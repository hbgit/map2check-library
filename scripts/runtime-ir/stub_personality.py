#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""D7 post-processing of the Rust core, step 3 (docs/cutover/d7-layout.md),
promoted from spikes/d7-layout/scripts/stub_personality.py (Task 2.7).

The core is built with panic = abort, but the precompiled std is not, so
std's rust_eh_personality stays and pulls the unwinder (_Unwind_*, libgcc_s)
into every combination. Nothing unwinds under panic = abort, so its body
becomes abort(); `opt -passes=globaldce` then drops what only it used.

Usage: stub_personality.py <in.ll> <out.ll>
Fails when the module has no rust_eh_personality definition.
"""
import re
import sys

PAT = re.compile(r"^(define [^\n]*@rust_eh_personality\([^\n]*?)( personality ptr @rust_eh_personality)? \{\n.*?^\}\n",
                 re.S | re.M)


def stub(src):
    m = PAT.search(src)
    if not m:
        raise ValueError("rust_eh_personality not found")
    body = m.group(1) + " {\n  call void @abort()\n  unreachable\n}\n"
    src = src[:m.start()] + body + src[m.end():]
    if not re.search(r"^(declare|define) [^\n]*@abort\(", src, re.M):
        src += "\ndeclare void @abort()\n"
    return src


def main(argv):
    if len(argv) != 2:
        sys.exit("usage: stub_personality.py <in.ll> <out.ll>")
    with open(argv[0]) as f:
        src = f.read()
    try:
        src = stub(src)
    except ValueError as e:
        sys.exit(f"stub_personality: {e}")
    with open(argv[1], "w") as f:
        f.write(src)
    print("stub_personality: rust_eh_personality now aborts")


if __name__ == "__main__":
    main(sys.argv[1:])
