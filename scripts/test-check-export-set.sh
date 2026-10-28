#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Fixture test of scripts/check-export-set.sh: archives built here with
# clang stand in for the staticlib. The real inventory, policy and IR modules
# define (a) and (b).
#   exact      the crate member defines (a) and every __m2c_rt_* the IR
#              calls, next to toolchain symbols and other members        -> OK
#   legacy     plus a legacy export (map2check_set_mode)                 -> FAIL
#   ir-name    plus a name an IR module defines (map2check_check_deref)  -> FAIL
#   data       plus a legacy data export                                 -> FAIL
#   missing    without map2check_track_bb                                -> FAIL
#   no-entry   without one __m2c_rt_* entry the IR calls                 -> FAIL
#   glue       plus map2check_assume (defined by the glue IR)            -> FAIL
#   no-wasm    without the __m2c_rt_wasm_* entries: FAIL by default, OK
#              with --without-wasm, which refuses the full set
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
export LC_ALL=C
GUARD="$HERE/check-export-set.sh"
CLANG="${CLANG:-clang}"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
python3 -I "$HERE/runtime-ir/gen_ll.py" "$ROOT/docs/runtime-abi/inventory.tsv" "$T/ll"

# (a) and the __m2c_rt_* the IR calls, computed independently of the guard.
cat "$T/ll"/*.ll | sed -nE 's/^define [^@]*@([A-Za-z0-9_.$]+)\(.*/\1/p' | sort -u > "$T/ir"
awk -F'\t' 'NR>1 && $2=="c-only" {print $1}' "$ROOT/docs/runtime-abi/export-policy.tsv" | sort -u > "$T/conly"
awk -F'\t' 'NR>1 && $5 ~ /^(Map2CheckFunctions|TrackBBLog|NonDetLog|PropertyGenerator)\.bc$/ {print $1}' \
  "$ROOT/docs/runtime-abi/inventory.tsv" | sort -u | comm -23 - "$T/conly" | comm -23 - "$T/ir" > "$T/a"
cat "$T/ll"/*.ll | grep -oE '@__m2c_rt_[A-Za-z0-9_]+' | tr -d '@' | sort -u > "$T/b"
grep -qx map2check_track_bb "$T/a" && grep -qx __m2c_rt_overflow_overflowError "$T/b" \
  || { echo "FAIL: fixture sets look wrong" >&2; exit 1; }

# archive <name> <names-file> [extra C]: the crate member defines every name
# of the file as a function; std and compiler_builtins members and
# toolchain symbols of the crate member are added in every archive.
archive() {
  local name="$1" names="$2" extra="${3:-}" d="$T/ar-$1"
  mkdir -p "$d"
  { while read -r s; do echo "void $s(void) {}"; done < "$names"
    echo "void _ZN9map2check3ffi4test17h0123456789abcdefE(void) {}"
    echo "void __rust_alloc(void) {}"
    echo "void __rust_no_alloc_shim_is_unstable(void) {}"
    printf '%s\n' "$extra"; } > "$d/crate.c"
  echo "void rust_panic(void) {} void rust_eh_personality(void) {} void map2check_set_mode(void) {}" > "$d/std.c"
  echo "int __divdi3(int a, int b) { return a / b; }" > "$d/cb.c"
  "$CLANG" -c -fno-builtin "$d/crate.c" -o "$d/map2check-0123456789abcdef.map2check.c0ffee-cgu.0.rcgu.o"
  "$CLANG" -c "$d/std.c" -o "$d/std-fedcba9876543210.std.beef-cgu.0.rcgu.o"
  "$CLANG" -c "$d/cb.c" -o "$d/compiler_builtins-0011223344556677.compiler_builtins.ab-cgu.000.rcgu.o"
  (cd "$d" && ar rc "$T/$name.a" ./*.o)
}

rc=0
# run <archive> <want 0|1> [grep pattern the report must contain]
run() {
  local a="$1" want="$2" pat="${3:-}" got=0
  "$GUARD" --lib "$T/$a.a" --ll-dir "$T/ll" ${GUARD_FLAGS:-} > "$T/$a.out" 2>&1 || got=$?
  if [ "$want" = 0 ] && [ "$got" != 0 ]; then
    echo "FAIL $a: guard refused (exit $got):" >&2; cat "$T/$a.out" >&2; rc=1
  elif [ "$want" = 1 ] && [ "$got" != 1 ]; then
    echo "FAIL $a: guard exit $got, want 1:" >&2; cat "$T/$a.out" >&2; rc=1
  elif [ -n "$pat" ] && ! grep -qE "$pat" "$T/$a.out"; then
    echo "FAIL $a: report lacks /$pat/:" >&2; cat "$T/$a.out" >&2; rc=1
  else
    echo "ok $a"
  fi
}

sort -u "$T/a" "$T/b" > "$T/exact"
archive exact "$T/exact"
run exact 0 '^OK: '
archive legacy "$T/exact" 'void map2check_set_mode(int m) { (void)m; }'
run legacy 1 '^  map2check_set_mode$'
archive ir-name "$T/exact" 'void map2check_check_deref(void) {}'
run ir-name 1 '^  map2check_check_deref$'
archive data "$T/exact" 'int map2check_legacy_flag = 1;'
run data 1 '^  map2check_legacy_flag$'
grep -vx map2check_track_bb "$T/exact" > "$T/missing"
archive missing "$T/missing"
run missing 1 'does not export core names.*'
grep -q '^  map2check_track_bb$' "$T/missing.out" || { echo "FAIL missing: track_bb not named" >&2; rc=1; }
grep -vx __m2c_rt_overflow_overflowError "$T/exact" > "$T/no-entry"
archive no-entry "$T/no-entry"
run no-entry 1 '^  __m2c_rt_overflow_overflowError$'
archive glue "$T/exact" 'void map2check_assume(int e) { (void)e; }'
run glue 1 '^  map2check_assume$'
grep -vE '^__m2c_rt_wasm_' "$T/exact" > "$T/no-wasm"
archive no-wasm "$T/no-wasm"
run no-wasm 1 '^  __m2c_rt_wasm_trap$'
GUARD_FLAGS=--without-wasm run no-wasm 0 '^OK: '
GUARD_FLAGS=--without-wasm run exact 1 'exports __m2c_rt_wasm_'
# The extra name is the only one reported.
[ "$(grep -c '^  ' "$T/legacy.out")" = 1 ] || { echo "FAIL legacy: report is not exact" >&2; cat "$T/legacy.out" >&2; rc=1; }

[ "$rc" = 0 ] && echo "OK: check-export-set.sh accepts exactly (a) and the __m2c_rt_* entries"
exit $rc
