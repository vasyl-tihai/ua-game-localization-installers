// Збирач української озвучки CONTROL Resonant на ПК гравця (порт tools\rmdpack.py + vo_install.py).
// Файлів гри ми не поширюємо: для кожного індексу (base-it, stream0-it, base-generic, stream0-generic) береться
// найменший архів самої гри → копія <назва>-uNN.rmdblob + наш звук у кінець, новий .rmdtoc. Оригінал → .rmdtoc.orig.
//   CrUaVo.exe <тека data_pack2\pc> <ua_vo.bin>        — встановити
//   CrUaVo.exe --restore <тека data_pack2\pc>           — повернути оригінал
// ua_vo.bin: "UAVO", u32 версія 1, u32 кількість індексів; на кожен: u8 довжина + назва (ascii), u32 n,
//   n × (u16 довжина + шлях utf8, f32 тривалість, u32 довжина, wem).
// Стан: <індекс>.rmdtoc.uavo = «довжина crc32» нашого .rmdtoc + шлях нашого архіву; не збігається → гру оновлено,
//   поточний .rmdtoc стає новим .orig.
// Збірка: C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /optimize /out:CrUaVo.exe CrUaVo.cs
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

class CrUaVo
{
    static uint U32(byte[] b, long p) { return BitConverter.ToUInt32(b, (int)p); }
    static long U40(byte[] b, long p) { long v = 0; for (int i = 4; i >= 0; i--) v = (v << 8) | b[p + i]; return v; }
    static void P32(byte[] b, long p, uint v) { BitConverter.GetBytes(v).CopyTo(b, p); }
    static void P40(byte[] b, long p, long v) { for (int i = 0; i < 5; i++) b[p + i] = (byte)(v >> (8 * i)); }

    static uint[] crcT;
    static uint Crc32(byte[] d, int off, int len)
    {
        if (crcT == null)
        {
            crcT = new uint[256];
            for (uint i = 0; i < 256; i++) { uint c = i; for (int k = 0; k < 8; k++) c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1; crcT[i] = c; }
        }
        uint r = 0xFFFFFFFF;
        for (int i = off; i < off + len; i++) r = crcT[(r ^ d[i]) & 0xFF] ^ (r >> 8);
        return r ^ 0xFFFFFFFF;
    }

    static byte[] Lz4Dec(byte[] s, long off, int clen, int dlen)
    {
        var o = new byte[dlen]; long ip = off, end = off + clen; int op = 0;
        while (ip < end)
        {
            int tok = s[ip++]; int lit = tok >> 4;
            if (lit == 15) { int b; do { b = s[ip++]; lit += b; } while (b == 255); }
            Array.Copy(s, ip, o, op, lit); ip += lit; op += lit;
            if (ip >= end) break;
            int dist = s[ip] | (s[ip + 1] << 8); ip += 2;
            int ml = tok & 15;
            if (ml == 15) { int b; do { b = s[ip++]; ml += b; } while (b == 255); }
            ml += 4;
            for (int i = 0; i < ml; i++) { o[op] = o[op - dist]; op++; }
        }
        if (op != dlen) throw new Exception("LZ4: розмір не збігся");
        return o;
    }

    static void Len(MemoryStream m, int r) { while (r >= 255) { m.WriteByte(255); r -= 255; } m.WriteByte((byte)r); }

