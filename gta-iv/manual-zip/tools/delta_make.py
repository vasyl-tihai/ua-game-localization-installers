#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""delta_make.py - simple binary delta (orig -> new) for the script-only (no .exe/.dll) GTA IV installer.

The delta is applied on the player's PC by installer\\UaDelta.cs (compiled by PowerShell Add-Type, C# 5),
so the ZIP for Nexus Mods needs no hpatchz.exe.

FORMAT "UAD1"  (all integers little-endian)
  offset  size
  0       4    magic  'UAD1'
  4       8    origSize   (u64)
  12      8    newSize    (u64)
  20      20   origSha1   (all zero = not recorded, then only the size of the original is checked)
  40      20   newSha1
  60      ...  RAW Deflate stream (RFC 1951, no zlib header; .NET System.IO.Compression.DeflateStream reads it)
               that contains a sequence of ops:
                 0x00 varint(offset) varint(length)       COPY  length bytes from orig[offset..]
                 0x01 varint(length) <length bytes>       INSERT literal bytes
                 0x02                                     END (bytes produced must be == newSize)
  varint = LEB128 unsigned: 7 bits per byte, low group first, high bit = "more bytes follow".

Matching: orig is indexed by hashes of 32-byte windows at every 32nd offset (polynomial rolling hash, numpy);
new is scanned at every offset (only outside the already matched regions); a hit is verified byte by byte
and extended forward and backward, matches shorter than MINLEN are ignored. Files of the build keep the
structure of the originals (rpf/wtd/gxt), so long COPY runs dominate.

