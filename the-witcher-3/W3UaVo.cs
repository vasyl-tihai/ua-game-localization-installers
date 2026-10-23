// Збирач української озвучки Відьмака 3 на ПК гравця: enpc.w3speech гри + ua_vo.bin (наш звук) → brpc.w3speech.
// Файлів гри ми не поширюємо: ліпсинк і решта реплік беруться з enpc.w3speech самого гравця.
//   W3UaVo.exe <enpc.w3speech> <ua_vo.bin> <brpc.w3speech>
// Формат w3speech — tools\w3speech.py. ua_vo.bin: "UAVO", u32 версія 1, u32 n, далі n × (u32 id, f32 тривалість, u32 len, wem).
// Збірка: C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /optimize /out:W3UaVo.exe W3UaVo.cs
using System;
using System.Collections.Generic;
using System.IO;

class W3UaVo
{
    static long Vlq(BinaryReader r)
    {
        int c = r.ReadByte(); long v = c & 0x3f; int sh = 6;
        if ((c & 0x40) != 0)
            while (true) { c = r.ReadByte(); v |= (long)(c & 0x7f) << sh; sh += 7; if ((c & 0x80) == 0) break; }
        return v;
    }

    static void Copy(Stream src, long off, long len, Stream dst, byte[] buf)
    {
        src.Position = off;
        while (len > 0)
        {
            int k = src.Read(buf, 0, (int)Math.Min(buf.Length, len));
            if (k <= 0) throw new EndOfStreamException();
            dst.Write(buf, 0, k); len -= k;
        }
    }

    static int Main(string[] a)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        if (a.Length != 3) { Console.Error.WriteLine("W3UaVo.exe <enpc.w3speech> <ua_vo.bin> <brpc.w3speech>"); return 2; }
        try
        {
            using (var src = new FileStream(a[0], FileMode.Open, FileAccess.Read, FileShare.Read, 1 << 20))
            using (var ua = new FileStream(a[1], FileMode.Open, FileAccess.Read, FileShare.Read, 1 << 20))
            {
                var r = new BinaryReader(src);
                if (new string(r.ReadChars(4)) != "CPSW") throw new Exception("enpc.w3speech: не CPSW");
                src.Position = 10;
                long n = Vlq(r);
                long tableStart = src.Position, tableEnd = tableStart + n * 40;
                var id = new uint[n]; var pad = new uint[n]; var wo = new long[n]; var ws = new long[n]; var lo = new long[n]; var ls = new long[n];
                for (long i = 0; i < n; i++)
                {
                    id[i] = r.ReadUInt32(); pad[i] = r.ReadUInt32();
                    wo[i] = r.ReadInt64(); ws[i] = r.ReadInt64(); lo[i] = r.ReadInt64(); ls[i] = r.ReadInt64();
                }

                var ur = new BinaryReader(ua);
                if (new string(ur.ReadChars(4)) != "UAVO" || ur.ReadUInt32() != 1) throw new Exception("ua_vo.bin: невідомий формат");
                uint un = ur.ReadUInt32();
                var map = new Dictionary<uint, long[]>();      // id → {зсув wem, довжина, біти f32 тривалості}
                for (uint k = 0; k < un; k++)
                {
                    uint uid = ur.ReadUInt32(); uint dur = ur.ReadUInt32(); uint len = ur.ReadUInt32();
                    map[uid] = new long[] { ua.Position, len, dur };
                    ua.Position += len;
                }

                string tmp = a[2] + ".tmp";
                int hit = 0;
                var buf = new byte[1 << 20];
                using (var o = new FileStream(tmp, FileMode.Create, FileAccess.Write, FileShare.None, 1 << 20))
                {
                    var w = new BinaryWriter(o);
                    Copy(src, 0, tableEnd + 2, o, buf);          // заголовок + таблиця (перепишемо) + 2 байти
                    var row = new long[n * 3];
                    long p = tableEnd + 2;
                    for (long i = 0; i < n; i++)
                    {
                        long wlen;
                        long[] e;
                        if (map.TryGetValue(id[i], out e))
                        {
                            w.Write((uint)e[1]); w.Flush();
                            Copy(ua, e[0], e[1], o, buf);
                            w.Write((uint)e[2]); w.Write((uint)1); w.Flush();
                            wlen = 4 + e[1] + 8; hit++;
                        }
                        else { Copy(src, wo[i], ws[i], o, buf); wlen = ws[i]; }
                        if (ls[i] > 0) Copy(src, lo[i], ls[i], o, buf);
                        row[i * 3] = p; row[i * 3 + 1] = wlen; row[i * 3 + 2] = ls[i] > 0 ? p + wlen : 0;
                        p += wlen + ls[i];
                        if (i % 5000 == 0) Console.WriteLine("{0}/{1}", i, n);
                    }
                    o.Position = tableStart;
                    for (long i = 0; i < n; i++)
                    {
                        w.Write(id[i]); w.Write(pad[i]); w.Write(row[i * 3]); w.Write(row[i * 3 + 1]); w.Write(row[i * 3 + 2]); w.Write(ls[i]);
                    }
                    w.Flush();
                }
                if (hit < un * 9 / 10) { File.Delete(tmp); throw new Exception(string.Format("збіглося лише {0} з {1} реплік — інша версія гри?", hit, un)); }
                if (File.Exists(a[2])) File.Delete(a[2]);
                File.Move(tmp, a[2]);
                Console.WriteLine("OK {0} українських реплік з {1}", hit, n);
            }
            return 0;
        }
        catch (Exception ex) { Console.Error.WriteLine(ex.Message); return 1; }
    }
}
