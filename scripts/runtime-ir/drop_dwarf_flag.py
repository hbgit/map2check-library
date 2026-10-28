#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""D7 post-processing of the Rust core, step 6 (docs/cutover/d7-layout.md),
promoted from spikes/d7-layout/scripts/drop_dwarf_flag.py (Task 2.7).

Drops the "Dwarf Version" module flag of a Rust module whose debug info was
stripped. rustc 1.72 writes 4, clang-16 writes 5, and llvm-link warns on
every frontend link (its stderr is not redirected). A module without the
flag is written unchanged.

Usage: drop_dwarf_flag.py <in.ll> <out.ll>
"""
import re
import sys


def drop(src):
    m = re.search(r'^(!\d+) = !\{i32 \d+, !"Dwarf Version", i32 \d+\}\n', src, re.M)
    if not m:
        return src
    node = m.group(1)
    src = src[:m.start()] + src[m.end():]
    flags = re.search(r"^!llvm\.module\.flags = !\{(.*)\}$", src, re.M)
    items = [i.strip() for i in flags.group(1).split(",") if i.strip() != node]
    return src[:flags.start(1)] + ", ".join(items) + src[flags.end(1):]


def main(argv):
    if len(argv) != 2:
        sys.exit("usage: drop_dwarf_flag.py <in.ll> <out.ll>")
    with open(argv[0]) as f:
        src = f.read()
    with open(argv[1], "w") as f:
        f.write(drop(src))


if __name__ == "__main__":
    main(sys.argv[1:])
