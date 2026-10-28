#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 2.8 (D7 A-fwd), host part: generates NonDetGeneratorAFL.ll,
# syntax-checks it with clang, checks that it has no stub, that the only
# AFL++ names it uses are those of the __AFL_FUZZ_INIT / __AFL_LOOP expansions
# of NonDetGeneratorAFL.c, and that libmap2check.a defines none of the C
# names the module defines (main, map2check_non_det_*, nondet_*,
# get_next_input_from_afl, the reader's and the expansions' globals; the
# names come from the .ll). The module needs afl-compiler-rt
# (__afl_persistent_loop), so it is not linked natively here: it runs in
# scripts/runtime-ir/test-afl-generator.sh (Docker).
#
# Usage: test-afl-ir.sh [<libmap2check.a>]
#   default lib: target/release/libmap2check.a (cargo build --release --all-features)
# Output: target/runtime-ir/NonDetGeneratorAFL.ll (not committed), the
# coverage extra of scripts/runtime-abi-coverage.sh.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LIB="${1:-$ROOT/target/release/libmap2check.a}"
OUT="$ROOT/target/runtime-ir"
LL="$OUT/NonDetGeneratorAFL.ll"
CLANG="${CLANG:-clang}"
TARGET=(--target=x86_64-pc-linux-gnu)
[ -f "$LIB" ] || { echo "missing $LIB (cargo build --release --all-features)" >&2; exit 2; }

python3 -I "$HERE/gen_ll.py" --module NonDetGeneratorAFL "$ROOT/docs/runtime-abi/inventory.tsv" "$OUT"
"$CLANG" "${TARGET[@]}" -c -x ir "$LL" -o /dev/null
echo "OK: $LL passes $("$CLANG" --version | head -1)"

if grep -q 'm2c-stub' "$LL"; then
  echo "FAIL: $LL has a stub (; m2c-stub)" >&2; exit 1
fi
# Only the AFL++ names of the expansions (afl-cc 4.40c), defined or used.
afl="$(grep -oE '@__afl_[A-Za-z0-9_]+' "$LL" | sort -u | tr '\n' ' ')"
want="@__afl_connected @__afl_fuzz_alt @__afl_fuzz_alt_ptr @__afl_fuzz_len @__afl_fuzz_ptr @__afl_persistent_loop @__afl_sharedmem_fuzzing "
[ "$afl" = "$want" ] || { echo "FAIL: unexpected AFL++ names: $afl" >&2; exit 1; }
grep -q 'c"##SIG_AFL_PERSISTENT##\\00"' "$LL" || { echo "FAIL: no ##SIG_AFL_PERSISTENT## marker" >&2; exit 1; }
funcs="$(sed -nE 's/^define [^@]*@([A-Za-z0-9_.$]+)\(.*/\1/p' "$LL" | grep -v '^m2c_' || true)"
[ "$(wc -l <<<"$funcs")" = 30 ] || { echo "FAIL: expected 30 defined C functions, got $(wc -l <<<"$funcs")" >&2; exit 1; }
data="$(sed -nE 's/^@([A-Za-z0-9_]+) = global .*/\1/p' "$LL")"
[ "$(tr '\n' ' ' <<<"$data")" = "__afl_sharedmem_fuzzing __afl_fuzz_alt __afl_fuzz_alt_ptr map2check_afl_data map2check_afl_size " ] \
  || { echo "FAIL: unexpected external globals: $(tr '\n' ' ' <<<"$data")" >&2; exit 1; }
names="$(printf '%s\n%s\n' "$funcs" "$data")"
leaks="$(nm --defined-only --extern-only "$LIB" 2>/dev/null | awk 'NF==3 {print $3}' | sort -u \
  | grep -xF -f <(printf '%s\n' "$names") || true)"
if [ -n "$leaks" ]; then
  echo "FAIL: $LIB defines C names of NonDetGeneratorAFL:" >&2; echo "$leaks" >&2; exit 1
fi
echo "OK: NonDetGeneratorAFL.ll defines the 30 C functions and 5 globals, no stub, and the staticlib none of them"
