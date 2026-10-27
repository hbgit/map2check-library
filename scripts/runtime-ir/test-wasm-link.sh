#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 2.9 (D7 A-fwd): generates WasmRuntimeStubs.ll, syntax-checks it with
# clang and links tests/runtime-ir/wasm_link.c against the release staticlib.
# Every wasm_rt_* C name (the ones wasm2c output calls) must reach its
# __m2c_rt_wasm_* entry point and behave as WasmRuntimeStubs.c; the trap
# scenarios check the abort status and the files written. The three
# map2check_wasm_* of AnalysisModeMemtrack are covered by
# test-memtrack-link.sh (wasm-free, wasm-access, wasm-shared-log).
# Also checks that libmap2check.a defines none of the C names of the module
# (no exemption since Task 2.10, which removed the legacy wasm_rt_* exports).
#
# Usage: test-wasm-link.sh [<libmap2check.a>]
#   default lib: target/release/libmap2check.a (cargo build --release --all-features)
# Output: target/runtime-ir/WasmRuntimeStubs.ll (not committed).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LIB="${1:-$ROOT/target/release/libmap2check.a}"
OUT="$ROOT/target/runtime-ir"
CLANG="${CLANG:-clang}"
TARGET=(--target=x86_64-pc-linux-gnu)
LL="$OUT/WasmRuntimeStubs.ll"
[ -f "$LIB" ] || { echo "missing $LIB (cargo build --release --all-features)" >&2; exit 2; }

python3 -I "$HERE/gen_ll.py" --module WasmRuntimeStubs "$ROOT/docs/runtime-abi/inventory.tsv" "$OUT"
"$CLANG" "${TARGET[@]}" -c -x ir "$LL" -o /dev/null
echo "OK: $LL passes $("$CLANG" --version | head -1)"

# No placeholder left; proc_exit is an empty C body (WasmRuntimeStubs.c:90-93),
# so an unmarked empty define.
! grep -q 'm2c-stub' "$LL" || { echo "FAIL: WasmRuntimeStubs.ll still has m2c-stub defines" >&2; exit 1; }
grep -qxF 'define void @w2c_wasi__snapshot__preview1_proc_exit(ptr %a0, i32 %a1) {' "$LL" \
  || { echo "FAIL: proc_exit is not an unmarked define" >&2; exit 1; }

# The names the module defines, from the .ll itself.
DEFS="$(sed -nE 's/^define[^@]*@([A-Za-z0-9_.]+)\(.*/\1/p' "$LL" | sort -u)"
NAMES="$(printf '%s\n' "$DEFS" | paste -sd'|')"
[ "$(printf '%s\n' "$DEFS" | wc -l)" = 10 ] \
  || { echo "FAIL: WasmRuntimeStubs.ll does not define the 10 C names" >&2; exit 1; }

# The staticlib must not define them (ruling: IR only). The legacy Rust
# exports of the same names left the C ABI in Task 2.10; one that reappears
# fails here.
leaks="$(nm --defined-only --extern-only "$LIB" 2>/dev/null | awk 'NF==3 {print $3}' | grep -xE "$NAMES" || true)"
if [ -n "$leaks" ]; then
  echo "FAIL: $LIB defines C names of WasmRuntimeStubs:" >&2; echo "$leaks" >&2; exit 1
fi

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
"$CLANG" "${TARGET[@]}" "$ROOT/tests/runtime-ir/wasm_link.c" "$LL" "$LIB" \
  -ldl -lpthread -lm -o "$T/wasm_link"

rc=0
run() { # scenario dir -> exit status
  local status=0
  { (ulimit -c 0; cd "$2" && exec "$T/wasm_link" "$1") >/dev/null 2>&1 || status=$?; } 2>/dev/null
  echo "$status"
}
# scenario expected-exit [file=content ...]: the exact set of files written.
check() {
  local name="$1" want="$2" d status; shift 2
  d="$T/$name"; mkdir "$d"
  status="$(run "$name" "$d")"
  [ "$status" = "$want" ] || { echo "FAIL $name: status $status (want $want)" >&2; rc=1; return; }
  local names=() pair f
  for pair in "$@"; do
    f="${pair%%=*}"; names+=("$f")
    [ -f "$d/$f" ] || { echo "FAIL $name: $f missing" >&2; rc=1; return; }
    [ "$(cat "$d/$f"; printf .)" = "$(printf "${pair#*=}"; printf .)" ] \
      || { echo "FAIL $name: $f = $(od -c "$d/$f" | head -3)" >&2; rc=1; return; }
  done
  local got exp
  got="$(cd "$d" && ls -A | sort)"; exp="$(printf '%s\n' "${names[@]:-}" | sort | grep . || true)"
  [ "$got" = "$exp" ] || { echo "FAIL $name: files [$got] (want [$exp])" >&2; rc=1; return; }
  echo "ok $name"
}
for s in memory grow table init proc_exit; do check "$s" 0; done
# WasmRuntimeStubs.c:110-116: map2check_error aborts (134 = 128 + SIGABRT).
# No mode: nothing is written.
check trap 134
# SD-19: with a mode set the trap records an UNKNOWN verdict and writes the
# frontend's UNKNOWN file, as map2check_error does (tests/legacy_golden/UNKNOWN:
# map2check_property__unknown). map2check_checked_error comes from
# generate_confirmation_file, which the WitnessGeneration module (not linked
# here) writes.
check trap-mode 134 'map2check_property__unknown=UNKNOWN\n'
[ "$rc" = 0 ] && echo "OK: WasmRuntimeStubs.ll forwarders reach the Rust core"
exit $rc
