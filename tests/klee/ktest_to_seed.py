#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Turns a KLEE .ktest into an AFL++/libFuzzer seed, as Map2Check's frontend
does (develop: modules/frontend/test_suite/ktest_reader.cpp, readKtestFile
and ktestToFuzzerBytes, called by Caller::exportKleeVectorsAsSeeds): the
bytes of every object, in file order, concatenated. Nothing is reordered,
padded or byte-swapped, so the seed is exactly what the generators stored.

Usage: ktest_to_seed.py <in.ktest> <out.seed>
Prints one line per object: name, size and the bytes in hex."""
import struct
import sys


def read_ktest(path):
    with open(path, "rb") as f:
        data = f.read()
    pos = 0

    def take(n):
        nonlocal pos
        if pos + n > len(data):
            raise ValueError(f"{path}: truncated at byte {pos}")
        chunk = data[pos : pos + n]
        pos += n
        return chunk

    def u32():
        return struct.unpack(">I", take(4))[0]

    magic = take(5)
    if magic not in (b"KTEST", b"BOUT\n"):
        raise ValueError(f"{path}: not a ktest file")
    version = u32()
    for _ in range(u32()):  # arguments
        take(u32())
    if version >= 2:
        u32()  # symArgvs
        u32()  # symArgvLen
    objects = []
    for _ in range(u32()):
        name = take(u32()).decode()
        objects.append((name, take(u32())))
    return objects


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    objects = read_ktest(sys.argv[1])
    if not objects:
        sys.exit(f"{sys.argv[1]}: no objects")
    for name, raw in objects:
        print(f"{name} {len(raw)} {raw.hex()}")
    with open(sys.argv[2], "wb") as f:
        f.write(b"".join(raw for _, raw in objects))


if __name__ == "__main__":
    main()
