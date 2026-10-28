#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Guard (Task 2.10, D6): the C ABI the staticlib exports is the Map2Check
# runtime ABI and nothing else. The set of names the library's own objects
# define with external linkage (nm --defined-only --extern-only, functions
# and data) must be exactly
#   (a) the names of docs/runtime-abi/inventory.tsv owned by the core
#       modules (Map2CheckFunctions, TrackBBLog, NonDetLog,
#       PropertyGenerator), minus the `c-only` names of export-policy.tsv
#       (SD-22) and minus every name a generated IR module defines
#       (scripts/runtime-ir/gen_ll.py, the glue included);
#   (b) the core entry points `__m2c_rt_*` (rust-only in export-policy.tsv),
#       of which every one an IR module calls must be there.
# Only the members of the crate itself count (archive members named
# `map2check-<hash>.*.o`): std, core, compiler_builtins and the dependencies
# are the Rust toolchain's, not the library's ABI. In those members the
# toolchain also emits symbols that are not C ABI and are skipped: mangled
# Rust names (`_ZN...`, `_R...`), the allocator shim (`__rust_*`,
# `__rustc*`) and the personality references (`DW.ref.*`).
#
# Usage: check-export-set.sh [--lib <libmap2check.a>] [--inventory F]
#                            [--policy F] [--ll-dir D] [--without-wasm]
#   default lib:    target/release/libmap2check.a
#   default ll-dir: every module generated here into a temporary directory
#   --without-wasm  the lib is built without the `wasm` feature: the
#                   __m2c_rt_wasm_* that WasmRuntimeStubs calls are not
#                   required (and must be absent)
# Exit 1 with the names missing from or extra in the staticlib.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
export LC_ALL=C
LIB="$ROOT/target/release/libmap2check.a"
INV="$ROOT/docs/runtime-abi/inventory.tsv"
POL="$ROOT/docs/runtime-abi/export-policy.tsv"
LLDIR=""
WASM=1
while [ $# -gt 0 ]; do
  case "$1" in
    --lib) LIB="$2"; shift 2 ;;
    --inventory) INV="$2"; shift 2 ;;
    --policy) POL="$2"; shift 2 ;;
    --ll-dir) LLDIR="$2"; shift 2 ;;
    --without-wasm) WASM=0; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
for f in "$LIB" "$INV" "$POL"; do
  [ -f "$f" ] || { echo "missing $f" >&2; exit 2; }
done
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
if [ -z "$LLDIR" ]; then
  LLDIR="$T/ll"
  python3 -I "$ROOT/scripts/runtime-ir/gen_ll.py" "$INV" "$LLDIR"
fi
ls "$LLDIR"/*.ll >/dev/null 2>&1 || { echo "no .ll in $LLDIR" >&2; exit 2; }

# What the IR modules define and the __m2c_rt_* they call.
cat "$LLDIR"/*.ll | sed -nE 's/^define [^@]*@"?([A-Za-z0-9_.$]+)"?\(.*/\1/p;
  s/^@"?([A-Za-z0-9_.$]+)"? = (dso_local |weak |linkonce |common |hidden )*(global|constant|common|weak|linkonce)[ ].*/\1/p' \
  | sort -u > "$T/ir-defined"
[ -s "$T/ir-defined" ] || { echo "FAIL: no definition found in $LLDIR/*.ll" >&2; exit 2; }
cat "$LLDIR"/*.ll | grep -oE '@__m2c_rt_[A-Za-z0-9_]+' | tr -d '@' | sort -u > "$T/ir-calls"

# (a)
awk -F'\t' 'NR>1 && $2=="c-only" {print $1}' "$POL" | sort -u > "$T/conly"
awk -F'\t' 'NR>1 { n=split($5, m, "+"); for (i=1;i<=n;i++)
    if (m[i] ~ /^(Map2CheckFunctions|TrackBBLog|NonDetLog|PropertyGenerator)\.bc$/) { print $1; break } }' "$INV" \
  | sort -u | comm -23 - "$T/conly" | comm -23 - "$T/ir-defined" > "$T/a"
[ -s "$T/a" ] || { echo "FAIL: (a) is empty; is $INV the inventory?" >&2; exit 2; }

# The staticlib: external definitions of the crate's own members.
nm -A --defined-only --extern-only "$LIB" 2>/dev/null > "$T/nm" || true
[ -s "$T/nm" ] || { echo "FAIL: nm found no symbol in $LIB" >&2; exit 2; }
awk 'NF==3 { k=split($1, p, ":"); m=p[k-1]; if (m ~ /^map2check-[0-9a-f]+\./) print $3 }' "$T/nm" \
  | grep -vE '^(_ZN|_R[A-Z0-9_]|__rust_|__rustc|DW\.ref\.)' | sort -u > "$T/exported" || true
[ -s "$T/exported" ] || { echo "FAIL: no member map2check-<hash>.*.o with C exports in $LIB" >&2; exit 2; }

grep -E '^__m2c_rt_' "$T/exported" > "$T/b" || true
if [ "$WASM" = 0 ]; then
  grep -vE '^__m2c_rt_wasm_' "$T/ir-calls" > "$T/ir-calls.nw" || true
  mv "$T/ir-calls.nw" "$T/ir-calls"
  wasm="$(grep -E '^__m2c_rt_wasm_' "$T/b" || true)"
  if [ -n "$wasm" ]; then
    echo "FAIL: --without-wasm, but $(basename "$LIB") exports __m2c_rt_wasm_* entries" >&2; exit 1
  fi
fi
sort -u "$T/a" "$T/b" > "$T/want"
rc=0
extra="$(comm -13 "$T/want" "$T/exported")"
missing="$(comm -23 "$T/a" "$T/exported")"
uncalled="$(comm -23 "$T/ir-calls" "$T/b")"
if [ -n "$extra" ]; then
  echo "FAIL: $(basename "$LIB") exports names outside the C runtime ABI ((a) and __m2c_rt_*):" >&2
  printf '  %s\n' $extra >&2; rc=1
fi
if [ -n "$missing" ]; then
  echo "FAIL: $(basename "$LIB") does not export core names of the C runtime ABI (a):" >&2
  printf '  %s\n' $missing >&2; rc=1
fi
if [ -n "$uncalled" ]; then
  echo "FAIL: $(basename "$LIB") does not export core entry points the IR modules call:" >&2
  printf '  %s\n' $uncalled >&2; rc=1
fi
[ "$rc" = 0 ] && echo "OK: $(basename "$LIB") exports exactly the C runtime ABI: $(wc -l < "$T/a") core names (a) and $(wc -l < "$T/b") __m2c_rt_* entries (b)"
exit $rc
