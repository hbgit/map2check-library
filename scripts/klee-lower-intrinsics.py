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

After the rewrite, every intrinsic still declared must be one KLEE 3.1
executes (KLEE_31_INTRINSICS below); any other one is an error, because
under KLEE it would kill a path silently ("unimplemented intrinsic") and a
killed path can hide a violation. A new rustc or std that brings one must
add a scalar version here, or prove KLEE runs it.

Why a rewrite and not `opt-16 -enable-new-pm=0 -expand-reductions`: that
pass only covers the reduce family (pmulhu.w and pause would still need
this script) and lives in the legacy pass manager LLVM is removing, so one
mechanism, checked by `lli-16` on tests/klee/lower-intrinsics.ll, is kept.

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
DECLARED = re.compile(r"^declare[^\n]*?@(llvm\.[\w.]+)\(", re.M)

# Intrinsics KLEE 3.1 executes: the `case Intrinsic::` labels of
# lib/Core/Executor.cpp (executeCall) and lib/Module/IntrinsicCleaner.cpp
# (lowered before execution) at tag v3.1, `_` written as `.`. A declared
# intrinsic matches when its name is one of these or one of these followed
# by `.<type suffix>`.
KLEE_31_INTRINSICS = """
abs addressofreturnaddress annotation assume bswap ceil copysign cos ctlz
ctpop cttz dbg.declare dbg.label dbg.value eh.typeid.for exp exp2 expect
experimental.noalias.scope.decl fabs floor flt.rounds fma fmuladd
frameaddress fshl fshr get.dynamic.area.offset get.rounding invariant.end
invariant.start is.constant lifetime.end lifetime.start log log10 log2
memcpy memmove memset objectsize pcmarker pow prefetch ptr.annotation
readcyclecounter returnaddress round roundeven sadd.sat sadd.with.overflow
sin smax smin smul.with.overflow sqrt ssub.sat ssub.with.overflow
stackrestore stacksave trap trunc uadd.sat uadd.with.overflow umax umin
umul.with.overflow usub.sat usub.with.overflow vacopy vaend var.annotation
vastart
""".split()

# Declared but accepted although KLEE 3.1 cannot run them, each with why it
# is never executed by the runtime.
ACCEPTED = {
    # miniz_oxide, reached only by std's backtrace printing, which
    # panic = "abort" never runs. KLEE warns "unsupported intrinsic" at
    # load; KLEE's --optimize folds any scalar version back into it.
    "bitreverse": "backtrace symbolisation only",
}


def unsupported(names):
    allowed = KLEE_31_INTRINSICS + list(ACCEPTED)
    bad = []
    for name in names:
        base = name[len("llvm."):]
        if not any(base == a or base.startswith(a + ".") for a in allowed):
            bad.append(name)
    return sorted(set(bad))


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

    bad = unsupported(DECLARED.findall(ir))
    if bad:
        sys.exit(
            "klee-lower-intrinsics: KLEE 3.1 cannot execute, and there is no "
            "scalar version of: " + ", ".join(bad)
        )

    with open(sys.argv[2], "w") as f:
        f.write(ir)
        f.write("\n; Scalar versions of vector/x86 intrinsics (scripts/klee-lower-intrinsics.py)\n")
        f.write("\n\n".join(bodies))
        f.write("\n")
    for name in renamed:
        print(f"klee-lower-intrinsics: {name} -> {new_name(name)}")


if __name__ == "__main__":
    main()