    // LZ4-блок (жадібний, хеш 4 байт): правила формату — останні 5 байт літерали, збіг не ближче 12 байт до кінця
    static byte[] Lz4Enc(byte[] d, int off, int n)
    {
        var m = new MemoryStream(n / 2 + 64); var ht = new int[1 << 16];
        for (int i = 0; i < ht.Length; i++) ht[i] = -1;
        int end = off + n, mflimit = end - 12, anchor = off, ip = off;
        while (ip < mflimit)
        {
            uint v = BitConverter.ToUInt32(d, ip); int h = (int)((v * 2654435761u) >> 16);
            int r = ht[h]; ht[h] = ip;
            if (r < 0 || ip - r > 65535 || BitConverter.ToUInt32(d, r) != v) { ip++; continue; }
            int ml = 4; while (ip + ml < end - 5 && d[r + ml] == d[ip + ml]) ml++;
            int lit = ip - anchor;
            int tok = (Math.Min(lit, 15) << 4) | Math.Min(ml - 4, 15);
            m.WriteByte((byte)tok);
            if (lit >= 15) Len(m, lit - 15);
            m.Write(d, anchor, lit);
            int dist = ip - r; m.WriteByte((byte)dist); m.WriteByte((byte)(dist >> 8));
            if (ml - 4 >= 15) Len(m, ml - 4 - 15);
            ip += ml; anchor = ip;
        }
        int last = end - anchor;
        m.WriteByte((byte)(Math.Min(last, 15) << 4));
        if (last >= 15) Len(m, last - 15);
        m.Write(d, anchor, last);
        return m.ToArray();
    }

    class Entry { public string Path; public float Dur; public long Off; public int Len; }

    static string NewName(string old)
    {
        int k = old.LastIndexOf('-');
        return old.Substring(0, k + 1) + "u" + old.Substring(k + 2);       // stream0-it-001 → stream0-it-u01
    }

    static void PatchMeta(byte[] L, long a, int ms, uint oldSize, uint newSize, uint crc, float dur)
    {
        long found = -1;
        for (long p = a; p + 12 <= a + ms; p++)
            if (U32(L, p) == 1 && U32(L, p + 4) == oldSize && U32(L, p + 8) == 0)
            {
                if (found >= 0) throw new Exception("DMKP: корінь не однозначний");
                found = p;
            }
        if (found < 0) throw new Exception("DMKP: корінь не знайдено");
        P32(L, found + 4, newSize); P32(L, found + 8, 0); P32(L, found + 12, crc);
        float old = BitConverter.ToSingle(L, (int)(a + ms - 4));
        if (!(old > 0 && old < 600)) throw new Exception("DMKP: тривалість " + old);
        BitConverter.GetBytes(dur).CopyTo(L, a + ms - 4);
    }

