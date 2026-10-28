#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Builds a C program against the C runtime ABI as Map2Check links it (D6,
# D7): the release staticlib plus the generated IR modules the program needs
# (scripts/runtime-ir/gen_ll.py), the way the link tests of
# scripts/runtime-ir/ do. Used by tests/ffi_harness.c and the programs of
# test/ (CI and CLAUDE.md).
#
# Usage: build-c-abi-program.sh -o <out> [-m <Module>]... [--lib <libmap2check.a>]
#                               [-I <include-dir>] <src.c> [-- <clang flags>...]
#   -m        a module of gen_ll.py (e.g. AnalysisModeMemtrack,
#             Map2CheckFunctions-glue, NonDetGeneratorAFL); written to
#             target/runtime-ir/<Module>.ll and linked before the library
#   --lib     default target/release/libmap2check.a (cargo build --release --all-features)
#   -I        where map2check.h is (default include/)
# Environment: CLANG (default clang).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
CLANG="${CLANG:-clang}"
LIB="$ROOT/target/release/libmap2check.a"
INC="$ROOT/include"
OUT=""; SRC=""; MODS=(); FLAGS=()
usage() { echo "usage: $0 -o <out> [-m <Module>]... [--lib <lib.a>] [-I <dir>] <src.c> [-- <clang flags>...]" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    -o) OUT="$2"; shift 2 ;;
    -m) MODS+=("$2"); shift 2 ;;
    --lib) LIB="$2"; shift 2 ;;
    -I) INC="$2"; shift 2 ;;
    --) shift; FLAGS=("$@"); break ;;
    -*) usage ;;
    *) [ -z "$SRC" ] || usage; SRC="$1"; shift ;;
  esac
done
[ -n "$OUT" ] && [ -n "$SRC" ] || usage
[ -f "$LIB" ] || { echo "missing $LIB (cargo build --release --all-features)" >&2; exit 2; }
LLDIR="$ROOT/target/runtime-ir"
LLS=()
for m in "${MODS[@]}"; do
  python3 -I "$HERE/runtime-ir/gen_ll.py" --module "$m" "$ROOT/docs/runtime-abi/inventory.tsv" "$LLDIR"
  LLS+=("$LLDIR/$m.ll")
done
mkdir -p "$(dirname "$OUT")"
# The IR modules are compiled without the sanitizer flags of the C source:
# they are the runtime, as the .bc Map2Check links are.
objs=()
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
for ll in "${LLS[@]}"; do
  "$CLANG" --target=x86_64-pc-linux-gnu -O2 -c -x ir "$ll" -o "$T/$(basename "$ll" .ll).o"
  objs+=("$T/$(basename "$ll" .ll).o")
done
"$CLANG" "${FLAGS[@]}" -I "$INC" "$SRC" "${objs[@]}" "$LIB" \
  -ldl -lpthread -lm -o "$OUT"
