#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 2.7 (D7 A-fwd), host part: generates NonDetGeneratorKlee.ll,
# syntax-checks it with clang, and checks that libmap2check.a defines none of
# the C names the module defines (main, map2check_non_det_*, nondet_*: they
# belong to the generator modules only; the names come from the .ll). The
# module calls KLEE intrinsics, so it is not linked natively here: it runs
# under KLEE in scripts/runtime-ir/test-klee-generator.sh (Docker).
#
# Usage: test-klee-ir.sh [<libmap2check.a>]
#   default lib: target/release/libmap2check.a (cargo build --release --all-features)
# Output: target/runtime-ir/NonDetGeneratorKlee.ll (not committed), the
# coverage extra of scripts/runtime-abi-coverage.sh.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LIB="${1:-$ROOT/target/release/libmap2check.a}"
OUT="$ROOT/target/runtime-ir"
LL="$OUT/NonDetGeneratorKlee.ll"
CLANG="${CLANG:-clang}"
TARGET=(--target=x86_64-pc-linux-gnu)
[ -f "$LIB" ] || { echo "missing $LIB (cargo build --release --all-features)" >&2; exit 2; }

python3 -I "$HERE/gen_ll.py" --module NonDetGeneratorKlee "$ROOT/docs/runtime-abi/inventory.tsv" "$OUT"
"$CLANG" "${TARGET[@]}" -c -x ir "$LL" -o /dev/null
echo "OK: $LL passes $("$CLANG" --version | head -1)"

if grep -q 'm2c-stub' "$LL"; then
  echo "FAIL: $LL has a stub (; m2c-stub)" >&2; exit 1
fi
# Only the intrinsics of NonDetGeneratorKlee.c.
intr="$(sed -nE 's/^declare[^@]*@(klee_[A-Za-z0-9_]+)\(.*/\1/p' "$LL" | sort -u | tr '\n' ' ')"
if [ "$intr" != "klee_assume klee_get_value_i64 klee_make_symbolic " ]; then
  echo "FAIL: unexpected KLEE intrinsics: $intr" >&2; exit 1
fi
names="$(sed -nE 's/^define [^@]*@([A-Za-z0-9_.$]+)\(.*/\1/p' "$LL" | grep -v '^m2c_' || true)"
[ "$(wc -l <<<"$names")" = 28 ] || { echo "FAIL: expected 28 defined C names, got $(wc -l <<<"$names")" >&2; exit 1; }
leaks="$(nm --defined-only --extern-only "$LIB" 2>/dev/null | awk 'NF==3 {print $3}' | sort -u \
  | grep -xF -f <(printf '%s\n' "$names") || true)"
if [ -n "$leaks" ]; then
  echo "FAIL: $LIB defines C names of NonDetGeneratorKlee:" >&2; echo "$leaks" >&2; exit 1
fi
echo "OK: NonDetGeneratorKlee.ll defines the 28 C names, no stub, and the staticlib none of them"
