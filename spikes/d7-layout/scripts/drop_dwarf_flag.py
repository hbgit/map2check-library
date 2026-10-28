#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""D7 spike (Task 1.1): drop the "Dwarf Version" module flag of a Rust
module whose debug info was stripped. rustc 1.72 writes 4, clang-16 writes 5,
and llvm-link warns on every frontend link (its stderr is not redirected).

Usage: drop_dwarf_flag.py <in.ll> <out.ll>
"""
import re
import sys

src = open(sys.argv[1]).read()
m = re.search(r'^(!\d+) = !\{i32 \d+, !"Dwarf Version", i32 \d+\}\n', src, re.M)
if m:
    node = m.group(1)
    src = src[:m.start()] + src[m.end():]
    flags = re.search(r"^!llvm\.module\.flags = !\{(.*)\}$", src, re.M)
    items = [i.strip() for i in flags.group(1).split(",") if i.strip() != node]
    src = src[:flags.start(1)] + ", ".join(items) + src[flags.end(1):]
open(sys.argv[2], "w").write(src)