Usage:  delta_make.py ORIG NEW OUT.ua [--no-orig-sha1]
"""
import sys, os, struct, zlib, hashlib, time
import numpy as np

W = 32            # hashed window
STEP = 32         # orig sampled at every STEP-th offset
MINLEN = 64       # minimal accepted match
BLK = 1 << 20     # positions of new hashed per round
EXT = 1 << 20     # chunk of byte comparison
P = 0x9E3779B97F4A7C15
PINV = pow(P, -1, 1 << 64)
M64 = (1 << 64) - 1


def _powers(base, n):
    a = np.empty(n, dtype=np.uint64)
    a[0] = 1
    a[1:] = np.uint64(base)
    np.cumprod(a, out=a)
    return a


_MAXC = (1 << 22) + W
PW = _powers(P, _MAXC)
PIW = _powers(PINV, _MAXC)


def _fin(h):
    h ^= h >> np.uint64(32)
    h *= np.uint64(0xD6E8FEB86659FD93)
    h ^= h >> np.uint64(32)
    return h


def window_hashes(buf, count):
    """hashes of windows buf[i:i+W] for i in 0..count-1 (buf has >= count+W-1 bytes)."""
    c = buf[:count + W - 1].astype(np.uint64)
    c *= PW[:count + W - 1]
    s = np.zeros(count + W, dtype=np.uint64)
    np.cumsum(c, out=s[1:])
    h = s[W:W + count] - s[:count]
    h *= PIW[:count]
    return _fin(h)


def sampled_hashes(buf, nwin):
    """hashes of windows starting at 0, STEP, 2*STEP ... (< nwin) ; buf >= nwin+W-1 bytes"""
    c = buf[:nwin + W - 1].astype(np.uint64)
    c *= PW[:nwin + W - 1]
    s = np.zeros(nwin + W, dtype=np.uint64)
    np.cumsum(c, out=s[1:])
    idx = np.arange(0, nwin, STEP)
    h = s[idx + W] - s[idx]
    h *= PIW[idx]
    return _fin(h)


def varint(n):
    out = bytearray()
    while n >= 0x80:
        out.append((n & 0x7F) | 0x80)
        n >>= 7
    out.append(n)
    return bytes(out)


def sha1_of(path):
    h = hashlib.sha1()
    with open(path, 'rb') as f:
        while True:
            b = f.read(1 << 24)
            if not b:
                break
            h.update(b)
    return h.digest()


def fwd_len(a, ao, b, bo, maxlen):
    """number of equal bytes a[ao+i]==b[bo+i], i < maxlen"""
    n = 0
    step = 256
    while n < maxlen:
        k = min(step, maxlen - n)
        step = min(step * 4, EXT)
        x = a[ao + n:ao + n + k]
        y = b[bo + n:bo + n + k]
        if np.array_equal(x, y):
            n += k
            continue
        n += int(np.flatnonzero(x != y)[0])
        break
    return n


def back_len(a, ao, b, bo, maxlen):
    """number of equal bytes a[ao-1-i]==b[bo-1-i], i < maxlen"""
    n = 0
    step = 256
    while n < maxlen:
        k = min(step, maxlen - n)
        step = min(step * 4, EXT)
        x = a[ao - n - k:ao - n][::-1]
        y = b[bo - n - k:bo - n][::-1]
        if np.array_equal(x, y):
            n += k
            continue
        n += int(np.flatnonzero(x != y)[0])
        break
    return n


class Writer:
    def __init__(self, f, level):
        self.f = f
        self.c = zlib.compressobj(level, zlib.DEFLATED, -15, 9)
        self.stat_copy = 0
        self.stat_ins = 0
        self.nops = 0

    def put(self, b):
        d = self.c.compress(b)
        if d:
            self.f.write(d)

    def copy(self, off, ln):
        self.put(b'\x00' + varint(off) + varint(ln))
        self.stat_copy += ln
        self.nops += 1

    def insert(self, arr, s, e):
        while s < e:
            k = min(1 << 22, e - s)
            self.put(b'\x01' + varint(k) + arr[s:s + k].tobytes())
            self.stat_ins += k
            s += k
        self.nops += 1

    def end(self):
        self.put(b'\x02')
        self.f.write(self.c.flush())


def make(orig_path, new_path, out_path, orig_sha=True, level=6, log=print):
    t0 = time.time()
    osz = os.path.getsize(orig_path)
    nsz = os.path.getsize(new_path)
    header = b'UAD1' + struct.pack('<QQ', osz, nsz)
    header += (sha1_of(orig_path) if orig_sha else bytes(20))
    header += sha1_of(new_path)
    with open(out_path, 'wb') as f:
        f.write(header)
        wr = Writer(f, level)
        if osz < MINLEN * 2 or nsz < MINLEN * 2:
            if nsz:
                new = np.fromfile(new_path, dtype=np.uint8)
                wr.insert(new, 0, nsz)
            wr.end()
        else:
            _scan(orig_path, new_path, osz, nsz, wr, log)
            wr.end()
    log('  orig %d new %d -> delta %d  (copy %d, insert %d, ops %d, %.0fs)' % (
        osz, nsz, os.path.getsize(out_path), wr.stat_copy, wr.stat_ins, wr.nops, time.time() - t0))
    return os.path.getsize(out_path)


def _scan(orig_path, new_path, osz, nsz, wr, log):
    orig = np.memmap(orig_path, dtype=np.uint8, mode='r')
    new = np.memmap(new_path, dtype=np.uint8, mode='r')
    # --- index of orig
    CH = 1 << 22
    hs, ps = [], []
    for s in range(0, osz - W + 1, CH):
        nwin = min(CH, osz - W + 1 - s)
        h = sampled_hashes(orig[s:s + nwin + W - 1], nwin)
        hs.append(h)
        ps.append(np.arange(s, s + nwin, STEP, dtype=np.int64))
    hs = np.concatenate(hs)
    ps = np.concatenate(ps)
    order = np.argsort(hs, kind='stable')
    hs = hs[order]
    ps = ps[order]
    del order
    first = np.ones(len(hs), dtype=bool)
    first[1:] = hs[1:] != hs[:-1]
    hs = hs[first]
    ps = ps[first]
    del first
    bm = np.zeros(1 << 28, dtype=bool)
    bm[(hs >> np.uint64(36)).astype(np.int64)] = True
    # --- scan new
    cur = 0   # start of not yet emitted literal
    pos = 0
    blk = 4096
    last_log = time.time()
    while pos + W <= nsz:
        cnt = min(blk, nsz - W + 1 - pos)
        h = window_hashes(new[pos:pos + cnt + W - 1], cnt)
        cand = np.flatnonzero(bm[(h >> np.uint64(36)).astype(np.int64)])
        found = False
        if len(cand):
            hc = h[cand]
            ix = np.searchsorted(hs, hc)
            ix[ix >= len(hs)] = len(hs) - 1
            okm = hs[ix] == hc
            for n_rel, k in zip(cand[okm].tolist(), ix[okm].tolist()):
                n = pos + n_rel
                p = int(ps[k])
                f = fwd_len(new, n, orig, p, min(nsz - n, osz - p))
                if f < W:
                    continue
                b = back_len(new, n, orig, p, min(n - cur, p))
                if b + f < MINLEN:
                    continue
                if n - b > cur:
                    wr.insert(new, cur, n - b)
                wr.copy(p - b, b + f)
                cur = n + f
                pos = cur
                found = True
                blk = 4096
                break
        if not found:
            pos += cnt
            blk = min(blk * 2, BLK)
        if time.time() - last_log > 60:
            log('    %.1f%%  copy %d insert %d' % (100.0 * pos / nsz, wr.stat_copy, wr.stat_ins))
            last_log = time.time()
    if cur < nsz:
        wr.insert(new, cur, nsz)
    del orig, new


if __name__ == '__main__':
    a = [x for x in sys.argv[1:] if not x.startswith('--')]
    if len(a) != 3:
        print(__doc__)
        sys.exit(2)
    make(a[0], a[1], a[2], orig_sha='--no-orig-sha1' not in sys.argv)
