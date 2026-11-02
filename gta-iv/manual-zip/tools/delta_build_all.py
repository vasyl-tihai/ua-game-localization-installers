#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""delta_build_all.py - builds delta\\*.ua + delta\\manifest.txt for the script-only GTA IV package (see delta_make.py).

For every line of installer\\files.txt (component|relative path|build folder) makes a UAD1 delta orig -> build file.
Originals are taken from <ORIG_ROOT>\\<rel>.orig (if exists) or <ORIG_ROOT>\\<rel>; ORIG_ROOT = the game's GTAIV folder.
SHA-1 of the original is recorded in the delta unless --no-orig-sha1 (then only the size of the original is checked).

Usage: delta_build_all.py ORIG_ROOT OUT_DIR [--no-orig-sha1] [--only 0,5,7]
"""
import sys, os, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import delta_make

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    orig_root, out_dir = args[0], args[1]
    sha = '--no-orig-sha1' not in sys.argv
    only = None
    if '--only' in sys.argv:
        only = [int(x) for x in sys.argv[sys.argv.index('--only') + 1].split(',')]
        args = [a for a in args if a != sys.argv[sys.argv.index('--only') + 1]]
    os.makedirs(out_dir, exist_ok=True)
    files = []
    for l in open(os.path.join(ROOT, 'installer', 'files.txt'), encoding='utf-8-sig'):
        l = l.strip()
        if l and not l.startswith(';'):
            files.append(l.split('|'))
    text = open(os.path.join(ROOT, 'installer', 'gen.iss'), encoding='utf-8-sig').read()
    gen = {m.group(2): (int(m.group(4)), int(m.group(5)), m.group(6)) for m in re.finditer(
        r"Add\('(\w+)', '([^']+)', '(p\d+\.hdiff)', (\d+), (\d+), '([0-9a-f]{40})'\)", text)}
    rows = []
    for i, (comp, rel, src) in enumerate(files):
        osz, nsz, nsha = gen[rel]
        d = 'p%02d.ua' % i
        rows.append('%s|%s|%s|%d|%d|%s' % (comp, rel, d, osz, nsz, nsha))
        if only is not None and i not in only:
            continue
        o = os.path.join(orig_root, rel + '.orig')
        if not os.path.exists(o):
            o = os.path.join(orig_root, rel)
        n = os.path.join(ROOT, src, rel)
        assert os.path.getsize(o) == osz, (rel, os.path.getsize(o), osz)
        assert os.path.getsize(n) == nsz, (rel, os.path.getsize(n), nsz)
        print('[%d] %s %s' % (i, comp, rel), flush=True)
        delta_make.make(o, n, os.path.join(out_dir, d), orig_sha=sha)
    with open(os.path.join(out_dir, 'manifest.txt'), 'w', encoding='utf-8', newline='\r\n') as f:
        f.write('; component|path inside GTAIV|delta file|original size|result size|SHA-1 of the result\n')
        f.write('\n'.join(rows) + '\n')


if __name__ == '__main__':
    main()