    static void Install(string pc, string tname, FileStream ua, Dictionary<string, Entry> repl)
    {
        string toc = Path.Combine(pc, tname + ".rmdtoc"), orig = toc + ".orig", state = toc + ".uavo";
        // .orig: перший запуск, або гру оновлено (поточний .rmdtoc не наш)
        bool ours = false;
        if (File.Exists(state) && File.Exists(toc))
        {
            var st = File.ReadAllLines(state); var cur = File.ReadAllBytes(toc);
            ours = st.Length > 0 && st[0] == cur.Length + " " + Crc32(cur, 0, cur.Length);
        }
        if (!File.Exists(orig)) File.Copy(toc, orig);
        else if (File.Exists(state) && !ours) File.Copy(toc, orig, true);   // ставили ми, але .rmdtoc уже інший — оновлення гри
        // .orig без стану — від попереднього встановлення (vo_install.py) — йому віримо

        byte[] T = File.ReadAllBytes(orig);
        if (Encoding.ASCII.GetString(T, 0, 4) != "COTR" || U32(T, 4) != 3) throw new Exception(tname + ": не COTR v3");
        uint dOff = U32(T, 8), dSize = U32(T, 12);
        var Lm = new MemoryStream();
        for (uint i = 0; i < dSize / 16; i++)
        {
            long p = dOff + i * 16; long off = U40(T, p + 3); int dec = (int)U32(T, p + 8), comp = (int)U32(T, p + 12);
            if (comp != 0) { var b = Lz4Dec(T, off, comp, dec); Lm.Write(b, 0, b.Length); } else Lm.Write(T, (int)off, dec);
        }
        byte[] L = Lm.ToArray();
        uint nArc = U32(T, 0x14), pathOff = U32(T, 0x18), nPath = U32(T, 0x1C), fileOff = U32(T, 0x20), nFile = U32(T, 0x24);
        uint sOff = U32(T, 0x28), mOff = U32(T, 0x38), chunkOff = U32(T, 0x50), chunkSize = U32(T, 0x54);
        Func<uint, uint, string> S = (o, n) => Encoding.UTF8.GetString(L, (int)(sOff + o), (int)n);
        var dirs = new string[nPath];
        for (uint i = 0; i < nPath; i++) { long p = pathOff + i * 0x1C; dirs[i] = S(U32(L, p + 0x14), U32(L, p + 0x18)); }

        int arc = 0;                                      // найменший архів — менше копіювати
        for (int i = 1; i < nArc; i++) if (BitConverter.ToUInt64(L, i * 24 + 16) < BitConverter.ToUInt64(L, arc * 24 + 16)) arc = i;
        uint ano = U32(L, arc * 24), ans = U32(L, arc * 24 + 4);
        string oldRel = S(ano, ans), rel = NewName(oldRel);
        long pos = (long)BitConverter.ToUInt64(L, arc * 24 + 16);
        string src = Path.GetFullPath(Path.Combine(pc, oldRel)), dst = Path.GetFullPath(Path.Combine(pc, rel));
        Console.WriteLine("{0}: {1} реплік, архів {2}", tname, repl.Count, Path.GetFileName(dst));
        File.Copy(src, dst, true);

        var newChunks = new MemoryStream(); var buf = new byte[1 << 20]; int hit = 0;
        using (var bf = new FileStream(dst, FileMode.Open, FileAccess.ReadWrite, FileShare.None, 1 << 20))
        {
            bf.SetLength(pos); bf.Position = pos;
            for (uint i = 0; i < nFile; i++)
            {
                long p = fileOff + i * 0x20;
                uint cr = U32(L, p), cb = U32(L, p + 4), pi = U32(L, p + 8), no = U32(L, p + 12), ns = U32(L, p + 16);
                uint total = U32(L, p + 20), mr = U32(L, p + 24), ms = U32(L, p + 28);
                string full = dirs[pi] != "" ? dirs[pi] + "/" + S(no, ns) : S(no, ns);
                uint relNew = (uint)newChunks.Length;
                Entry e;
                if (repl.TryGetValue(full, out e))
                {
                    var data = new byte[e.Len]; ua.Position = e.Off;
                    int got = 0; while (got < e.Len) { int k = ua.Read(data, got, e.Len - got); if (k <= 0) throw new EndOfStreamException(); got += k; }
                    bf.Write(data, 0, data.Length);
                    var rec = new byte[16]; rec[1] = (byte)arc; P40(rec, 3, pos); P32(rec, 8, (uint)data.Length);
                    newChunks.Write(rec, 0, 16); pos += data.Length;
                    if (ms > 0) PatchMeta(L, mOff + mr, (int)ms, total, (uint)data.Length, Crc32(data, 0, data.Length), e.Dur);
                    P32(L, p + 20, (uint)data.Length); hit++;
                }
                else newChunks.Write(L, (int)(chunkOff + cr), (int)cb);
                P32(L, p, relNew); P32(L, p + 4, (uint)newChunks.Length - relNew);
            }
        }
        if (hit < repl.Count * 9 / 10) throw new Exception(string.Format("{0}: збіглося лише {1} з {2} — інша версія гри?", tname, hit, repl.Count));
        if (chunkOff + chunkSize != L.Length) throw new Exception(tname + ": чанки не в кінці індексу");
        var nc = newChunks.ToArray();
        var L2 = new byte[chunkOff + nc.Length]; Array.Copy(L, L2, chunkOff); Array.Copy(nc, 0, L2, chunkOff, nc.Length); L = L2;
        byte[] rb = Encoding.UTF8.GetBytes(rel);
        if (rb.Length != ans) throw new Exception("назва архіву іншої довжини");
        Array.Copy(rb, 0, L, sOff + ano, rb.Length);
        BitConverter.GetBytes((ulong)pos).CopyTo(L, arc * 24 + 16);

        // новий .rmdtoc: логічний індекс блоками по 1 МіБ (останній бере залишок), дескриптори з 0x58, дані з 0x1000
        const int DATA = 0x1000, BLK = 1 << 20;
        if (U40(T, 0x58 + 3) != DATA) throw new Exception(tname + ": очікувались дані з 0x1000");
        int nb = Math.Max(1, L.Length / BLK);
        var head = new byte[DATA]; Array.Copy(T, head, DATA);
        Array.Clear(head, 0x58, DATA - 4 - 0x58);
        P32(head, 0x0C, (uint)(nb * 16)); P32(head, 0x54, (uint)nc.Length);
        var body = new MemoryStream(); long pd = DATA;
        for (int i = 0; i < nb; i++)
        {
            int a = i * BLK, b = i == nb - 1 ? L.Length : (i + 1) * BLK;
            var c = Lz4Enc(L, a, b - a); int p = 0x58 + i * 16;
            head[p] = 0x10; head[p + 1] = 0; head[p + 2] = 0; P40(head, p + 3, pd); P32(head, p + 8, (uint)(b - a)); P32(head, p + 12, (uint)c.Length);
            int pad = i < nb - 1 ? (16 - c.Length % 16) % 16 : 0;
            body.Write(c, 0, c.Length); body.Write(new byte[pad], 0, pad); pd += c.Length + pad;
        }
        var outB = new byte[DATA + body.Length]; Array.Copy(head, outB, DATA); body.ToArray().CopyTo(outB, DATA);
        File.WriteAllBytes(toc + ".tmp", outB);
        if (File.Exists(toc)) File.Delete(toc);
        File.Move(toc + ".tmp", toc);
        File.WriteAllLines(state, new[] { outB.Length + " " + Crc32(outB, 0, outB.Length), dst });
        Console.WriteLine("  OK {0}", hit);
    }

