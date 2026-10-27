#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 2.10 (D7 A-fwd): map2check_assume, map2check_crab_assume and
# map2check_assume_loop (Map2CheckFunctions.c:45-47) are delivered by the
# glue IR, Map2CheckFunctions-glue.ll, which Task 3.1 links into
# Map2CheckFunctions.bc. Generates and syntax-checks the glue, checks that the
# staticlib defines none of the three names, and links
# tests/runtime-ir/assume_link.c against the glue and the release staticlib:
#   record  the driver's own nondet_assume sees every argument, the char ones
#           widened as C's (int)expr;
#   none    with NonDetGeneratorNone.ll, whose nondet_assume is empty as in
#           C, every call returns.
#
# Usage: test-assume-link.sh [<libmap2check.a>]
#   default lib: target/release/libmap2check.a (cargo build --release --all-features)
# Output: target/runtime-ir/{Map2CheckFunctions-glue,NonDetGeneratorNone}.ll (not committed).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LIB="${1:-$ROOT/target/release/libmap2check.a}"
OUT="$ROOT/target/runtime-ir"
CLANG="${CLANG:-clang}"
TARGET=(--target=x86_64-pc-linux-gnu)
[ -f "$LIB" ] || { echo "missing $LIB (cargo build --release --all-features)" >&2; exit 2; }

for m in Map2CheckFunctions-glue NonDetGeneratorNone; do
  python3 -I "$HERE/gen_ll.py" --module "$m" "$ROOT/docs/runtime-abi/inventory.tsv" "$OUT"
  "$CLANG" "${TARGET[@]}" -c -x ir "$OUT/$m.ll" -o /dev/null
  echo "OK: $OUT/$m.ll passes $("$CLANG" --version | head -1)"
done

# The glue defines exactly the three names; the staticlib none of them.
got="$(sed -nE 's/^define [^@]*@([A-Za-z0-9_]+)\(.*/\1/p' "$OUT/Map2CheckFunctions-glue.ll" | sort | tr '\n' ' ')"
[ "$got" = "map2check_assume map2check_assume_loop map2check_crab_assume " ] \
  || { echo "FAIL: the glue defines '$got'" >&2; exit 1; }
leaks="$(nm --defined-only --extern-only "$LIB" 2>/dev/null | awk 'NF==3 {print $3}' \
  | grep -xE 'map2check_(crab_)?assume(_loop)?|nondet_assume' || true)"
if [ -n "$leaks" ]; then
  echo "FAIL: $LIB defines names of the glue or of a generator module:" >&2; echo "$leaks" >&2; exit 1
fi

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
"$CLANG" "${TARGET[@]}" -DRECORD "$ROOT/tests/runtime-ir/assume_link.c" "$OUT/Map2CheckFunctions-glue.ll" \
  "$LIB" -ldl -lpthread -lm -o "$T/record"
"$CLANG" "${TARGET[@]}" "$ROOT/tests/runtime-ir/assume_link.c" "$OUT/Map2CheckFunctions-glue.ll" \
  "$OUT/NonDetGeneratorNone.ll" "$LIB" -ldl -lpthread -lm -o "$T/none"

rc=0
want="$(printf '%s\n' 5 0 -2147483648 -1 0 -128 127)"
got="$(cd "$T" && ./record)" || { echo "FAIL record: exit $?" >&2; rc=1; }
if [ "$got" != "$want" ]; then
  echo "FAIL record: nondet_assume saw" >&2; printf '  %s\n' $got >&2; rc=1
else
  echo "ok record"
fi
status=0
got="$(cd "$T" && ./none)" || status=$?
if [ "$status" != 0 ] || [ "$got" != returned ]; then
  echo "FAIL none: status $status, output '$got'" >&2; rc=1
else
  echo "ok none"
fi
[ "$rc" = 0 ] && echo "OK: map2check_assume* of the glue IR reach nondet_assume"
exit $rc
