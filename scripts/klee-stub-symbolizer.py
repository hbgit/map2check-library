#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Replaces the body of every function of std's backtrace symbolizer in the
KLEE runtime's IR by a call to `abort`.

std's default panic hook can print a backtrace, so fat LTO carries the whole
symbolizer (gimli, addr2line, miniz_oxide, rustc_demangle, backtrace_rs) into
the module, even with panic = "abort": about 48% of its IR, which KLEE loads,
links against uclibc and re-optimises (--optimize) on every run, about 1.6 s
and 60 MB per symex task (task 4.3, criterion 9). Only a panic with
RUST_BACKTRACE set reaches that code, and the runtime denies panics outside
tests (rust/src/lib.rs).

Each stubbed function keeps its name and signature, so nothing that calls it
changes and no undefined symbol is introduced; its body becomes
`call void @abort()` + `unreachable`, which KLEE reports as an abort, the
same end a panic = "abort" panic has. Its function attributes are replaced
by `cold noinline noreturn nounwind`: an attribute such as `willreturn` or
`memory(none)` on a body that never returns would let the optimiser turn the
call sites into `unreachable` instead of an abort. `opt -passes=globaldce`
then drops what only those bodies used (the `object` crate, the
decompression tables).

Shared bodies are kept. rustc merges identical functions, so one body named
after a symbolizer type (`drop_in_place<RawVec<(usize, backtrace_rs::..)>>`)
is also the one `alloc::fmt::format` calls to free a `String`. A candidate
is stubbed only if the code that stays cannot reach it: a walk from every
symbol with external linkage (`main`, the C API, `llvm.used`), through the
bodies and initialisers of everything it reaches, stopping only at the
printer's entry (ENTRY below, the call std's default hook makes when a
backtrace is asked for), marks the candidates it meets as shared, and those
keep their bodies.

