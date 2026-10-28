#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 2.3 (D7 A-fwd): generates AnalysisModeOverflow.ll, syntax-checks it with
# clang, links it with tests/runtime-ir/overflow_link.c against the release
# staticlib and checks that each forwarder reaches its __m2c_rt_overflow_*
# entry point: exit status and property files as AnalysisModeOverflow.c and
# PropertyGenerator.c write them. Also checks that libmap2check.a defines none
# of the C names of the module (they belong to the IR only).
#
# Usage: test-overflow-link.sh [<libmap2check.a>]
#   default lib: target/release/libmap2check.a (cargo build --release --all-features)
# Output: target/runtime-ir/AnalysisModeOverflow.ll (not committed).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LIB="${1:-$ROOT/target/release/libmap2check.a}"
OUT="$ROOT/target/runtime-ir"
LL="$OUT/AnalysisModeOverflow.ll"
CLANG="${CLANG:-clang}"
# The triple of every delivered module (D7 item 6); explicit, so that a host
# clang with another default triple does not warn.
TARGET=(--target=x86_64-pc-linux-gnu)
[ -f "$LIB" ] || { echo "missing $LIB (cargo build --release --all-features)" >&2; exit 2; }

python3 -I "$HERE/gen_ll.py" --module AnalysisModeOverflow "$ROOT/docs/runtime-abi/inventory.tsv" "$OUT"
"$CLANG" "${TARGET[@]}" -c -x ir "$LL" -o /dev/null
echo "OK: $LL passes $("$CLANG" --version | head -1)"

# The staticlib must not define the C names of the module (ruling: IR only).
leaks="$(nm --defined-only --extern-only "$LIB" 2>/dev/null | awk 'NF==3 {print $3}' \
  | grep -xE 'analysis_(init|destroy|is_program_correct|generate_aux_witness_files)|map2check_binop_(add|sub|mul)(_uint)?|map2check_binop_(sdiv|srem)|overflowError|divisionByZeroError|unknown_not_supported' || true)"
if [ -n "$leaks" ]; then
  echo "FAIL: $LIB defines C names of AnalysisModeOverflow:" >&2; echo "$leaks" >&2; exit 1
fi

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
"$CLANG" "${TARGET[@]}" "$ROOT/tests/runtime-ir/overflow_link.c" "$LL" "$LIB" -ldl -lpthread -lm -o "$T/overflow_link"

rc=0
# Contents of a file, byte for byte (trailing newlines kept), or "-" if absent.
content() { if [ -f "$1" ]; then cat "$1"; printf '.'; else printf -- '-'; fi; }
# scenario  expected-exit  map2check_property  map2check_property_overflow (- = absent)
check() {
  local name="$1" want_status="$2" want_prop="$3" want_ovf="$4" d status
  d="$T/$name"; mkdir "$d"
  status=0
  { (ulimit -c 0; cd "$d" && exec "$T/overflow_link" "$name") >/dev/null 2>&1 || status=$?; } 2>/dev/null
  local got_prop got_ovf
  got_prop="$(content "$d/map2check_property")"
  got_ovf="$(content "$d/map2check_property_overflow")"
  local extra; extra="$(cd "$d" && ls | grep -vxE 'map2check_property|map2check_property_overflow' || true)"
  if [ "$status" != "$want_status" ] || [ "$got_prop" != "$want_prop" ] || [ "$got_ovf" != "$want_ovf" ] || [ -n "$extra" ]; then
    echo "FAIL $name: status $status (want $want_status)" >&2
    printf '  map2check_property: %q (want %q)\n' "$got_prop" "$want_prop" >&2
    printf '  map2check_property_overflow: %q (want %q)\n' "$got_ovf" "$want_ovf" >&2
    [ -z "$extra" ] || echo "  extra files: $extra" >&2
    rc=1
  else
    echo "ok $name"
  fi
}
# PropertyGenerator.c:86-91 / :116-122 (OVERFLOW), :98-102 (FALSE-DIVBYZERO);
# map2check_error aborts (Map2CheckFunctions.c:72-102): 134 = 128 + SIGABRT.
ovf() { printf 'OVERFLOW\nLine: %s\nFunction: %s\n.' "$1" "$2"; }
check add 134 "$(ovf 20 main)" "$(ovf 20 main)"
check sub 134 "$(ovf 21 main)" "$(ovf 21 main)"
check mul 134 "$(ovf 22 main)" "$(ovf 22 main)"
check sdiv 134 "$(ovf 23 main)" "$(ovf 23 main)"
check srem 134 "$(printf 'FALSE-DIVBYZERO\nLine: 24\nFunction: main\n.')" -
check overflowError 134 "$(ovf 25 f)" "$(ovf 25 f)"
# AnalysisModeOverflow.c:219-248: unsigned binops are no-ops; success writes NONE.
check uint 0 "$(printf 'NONE\n.')" -
check safe 0 "$(printf 'NONE\n.')" -
[ "$rc" = 0 ] && echo "OK: AnalysisModeOverflow.ll forwarders reach the Rust core"
exit $rc
