#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Inventory the ABI of the Map2Check C runtime and compare it with this library.

Writes two tab-separated files to --out-dir, sorted by symbol:

  inventory.tsv  symbol kind signature module referenced_by
  rust-gap.tsv   symbol status rust_signature

A row exists for every external symbol defined (nm types T/D/B/R/C/V/W) by an
object compiled from modules/backend/library/lib/*.c. `signature` is the
`type.qualType` clang prints in its JSON AST for the definition; `module` lists
the .bc files that define it (joined by '+'); `referenced_by` is a subset of
pass+frontend+runtime ('-' when empty):

  pass      the name is a string literal (or the expansion of a `"prefix" #arg`
            macro body for every invocation) in modules/backend/pass/*.{cpp,hpp}
  frontend  the name is a string literal in modules/frontend/*.{cpp,hpp}
  runtime   the symbol is undefined in one runtime object and defined in another

WasmRuntimeStubs.c includes wasm-rt.h from WABT. When the host has no WABT the
script falls back (-idirafter, so a real wasm-rt.h always wins) to a minimal
shim written to a temporary directory; it declares the WABT typedef names the
file uses, so the qualType spelling is the same as with WABT.

rust-gap.tsv compares each inventory symbol with the external symbols defined
in --rust-lib (nm) and the declarations of --rust-header (clang JSON AST):
`same` needs an equal qualType, `different` otherwise, `missing` when the
archive does not define the symbol.

Regenerate the committed files from the repository root with:

  cargo build --release --all-features
  python3 -I scripts/runtime-abi-inventory.py --map2check vendor/map2check \\
      --out-dir docs/runtime-abi --rust-lib target/release/libmap2check.a \\
      --rust-header include/map2check.h

Needs clang and nm (binutils or llvm) on PATH.
"""

import argparse
import glob
import json
import os
import re
import subprocess
import sys
import tempfile

DEFINED_TYPES = set("TDBRCVW")
WASM_SHIM = """\
/* Minimal stand-in for WABT's wasm-rt.h (runtime-abi-inventory.py). */
#ifndef WASM_RT_SHIM_H
#define WASM_RT_SHIM_H
#include <stdbool.h>
#include <stdint.h>
typedef enum { WASM_RT_TRAP_NONE } wasm_rt_trap_t;
typedef struct {
  uint8_t *data;
  uint8_t *data_end;
  uint64_t pages, max_pages, size;
  uint32_t page_size;
  bool is64;
} wasm_rt_memory_t;
typedef struct {
  void *data;
  uint32_t max_size, size;
} wasm_rt_funcref_table_t;
#endif
"""

STRING_RE = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
IDENT_RE = re.compile(r"^[A-Za-z_.][A-Za-z0-9_.]*$")
DEFINE_RE = re.compile(r"^[ \t]*#[ \t]*define[ \t]+(\w+)\(([^)]*)\)((?:[^\n]*\\\n)*[^\n]*)", re.M)
STRINGIFY_RE = re.compile(r'"((?:[^"\\\n]|\\.)*)"\s*#\s*(\w+)')


def run(cmd, **kwargs):
    return subprocess.run(cmd, check=True, capture_output=True, text=True, **kwargs).stdout


def strip_comments(text):
    """Remove C/C++ comments, keeping string literals intact."""
    pattern = re.compile(r'//[^\n]*|/\*.*?\*/|"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\'', re.S)

    def keep(match):
        token = match.group(0)
        if token.startswith("/"):
            return "\n" * token.count("\n") if token.startswith("/*") else ""
        return token

    return pattern.sub(keep, text)


def split_args(text):
    """Split a macro argument list on top-level commas."""
    args, depth, current = [], 0, ""
    for char in text:
        if char == "," and depth == 0:
            args.append(current.strip())
            current = ""
            continue
        depth += char == "("
        depth -= char == ")"
        current += char
    args.append(current.strip())
    return args


def macro_names(text):
    """Names produced by `"prefix" #param` in macro bodies, for every invocation."""
    names = set()
    for match in DEFINE_RE.finditer(text):
        macro, params = match.group(1), [p.strip() for p in match.group(2).split(",")]
        templates = STRINGIFY_RE.findall(match.group(3))
        if not templates:
            continue
        body_free = text[: match.start()] + text[match.end():]
        for call in re.finditer(r"\b%s\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\)" % re.escape(macro), body_free):
            args = split_args(call.group(1))
            if len(args) != len(params):
                continue
            for prefix, param in templates:
                if param in params:
                    names.add(prefix + args[params.index(param)])
    return names


def referenced_names(files):
    """Identifier-shaped string literals plus macro expansions found in files."""
    names = set()
    for path in files:
        with open(path, encoding="utf-8", errors="replace") as handle:
            text = strip_comments(handle.read())
        names.update(s for s in STRING_RE.findall(text) if IDENT_RE.match(s))
        names.update(n for n in macro_names(text) if IDENT_RE.match(n))
    return names


def nm_symbols(path):
    """Return (defined {name: type}, undefined set) for an object or archive."""
    defined, undefined = {}, set()
    for line in run(["nm", path]).splitlines():
        fields = line.split()
        if len(fields) == 3 and fields[1] in DEFINED_TYPES:
            defined[fields[2]] = fields[1]
        elif len(fields) == 2 and fields[0] == "U":
            undefined.add(fields[1])
    return defined, undefined


def ast_declarations(source, flags):
    """Map name -> (kind, qualType) of top-level declarations; definitions win."""
    dump = run(["clang", "-w", "-fsyntax-only", "-Xclang", "-ast-dump=json"] + flags + [source])
    decls = {}
    for node in json.loads(dump).get("inner", []):
        if node.get("kind") not in ("FunctionDecl", "VarDecl") or "name" not in node:
            continue
        kind = "func" if node["kind"] == "FunctionDecl" else "data"
        if kind == "func":
            is_def = any(c.get("kind") == "CompoundStmt" for c in node.get("inner", []))
        else:
            is_def = node.get("storageClass") != "extern" or "init" in node
        name = node["name"]
        if is_def or name not in decls or not decls[name][2]:
            decls[name] = (kind, node["type"]["qualType"], is_def)
    return {name: (kind, sig) for name, (kind, sig, _) in decls.items()}


def compile_runtime(lib_dir, header_dir, work):
    """Compile every runtime .c; return {module: (defined, undefined, decls)}."""
    shim = os.path.join(work, "shim")
    os.makedirs(shim, exist_ok=True)
    with open(os.path.join(shim, "wasm-rt.h"), "w", encoding="utf-8") as handle:
        handle.write(WASM_SHIM)
    flags = ["-I", header_dir, "-I", lib_dir, "-idirafter", shim]
    modules = {}
    for source in sorted(glob.glob(os.path.join(lib_dir, "*.c"))):
        base = os.path.splitext(os.path.basename(source))[0]
        obj = os.path.join(work, base + ".o")
        run(["clang", "-w", "-c", "-O0"] + flags + ["-o", obj, source])
        defined, undefined = nm_symbols(obj)
        modules[base + ".bc"] = (defined, undefined, ast_declarations(source, flags))
    return modules


def build_inventory(m2c, work):
    backend = os.path.join(m2c, "modules", "backend")
    lib_dir = os.path.join(backend, "library", "lib")
    modules = compile_runtime(lib_dir, os.path.join(backend, "library", "header"), work)

    def sources(directory):
        return sorted(glob.glob(os.path.join(directory, "*.cpp")) + glob.glob(os.path.join(directory, "*.hpp")))

    pass_names = referenced_names(sources(os.path.join(backend, "pass")))
    frontend_names = referenced_names(sources(os.path.join(m2c, "modules", "frontend")))

    rows = {}
    for module, (defined, _, decls) in modules.items():
        for name, nm_type in defined.items():
            row = rows.setdefault(name, {"modules": [], "sigs": [], "kind": None})
            row["modules"].append(module)
            kind, sig = decls.get(name, ("func" if nm_type == "T" else "data", "?"))
            row["kind"] = row["kind"] or kind
            if sig not in row["sigs"]:
                row["sigs"].append(sig)

    for name, row in rows.items():
        refs = []
        if name in pass_names:
            refs.append("pass")
        if name in frontend_names:
            refs.append("frontend")
        if any(name in undefined and module not in row["modules"]
               for module, (_, undefined, _) in modules.items()):
            refs.append("runtime")
        row["refs"] = "+".join(refs) or "-"
        row["signature"] = " | ".join(row["sigs"])
    unresolved = sorted(pass_names - set(rows))
    return rows, unresolved


def rust_gap(rows, rust_lib, rust_header):
    defined, _ = nm_symbols(rust_lib)
    decls = ast_declarations(rust_header, ["-x", "c"])
    gap = {}
    for name, row in rows.items():
        if name not in defined:
            gap[name] = ("missing", "-")
        elif name not in decls:
            gap[name] = ("different", "(not declared in header)")
        else:
            sig = decls[name][1]
            gap[name] = ("same" if sig == row["signature"] else "different", sig)
    return gap


def write_tsv(path, header, lines):
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("\t".join(header) + "\n")
        for line in lines:
            handle.write("\t".join(line) + "\n")


def main(argv=None):
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--map2check", required=True, help="Map2Check source tree (vendor/map2check)")
    parser.add_argument("--out-dir", required=True, help="directory for inventory.tsv and rust-gap.tsv")
    parser.add_argument("--rust-lib", required=True, help="static library to compare (libmap2check.a)")
    parser.add_argument("--rust-header", required=True, help="its C header (include/map2check.h)")
    args = parser.parse_args(argv)

    with tempfile.TemporaryDirectory() as work:
        rows, unresolved = build_inventory(args.map2check, work)
    gap = rust_gap(rows, args.rust_lib, args.rust_header)

    os.makedirs(args.out_dir, exist_ok=True)
    names = sorted(rows)
    write_tsv(os.path.join(args.out_dir, "inventory.tsv"),
              ["symbol", "kind", "signature", "module", "referenced_by"],
              ([n, rows[n]["kind"], rows[n]["signature"], "+".join(sorted(rows[n]["modules"])), rows[n]["refs"]]
               for n in names))
    write_tsv(os.path.join(args.out_dir, "rust-gap.tsv"), ["symbol", "status", "rust_signature"],
              ([n, gap[n][0], gap[n][1]] for n in names))

    counts = {s: sum(1 for g in gap.values() if g[0] == s) for s in ("same", "different", "missing")}
    print("defined: %d" % len(rows))
    print("rust: same %(same)d, different %(different)d, missing %(missing)d" % counts)
    print("pass-referenced names not defined by the runtime (%d):" % len(unresolved))
    for name in unresolved:
        print("  " + name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
