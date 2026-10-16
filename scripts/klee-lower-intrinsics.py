#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Replaces the vector and x86 intrinsics of the KLEE runtime's IR by plain
scalar functions, which KLEE 3.1 can execute.

The precompiled std of rustc 1.72.1 is vectorised (char counting in
`core::fmt::Formatter::pad`/`pad_integral`, `StrSearcher::new`, integer
formatting), and fat LTO carries that code into the runtime module. KLEE 3.1
does not implement `llvm.vector.reduce.*` nor the x86 SIMD intrinsics: a path
that formats a padded number (the witness logs of the memory modes do) dies
with "unimplemented intrinsic". Each declaration found is renamed to an
internal function with the same signature and semantics, written with
extractelement/insertelement and scalar arithmetic, which KLEE supports.

Any other `llvm.vector.*` or `llvm.x86.*` declaration is an error: a new
rustc brought one this script does not know, and it must be added here.

`llvm.bitreverse.*` (miniz_oxide, which only std's backtrace printing
reaches) is left alone: KLEE warns "unsupported intrinsic" at load, and its
own --optimize would fold a scalar version back into the intrinsic anyway.

Usage: klee-lower-intrinsics.py <in.ll> <out.ll>"""
import re
import sys

REDUCE = re.compile(
    r"^declare\s+(?P<ret>i\d+)\s+@(?P<name>llvm\.vector\.reduce\."
    r"(?P<op>add|mul|and|or|xor|umax|umin|smax|smin)\.v(?P<n>\d+)i(?P<w>\d+))"
    r"\(<(?P=n) x i(?P=w)>\)[^\n]*$",
    re.M,
)
PMULHU = re.compile(r"^declare\s+<8 x i16>\s+@(?P<name>llvm\.x86\.sse2\.pmulhu\.w)\([^\n]*$", re.M)
PAUSE = re.compile(r"^declare\s+void\s+@(?P<name>llvm\.x86\.sse2\.pause)\(\)[^\n]*$", re.M)
LEFTOVER = re.compile(r"^declare[^\n]*@(llvm\.(?:vector|x86)\.[\w.]+)", re.M)


def new_name(name):
    return "__map2check_klee_" + name.replace(".", "_")


def reduce_body(name, op, n, w):
    t = f"i{w}"
    lines = [f"define internal {t} @{new_name(name)}(<{n} x {t}> %v) {{"]
    for i in range(n):
        lines.append(f"  %e{i} = extractelement <{n} x {t}> %v, i32 {i}")
    acc = "%e0"
    for i in range(1, n):
        r = f"%r{i}"
        if op in ("add", "mul", "and", "or", "xor"):
            lines.append(f"  {r} = {op} {t} {acc}, %e{i}")
        else:
            pred = {"umax": "ugt", "umin": "ult", "smax": "sgt", "smin": "slt"}[op]
            lines.append(f"  %c{i} = icmp {pred} {t} {acc}, %e{i}")
            lines.append(f"  {r} = select i1 %c{i}, {t} {acc}, {t} %e{i}")
        acc = r
    lines.append(f"  ret {t} {acc}")
    lines.append("}")
    return "\n".join(lines)


def pmulhu_body(name):
    lines = [f"define internal <8 x i16> @{new_name(name)}(<8 x i16> %a, <8 x i16> %b) {{"]
    prev = "undef"
    for i in range(8):
        lines += [
            f"  %a{i} = extractelement <8 x i16> %a, i32 {i}",
            f"  %b{i} = extractelement <8 x i16> %b, i32 {i}",
            f"  %xa{i} = zext i16 %a{i} to i32",
            f"  %xb{i} = zext i16 %b{i} to i32",
            f"  %m{i} = mul i32 %xa{i}, %xb{i}",
            f"  %h{i} = lshr i32 %m{i}, 16",
            f"  %t{i} = trunc i32 %h{i} to i16",
            f"  %v{i} = insertelement <8 x i16> {prev}, i16 %t{i}, i32 {i}",
        ]
        prev = f"%v{i}"
    lines += [f"  ret <8 x i16> {prev}", "}"]
    return "\n".join(lines)


def pause_body(name):
    return f"define internal void @{new_name(name)}() {{\n  ret void\n}}"


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    with open(sys.argv[1]) as f:
        ir = f.read()

    bodies = []
    renamed = []
    for m in REDUCE.finditer(ir):
        bodies.append(reduce_body(m["name"], m["op"], int(m["n"]), int(m["w"])))
        renamed.append(m["name"])
    for m in PMULHU.finditer(ir):
        bodies.append(pmulhu_body(m["name"]))
        renamed.append(m["name"])
    for m in PAUSE.finditer(ir):
        bodies.append(pause_body(m["name"]))
        renamed.append(m["name"])

    for pattern in (REDUCE, PMULHU, PAUSE):
        ir = pattern.sub("", ir)
    for name in renamed:
        ir = re.sub(r"@" + re.escape(name) + r"(?![\w.])", "@" + new_name(name), ir)

    leftover = sorted(set(LEFTOVER.findall(ir)))
    if leftover:
        sys.exit("klee-lower-intrinsics: no scalar version of: " + ", ".join(leftover))

    with open(sys.argv[2], "w") as f:
        f.write(ir)
        f.write("\n; Scalar versions of vector/x86 intrinsics (scripts/klee-lower-intrinsics.py)\n")
        f.write("\n\n".join(bodies))
        f.write("\n")
    for name in renamed:
        print(f"klee-lower-intrinsics: {name} -> {new_name(name)}")


if __name__ == "__main__":
    main()
