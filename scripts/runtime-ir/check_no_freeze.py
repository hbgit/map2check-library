#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Guard of the drop-in core (Task 2.7): KLEE 3.1 has no `freeze`
instruction. A path that reaches one ends with "illegal instruction", a KLEE
error the frontend reads as a dropped path, so no TRUE verdict is possible.
rustc's optimiser writes them (a speculated `add nuw`, a shift by a
variable amount, loop unswitching); the C runtime has none.

The core is not rewritten: the build fails, naming each function that keeps
one, and the Rust source is changed so that rustc writes none (the
`freeze`-free forms are tested in rust/src). Run on the core after
internalize + globaldce, where every function left is reachable from the
exported API.

Usage: check_no_freeze.py <core.ll>
Exit 0 when the module has no freeze; 1 with the functions otherwise.
"""
import re
import sys

DEFINE = re.compile(r"^define [^@]*@(\"[^\"]+\"|[-\w.$]+)\(")
FREEZE = re.compile(r"^\s*%\S+ = freeze ")


def functions_with_freeze(src):
    """{function name: number of freeze instructions}, in module order."""
    found, current = {}, None
    for line in src.split("\n"):
        m = DEFINE.match(line)
        if m:
            current = m.group(1).strip('"')
        elif line.startswith("}"):
            current = None
        elif current is not None and FREEZE.match(line):
            found[current] = found.get(current, 0) + 1
    return found


def main(argv):
    if len(argv) != 1:
        sys.exit("usage: check_no_freeze.py <core.ll>")
    with open(argv[0]) as f:
        found = functions_with_freeze(f.read())
    if found:
        print(f"check_no_freeze: {sum(found.values())} freeze left (KLEE 3.1 cannot execute it):",
              file=sys.stderr)
        for name, n in found.items():
            print(f"  {n}  {name}", file=sys.stderr)
        sys.exit(1)
    print("check_no_freeze: no freeze")


if __name__ == "__main__":
    main(sys.argv[1:])
