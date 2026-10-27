#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Guard (Task 2.9 fix round): no code in the release staticlib may call or
# reference, by name, a symbol that a generated IR module (gen_ll.py) defines.
#
# Why: the IR modules define the C names and forward to the Rust core's
# __m2c_rt_* entry points. When the staticlib is linked next to an IR module,
# an intra-crate call by name to a symbol the IR defines (an exported Rust
# function of the same name, as the 1.x exports were until Task 2.10, or an
# extern declaration) relocates against that name, and the linker binds it
# to the IR's definition, which forwards back to the core: infinite
# recursion. `nm -u` cannot see this (the symbol is defined in the same
# object), so the guard reads the relocations: `objdump -dr` of every member
# of the archive, with the function each relocation sits in.
#
# Usage: check-no-ir-name-calls.sh [<libmap2check.a> [<ll-dir>]]
#   default lib:    target/release/libmap2check.a
#   default ll-dir: target/runtime-ir/all (every module, generated here)
# Allow-list: exact "caller>target" pairs in M2C_IR_CALL_ALLOW. Empty, and it
# must stay empty (Task 2.10); the variable exists for the fixture test.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LIB="${1:-$ROOT/target/release/libmap2check.a}"
LLDIR="${2:-}"
[ -f "$LIB" ] || { echo "missing $LIB (cargo build --release --all-features)" >&2; exit 2; }
if [ -z "$LLDIR" ]; then
  LLDIR="$ROOT/target/runtime-ir/all"
  python3 -I "$HERE/gen_ll.py" "$ROOT/docs/runtime-abi/inventory.tsv" "$LLDIR"
fi
ALLOW="${M2C_IR_CALL_ALLOW:-}"   # exact "caller>target" lines, one per line; empty today

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
# Every function and global the IR modules define with external linkage.
cat "$LLDIR"/*.ll | { sed -nE 's/^define [^@]*@([A-Za-z0-9_.$]+)\(.*/\1/p'
  sed -nE 's/^@([A-Za-z0-9_.$]+) = (global|constant|common|weak|linkonce)[ ].*/\1/p' "$LLDIR"/*.ll; } \
  | sort -u > "$T/names"
[ -s "$T/names" ] || { echo "FAIL: no names found in $LLDIR/*.ll" >&2; exit 2; }

# caller>target for every relocation in every member.
objdump -dr "$LIB" > "$T/dump" 2>/dev/null || { echo "FAIL: objdump -dr $LIB failed" >&2; exit 2; }
grep -qE '^[0-9a-f]+ <.*>:$' "$T/dump" || { echo "FAIL: no function disassembled from $LIB" >&2; exit 2; }
awk '
  /^[0-9a-f]+ <.*>:$/ { fn = $0; sub(/^[0-9a-f]+ </, "", fn); sub(/>:$/, "", fn); next }
  /^[ \t]+[0-9a-f]+:[ \t]+R_[A-Z0-9_]+[ \t]/ {
    t = $NF; sub(/[+-]0x[0-9a-f]+$/, "", t); print fn ">" t }' "$T/dump" | sort -u > "$T/relocs"

hits="$(awk -F'>' 'NR==FNR { n[$0]=1; next } ($2 in n)' "$T/names" "$T/relocs" || true)"
if [ -n "$ALLOW" ]; then
  hits="$(printf '%s\n' "$hits" | grep -vxF -f <(printf '%s\n' "$ALLOW") || true)"
fi
hits="$(printf '%s\n' "$hits" | grep . || true)"
if [ -n "$hits" ]; then
  echo "FAIL: code in $LIB references names that an IR module defines (caller>target):" >&2
  echo "$hits" >&2
  exit 1
fi
echo "OK: no relocation in $(basename "$LIB") targets one of the $(wc -l < "$T/names") names the IR modules define"
