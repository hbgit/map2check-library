#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Post-processing of the drop-in core (Task 2.7): KLEE 3.1 has no `freeze`
instruction. A module that reaches one ends the path with "illegal
instruction", a KLEE error the frontend reads as a dropped path (measured:
map2check_binop_sdiv of the Rust core, the safe program of
scripts/runtime-ir/test-klee-generator.sh in the overflow mode). rustc's
optimiser writes them (`select` turned into logic, loop unswitching); the C
runtime, built by clang without them, has none.

Each `%x = freeze <ty> <v>` becomes `%x = bitcast <ty> <v> to <ty>`, the
identity. That is exactly freeze for any value that is not poison, and KLEE
has no poison: it executes the two the same way. Only first-class scalar
types (iN, ptr, half/float/double) and vectors of them are accepted; any
other freeze, or an operand this script does not parse, is an error.

Usage: lower_freeze.py <in.ll> <out.ll>     (prints how many were lowered)
       lower_freeze.py --check <in.ll>      (fails if a freeze remains)
"""
import re
import sys

FREEZE = re.compile(r"^(\s*%[-\w.$]+|\s*%\"[^\"]+\") = freeze (.*)$")
SCALAR = re.compile(r"^(i\d+|ptr|half|float|double)$")
VECTOR = re.compile(r"^<\d+ x (i\d+|ptr|half|float|double)>$")
VALUE = re.compile(r"^(%[-\w.$]+|%\"[^\"]+\"|-?\d+|true|false|null|undef|poison|zeroinitializer|@[-\w.$]+)$")


def lower_line(line):
    m = FREEZE.match(line)
    if not m:
        return line
    lhs, rest = m.groups()
    if rest.startswith("<"):
        close = rest.index(">") + 1
        ty, tail = rest[:close], rest[close:].lstrip()
    else:
        ty, _, tail = rest.partition(" ")
    if not (SCALAR.match(ty) or VECTOR.match(ty)):
        raise ValueError(f"freeze of an unsupported type: {line.strip()}")
    value, sep, meta = tail.partition(", ")
    if not VALUE.match(value):
        raise ValueError(f"freeze of an unsupported operand: {line.strip()}")
    return f"{lhs} = bitcast {ty} {value} to {ty}{sep}{meta}"


def lower(src):
    out, n = [], 0
    for line in src.split("\n"):
        new = lower_line(line)
        n += new is not line
        out.append(new)
    return "\n".join(out), n


def remaining(src):
    return [line.strip() for line in src.split("\n") if FREEZE.match(line)]


def main(argv):
    if len(argv) == 2 and argv[0] == "--check":
        with open(argv[1]) as f:
            left = remaining(f.read())
        if left:
            sys.exit(f"lower_freeze: {len(left)} freeze left, e.g. {left[0]}")
        return
    if len(argv) != 2:
        sys.exit("usage: lower_freeze.py <in.ll> <out.ll> | --check <in.ll>")
    with open(argv[0]) as f:
        src = f.read()
    try:
        src, n = lower(src)
    except ValueError as e:
        sys.exit(f"lower_freeze: {e}")
    with open(argv[1], "w") as f:
        f.write(src)
    print(f"lower_freeze: {n} freeze lowered")


if __name__ == "__main__":
    main(sys.argv[1:])
