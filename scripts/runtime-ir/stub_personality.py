#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""D7 post-processing of the Rust core, step 3 (docs/cutover/d7-layout.md),
promoted from spikes/d7-layout/scripts/stub_personality.py (Task 2.7).

The core is built with panic = abort, but the precompiled std is not. Two of
its functions become abort():

- rust_eh_personality: it stays and pulls the unwinder (_Unwind_*,
  libgcc_s) into every combination; nothing unwinds under panic = abort;
- std::panicking::rust_panic_with_hook (any hash): std's panic path, which
  every core::panicking call reaches. Its inlined get_backtrace_style keeps
  a `freeze` that KLEE 3.1 cannot execute ("illegal instruction"), and the
  freeze guard of scripts/build-runtime-bc.sh allows none. Under panic = abort
  the hook ends in abort anyway; only the panic message is no longer
  printed. Approved by the user on 2026-10-27 (D7 item 3).

`opt -passes=globaldce` then drops what only their bodies used. The
signatures (and so every call site) are unchanged; a `personality` clause on
a stubbed definition is dropped, since the new body has no invoke.

Usage: stub_personality.py <in.ll> <out.ll>
Fails unless each of the two functions is defined exactly once.
"""
import re
import sys

# (label, IR name pattern); each must match exactly one definition.
TARGETS = [
    ("rust_eh_personality", r"rust_eh_personality"),
    ("std::panicking::rust_panic_with_hook", r"_ZN3std9panicking20rust_panic_with_hook17h[0-9a-f]{16}E"),
]


def _pattern(name):
    return re.compile(r"^(define [^\n]*@" + name + r"\([^\n]*?)( personality ptr @[-\w.$]+)? \{\n.*?^\}\n",
                      re.S | re.M)


def stub(src):
    for label, name in TARGETS:
        found = list(_pattern(name).finditer(src))
        if len(found) != 1:
            raise ValueError(f"{label}: expected one definition, found {len(found)}")
        m = found[0]
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
    print("stub_personality: rust_eh_personality and std::panicking::rust_panic_with_hook now abort")


if __name__ == "__main__":
    main(sys.argv[1:])
