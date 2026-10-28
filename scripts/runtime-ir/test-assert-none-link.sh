#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 2.4 (D7 A-fwd): generates AnalysisModeAssert.ll and AnalysisModeNone.ll,
# syntax-checks them with clang, links each with tests/runtime-ir/assert_link.c
# against the release staticlib and checks that every C name reaches its
# __m2c_rt_{assert,none}_* entry point: exit status and property files as
# AnalysisModeAssert.c, AnalysisModeNone.c and PropertyGenerator.c write them.
# Also checks that libmap2check.a defines none of the C names of the modules
# (map2check_assert, analysis_*) and that AnalysisModeAssert.ll defines
# __VERIFIER_assert as an empty function.
#
# Usage: test-assert-none-link.sh [<libmap2check.a>]
#   default lib: target/release/libmap2check.a (cargo build --release --all-features)
# Output: target/runtime-ir/AnalysisMode{Assert,None}.ll (not committed).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LIB="${1:-$ROOT/target/release/libmap2check.a}"
OUT="$ROOT/target/runtime-ir"
CLANG="${CLANG:-clang}"
TARGET=(--target=x86_64-pc-linux-gnu)
[ -f "$LIB" ] || { echo "missing $LIB (cargo build --release --all-features)" >&2; exit 2; }

for m in AnalysisModeAssert AnalysisModeNone; do
  python3 -I "$HERE/gen_ll.py" --module "$m" "$ROOT/docs/runtime-abi/inventory.tsv" "$OUT"
  "$CLANG" "${TARGET[@]}" -c -x ir "$OUT/$m.ll" -o /dev/null
  echo "OK: $OUT/$m.ll passes $("$CLANG" --version | head -1)"
done

# __VERIFIER_assert is empty in C (AnalysisModeAssert.c:25-27): an empty
# define in the IR, not a stub.
grep -qxF 'define void @__VERIFIER_assert(i32 %a0) {' "$OUT/AnalysisModeAssert.ll" \
  && ! grep -q 'm2c-stub' "$OUT/AnalysisModeAssert.ll" \
  || { echo "FAIL: __VERIFIER_assert is not an unmarked empty define" >&2; exit 1; }

# The staticlib must not define the C names of the modules (ruling: IR only),
# __VERIFIER_assert included: the legacy export of the libfuzzer and klee
# features left the C ABI in Task 2.10, and one that reappears fails here.
leaks="$(nm --defined-only --extern-only "$LIB" 2>/dev/null | awk 'NF==3 {print $3}' \
  | grep -xE 'analysis_(init|destroy|is_program_correct|generate_aux_witness_files)|map2check_assert|__VERIFIER_assert' || true)"
if [ -n "$leaks" ]; then
  echo "FAIL: $LIB defines C names of AnalysisModeAssert/None:" >&2; echo "$leaks" >&2; exit 1
fi

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
"$CLANG" "${TARGET[@]}" -DMODE_ASSERT "$ROOT/tests/runtime-ir/assert_link.c" "$OUT/AnalysisModeAssert.ll" "$LIB" \
  -ldl -lpthread -lm -o "$T/assert_link"
"$CLANG" "${TARGET[@]}" -DMODE_NONE "$ROOT/tests/runtime-ir/assert_link.c" "$OUT/AnalysisModeNone.ll" "$LIB" \
  -ldl -lpthread -lm -o "$T/none_link"

rc=0
# Contents of a file, byte for byte (trailing newlines kept), or "-" if absent.
content() { if [ -f "$1" ]; then cat "$1"; printf '.'; else printf -- '-'; fi; }
# bin scenario expected-exit map2check_property map2check_property_assert (- = absent)
check() {
  local bin="$1" name="$2" want_status="$3" want_prop="$4" want_assert="$5" d status
  d="$T/$bin.$name"; mkdir "$d"
  status=0
  { (ulimit -c 0; cd "$d" && exec "$T/$bin" "$name") >/dev/null 2>&1 || status=$?; } 2>/dev/null
  local got_prop got_assert extra
  got_prop="$(content "$d/map2check_property")"
  got_assert="$(content "$d/map2check_property_assert")"
  extra="$(cd "$d" && ls | grep -vxE 'map2check_property|map2check_property_assert' || true)"
  if [ "$status" != "$want_status" ] || [ "$got_prop" != "$want_prop" ] || [ "$got_assert" != "$want_assert" ] || [ -n "$extra" ]; then
    echo "FAIL $bin $name: status $status (want $want_status)" >&2
    printf '  map2check_property: %q (want %q)\n' "$got_prop" "$want_prop" >&2
    printf '  map2check_property_assert: %q (want %q)\n' "$got_assert" "$want_assert" >&2
    [ -z "$extra" ] || echo "  extra files: $extra" >&2
    rc=1
  else
    echo "ok $bin $name"
  fi
}
# PropertyGenerator.c:92-96 (ASSERT) and :124-130; TARGET_REACHED :81-85;
# map2check_error aborts (Map2CheckFunctions.c:72-102): 134 = 128 + SIGABRT.
text() { printf '%s\nLine: %s\nFunction: %s\n.' "$1" "$2" "$3"; }
check assert_link assert0 134 "$(text ASSERT 21 main)" "$(text ASSERT 21 main)"
check assert_link assert1 0 "$(printf 'NONE\n.')" -
check assert_link verifier_assert 0 "$(printf 'NONE\n.')" -
check assert_link analysis 0 "$(printf 'NONE\n.')" -
check none_link target 134 "$(text TARGET-REACHED 22 reach_error)" -
check none_link analysis 0 "$(printf 'NONE\n.')" -
[ "$rc" = 0 ] && echo "OK: AnalysisModeAssert.ll and AnalysisModeNone.ll forwarders reach the Rust core"
exit $rc