Usage:
  klee-stub-symbolizer.py <in.ll> <out.ll>   rewrite
  klee-stub-symbolizer.py --check <in.ll>    fail if a candidate that only
                                             symbolizer code reaches still
                                             has a real body, or if one that
                                             live code reaches is a stub"""
import re
import sys

# A candidate is a function whose (mangled) name names one of these crates
# or std's copy of backtrace-rs ...
SYMBOLIZER = re.compile(r"gimli|addr2line|miniz_oxide|rustc_demangle|backtrace_rs")
# ... or std's backtrace printer, which calls the symbolizer. The
# short-backtrace markers (`__rust_{begin,end}_short_backtrace`), on every
# panic path, are not candidates.
PRINTER = re.compile(
    r"sys_common9backtrace5print|sys_common9backtrace10_print_fmt"
    r"|sys_common9backtrace15output_filename|sys_common\.\.backtrace\.\._print"
)
# The one edge the walk does not follow: `std::sys_common::backtrace::print`,
# the printer's entry, which std's default panic hook calls only when a
# backtrace is asked for. Every other printer function (its closures, the
# `drop_in_place` of its closure, which is a plain buffer drop rustc may
# merge with a `String` drop) is an ordinary candidate, kept when the walk
# reaches it.
ENTRY = re.compile(r"^_ZN3std10sys_common9backtrace5print17h[0-9a-f]{16}E$")

NAME = r'@(?:"(?P<q>(?:[^"\\]|\\.)*)"|(?P<n>[-\w.$]+))'
DEFINE = re.compile(r"^define [^\n]*?" + NAME + r"\(", re.M)
GLOBAL = re.compile(r"^" + NAME + r" = [^\n]*$", re.M)
REF = re.compile(NAME)
LOCAL_DEFINE = re.compile(r"define (?:internal|private) ")
LOCAL_GLOBAL = re.compile(r'"? = (?:internal|private) ')
STUB_ATTRS = "cold noinline noreturn nounwind"
STUB_BODY = ["  call void @abort()", "  unreachable"]


def name_of(m):
    return m["q"] if m["q"] is not None else m["n"]


def candidate(name):
    return bool(SYMBOLIZER.search(name) or PRINTER.search(name))


def parse(ir):
    """Returns the definitions as {name: (start, end)} (`end` just past the
    closing `}` line), the names each global symbol (function body, variable
    or alias initialiser) refers to, and the roots: the symbols with
    external linkage."""
    defs, refs, roots = {}, {}, set()
    for m in DEFINE.finditer(ir):
        name = name_of(m)
        end = ir.index("\n}\n", m.start()) + 3
        defs[name] = (m.start(), end)
        body = ir[ir.index("\n", m.start()) : end]
        refs[name] = {name_of(r) for r in REF.finditer(body)}
        if not LOCAL_DEFINE.match(ir, m.start()):
            roots.add(name)
    for m in GLOBAL.finditer(ir):
        name = name_of(m)
        rest = m.group(0)[m.end("q" if m["q"] is not None else "n") :]
        refs[name] = {name_of(r) for r in REF.finditer(rest)}
        if not LOCAL_GLOBAL.match(rest):
            roots.add(name)
    return defs, refs, roots


def stub_set(defs, refs, roots):
    """The candidates the code that stays cannot reach (a walk from the
    roots that does not enter the printer's entry), and the candidates it
    reaches."""
    seen, todo = set(), [r for r in roots if not ENTRY.match(r)]
    while todo:
        name = todo.pop()
        if name in seen:
            continue
        seen.add(name)
        todo.extend(r for r in refs.get(name, ()) if r not in seen and not ENTRY.match(r))
    stub = {n for n in defs if candidate(n) and n not in seen}
    return stub, {n for n in defs if candidate(n) and n in seen}


def stub_header(header, group):
    header = re.sub(r" #\d+(?= |$)", "", header)
    header = re.sub(r" personality ptr " + NAME, "", header)
    if not header.endswith(" {"):
        sys.exit(f"klee-stub-symbolizer: unexpected definition line: {header[:200]}")
    return header[: -len(" {")] + f" #{group} {{"


def rewrite(ir):
    defs, refs, roots = parse(ir)
    stub, _ = stub_set(defs, refs, roots)
    groups = [int(g) for g in re.findall(r"^attributes #(\d+) ", ir, re.M)]
    group = max(groups, default=-1) + 1
    out, last = [], 0
    for name, (start, end) in sorted(defs.items(), key=lambda d: d[1][0]):
        if name not in stub:
            continue
        header = ir[start : ir.index("\n", start)]
        out.append(ir[last:start])
        out.append("\n".join([stub_header(header, group), "start:"] + STUB_BODY + ["}"]) + "\n")
        last = end
    out.append(ir[last:])
    ir = "".join(out)
    if stub:
        if not re.search(r"^declare [^\n]*@abort\(\)", ir, re.M):
            ir += "\ndeclare void @abort()\n"
        ir += f"\nattributes #{group} = {{ {STUB_ATTRS} }}\n"
    kept = sorted(n for n in defs if candidate(n) and n not in stub)
    return ir, len(stub), kept


def is_stub(ir, start, end):
    body = [line.strip() for line in ir[start:end].splitlines()[1:-1]]
    return [b for b in body if b and not b.endswith(":")] == [s.strip() for s in STUB_BODY]


def check(ir):
    """The candidates that only symbolizer code reaches but that still have
    a real body, the candidates that live code reaches but that are stubs
    (live code would abort), and the kept (shared) candidates with their
    sizes."""
    defs, refs, roots = parse(ir)
    stub, live = stub_set(defs, refs, roots)
    bad = sorted(n for n in stub if not is_stub(ir, *defs[n]))
    dead = sorted(n for n in live if is_stub(ir, *defs[n]))
    kept = {n: ir[defs[n][0] : defs[n][1]].count("\n") - 2 for n in live if n not in dead}
    return bad, dead, kept


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--check":
        with open(sys.argv[2]) as f:
            bad, dead, kept = check(f.read())
        if bad:
            sys.exit(
                "klee-stub-symbolizer: backtrace symbolizer code is still in the module: "
                + ", ".join(bad[:10])
                + (f" (and {len(bad) - 10} more)" if len(bad) > 10 else "")
            )
        if dead:
            sys.exit(
                "klee-stub-symbolizer: code outside the backtrace printer calls an abort stub: "
                + ", ".join(dead[:10])
                + (f" (and {len(dead) - 10} more)" if len(dead) > 10 else "")
            )
        for name, size in sorted(kept.items()):
            print(f"klee-stub-symbolizer: shared body kept ({size} lines): {name}")
        return
    if len(sys.argv) != 3 or sys.argv[1].startswith("-"):
        sys.exit(__doc__)
    with open(sys.argv[1]) as f:
        ir, stubbed, kept = rewrite(f.read())
    with open(sys.argv[2], "w") as f:
        f.write(ir)
    print(f"klee-stub-symbolizer: {stubbed} symbolizer function(s) now abort, {len(kept)} shared kept")


if __name__ == "__main__":
    main()