    static void Restore(string pc)
    {
        foreach (var t in new[] { "base-it", "stream0-it", "base-generic", "stream0-generic" })
        {
            string toc = Path.Combine(pc, t + ".rmdtoc"), orig = toc + ".orig", state = toc + ".uavo";
            if (!File.Exists(state)) continue;
            var st = File.ReadAllLines(state);
            if (File.Exists(orig)) { File.Copy(orig, toc, true); File.Delete(orig); }
            if (st.Length > 1 && File.Exists(st[1]) && Path.GetFileName(st[1]).Contains("-u")) File.Delete(st[1]);
            File.Delete(state);
            Console.WriteLine("відновлено {0}", t);
        }
    }

    static int Main(string[] a)
    {
        Console.OutputEncoding = Encoding.UTF8;
        try
        {
            if (a.Length == 2 && a[0] == "--restore") { Restore(a[1]); return 0; }
            if (a.Length != 2) { Console.Error.WriteLine("CrUaVo.exe <data_pack2\\pc> <ua_vo.bin> | --restore <data_pack2\\pc>"); return 2; }
            using (var ua = new FileStream(a[1], FileMode.Open, FileAccess.Read, FileShare.Read, 1 << 20))
            {
                var r = new BinaryReader(ua, Encoding.UTF8);
                if (Encoding.ASCII.GetString(r.ReadBytes(4)) != "UAVO" || r.ReadUInt32() != 1) throw new Exception("ua_vo.bin: невідомий формат");
                uint nt = r.ReadUInt32();
                var all = new List<KeyValuePair<string, Dictionary<string, Entry>>>();
                for (uint t = 0; t < nt; t++)
                {
                    string name = Encoding.ASCII.GetString(r.ReadBytes(r.ReadByte()));
                    uint n = r.ReadUInt32(); var d = new Dictionary<string, Entry>();
                    for (uint k = 0; k < n; k++)
                    {
                        var e = new Entry(); e.Path = Encoding.UTF8.GetString(r.ReadBytes(r.ReadUInt16()));
                        e.Dur = r.ReadSingle(); e.Len = (int)r.ReadUInt32(); e.Off = ua.Position; ua.Position += e.Len;
                        d[e.Path] = e;
                    }
                    all.Add(new KeyValuePair<string, Dictionary<string, Entry>>(name, d));
                }
                foreach (var kv in all) Install(a[0], kv.Key, ua, kv.Value);
            }
            Console.WriteLine("DONE");
            return 0;
        }
        catch (Exception ex) { Console.Error.WriteLine(ex.Message); return 1; }
    }
}
