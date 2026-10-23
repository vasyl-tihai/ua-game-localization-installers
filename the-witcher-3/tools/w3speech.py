# Читання *.w3speech (Відьмак 3): заголовок CPSW, таблиця записів (id, wem, lipsync cr2w).
# python w3speech.py list <файл> [N]   — перші N записів
# python w3speech.py map <w3speech> <en.tsv> <ua.tsv> <out.tsv> — index, speech_id, string_id, en, ua
import struct, sys

def vlq(b, p):
    """Упакований int REDengine: 1-й байт — 6 біт + 0x40 продовження, далі по 7 біт + 0x80."""
    c = b[p]; v = c & 0x3f; sh = 6; p += 1
    if c & 0x40:
        while True:
            c = b[p]; p += 1
            v |= (c & 0x7f) << sh; sh += 7
            if not c & 0x80: break
    return (-v if c & 0x80 and False else v), p

def read_table(path):
    with open(path, 'rb') as f:
        head = f.read(1 << 22)
    assert head[:4] == b'CPSW', head[:4]
    ver, key = struct.unpack_from('<IH', head, 4)
    n, p = vlq(head, 10)
    need = p + n * 40
    if need > len(head):
        with open(path, 'rb') as f:
            head = f.read(need)
    items = []
    for i in range(n):
        sid, pad, wo, ws, lo, ls = struct.unpack_from('<IIQQQQ', head, p + i * 40)
        items.append(dict(id=sid, pad=pad, wo=wo, ws=ws, lo=lo, ls=ls))
    return dict(ver=ver, key=key, n=n, table_end=need, items=items)

def build(src, out, repl, lips=None):
    """Копія src з підміною звуку: repl {індекс запису: (байти .wem, тривалість с)}; lips {індекс: байти ліпсинку}.
    Блок звуку = u32 розмір RIFF + RIFF + f32 тривалість + u32 1; одразу за ним — блок ліпсинку. Таблиця на 40 байт/запис."""
    lips = lips or {}
    t = read_table(src); it = t['items']
    with open(src, 'rb') as f:
        head = f.read(t['table_end'] + 2)            # заголовок + таблиця + 2 байти після таблиці
    with open(src, 'rb') as f, open(out, 'wb') as o:
        o.write(head)
        p = len(head); rows = []
        for i, x in enumerate(it):
            if i in repl:
                wem, dur = repl[i]
                wb = struct.pack('<I', len(wem)) + wem + struct.pack('<fI', dur, 1)
            else:
                f.seek(x['wo']); wb = f.read(x['ws'])
            if i in lips:
                lb = lips[i]
            elif x['ls']:
                f.seek(x['lo']); lb = f.read(x['ls'])
            else:
                lb = b''                                # без ліпсинку (вигуки): lo = 0
            o.write(wb); o.write(lb)
            rows.append(struct.pack('<IIQQQQ', x['id'], x['pad'], p, len(wb), p + len(wb) if lb else 0, len(lb)))
            p += len(wb) + len(lb)
        o.seek(t['table_end'] - t['n'] * 40)
        o.write(b''.join(rows))

EN_MAGIC = 0x79321793   # magic en.w3strings (id у w3strings зберігається як id^magic)

def speech_string_id(entry_id):
    """id запису w3speech = id рядка ^ magic англ. w3strings (0x79321793)."""
    return entry_id ^ EN_MAGIC

if __name__ == '__main__' and sys.argv[1] == 'map':
    # map <w3speech> <en.tsv> <ua.tsv> <out.tsv>: index, speech_id, string_id, en, ua
    import w3strings
    t = read_table(sys.argv[2])
    en = w3strings.read_tsv(sys.argv[3]); ua = w3strings.read_tsv(sys.argv[4])
    hit = 0
    with open(sys.argv[5], 'w', encoding='utf-8', newline='\n') as f:
        for i, it in enumerate(t['items']):
            sid = speech_string_id(it['id'])
            hit += sid in en and sid in ua
            f.write('%d\t0x%08x\t%d\t%s\t%s\n' % (i, it['id'], sid, en.get(sid, ''), ua.get(sid, '')))
    print('записів', t['n'], 'є в en і ua', hit, '%.2f%%' % (100 * hit / t['n']))
elif __name__ == '__main__':
    t = read_table(sys.argv[2])
    print('ver', t['ver'], 'key', hex(t['key']), 'n', t['n'], 'table_end', t['table_end'])
    for it in t['items'][:int(sys.argv[3]) if len(sys.argv) > 3 else 5]:
        print({k: hex(v) for k, v in it.items()})
