#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Self-tests of the two post-processing scripts of the Rust core's bitcode
# (D1 route A', D7 "Pós-processamento do núcleo";
# scripts/build-runtime-bc.sh runs both). They used to run
# inside scripts/build-klee-runtime.sh, which left with the legacy `klee`
# feature in Task 2.10; the checks are the same.
#
#   scripts/klee-stub-symbolizer.py  std's backtrace symbolizer -> abort:
#     a body the remaining code shares keeps working (lli-16 returns 42, a
#     printer-named one too), the printer path aborts (134), and the --check
#     guard rejects the fixture before the rewrite and a stub that live code
#     calls (tests/klee/stub-symbolizer{,-live}.ll).
#   scripts/klee-lower-intrinsics.py  vector intrinsics KLEE 3.1 cannot run
#     -> scalar code: the scalar versions compute what the intrinsics compute
#     (lli-16 on tests/klee/lower-intrinsics.ll), and an unknown intrinsic is
#     rejected (tests/klee/unknown-intrinsic.ll).
#
# Usage: scripts/test-klee-postprocess.sh
# Environment: LLI (default lli-16).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LLI="${LLI:-lli-16}"
die() { echo "test-klee-postprocess: FAIL: $*" >&2; exit 1; }
command -v "$LLI" >/dev/null || die "$LLI not found in PATH"
fixtures="$ROOT/tests/klee"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

stub="$ROOT/scripts/klee-stub-symbolizer.py"
"$LLI" "$fixtures/stub-symbolizer.ll" >/dev/null 2>&1 && rc=0 || rc=$?
[ "$rc" = 42 ] || die "$LLI: the stub fixture returned $rc, not 42"
python3 -I "$stub" "$fixtures/stub-symbolizer.ll" "$work/stub-fixture.ll" >/dev/null ||
  die "the stub self-test fixture was rejected"
"$LLI" "$work/stub-fixture.ll" >/dev/null 2>&1 && rc=0 || rc=$?
[ "$rc" = 42 ] || die "the stub rewrite broke a shared body: the fixture returned $rc, not 42"
("$LLI" "$work/stub-fixture.ll" backtrace >/dev/null 2>&1) 2>/dev/null && rc=0 || rc=$?
[ "$rc" = 134 ] || die "the stubbed printer path did not abort: the fixture returned $rc, not 134"
if python3 -I "$stub" --check "$fixtures/stub-symbolizer.ll" >/dev/null 2>&1; then
  die "the symbolizer guard accepted a module that still has the symbolizer (stub-symbolizer.ll)"
fi
python3 -I "$stub" --check "$work/stub-fixture.ll" >/dev/null ||
  die "the symbolizer guard rejected the rewritten fixture"
if python3 -I "$stub" --check "$fixtures/stub-symbolizer-live.ll" >/dev/null 2>&1; then
  die "the symbolizer guard accepted a stub that live code calls (stub-symbolizer-live.ll)"
fi
echo "ok klee-stub-symbolizer.py"

lower="$ROOT/scripts/klee-lower-intrinsics.py"
python3 -I "$lower" "$fixtures/lower-intrinsics.ll" "$work/fixture.ll" >/dev/null ||
  die "the lowering self-test fixture was rejected"
expected="$("$LLI" "$fixtures/lower-intrinsics.ll")" || die "$LLI failed on the fixture"
got="$("$LLI" "$work/fixture.ll")" || die "$LLI failed on the lowered fixture"
[ "$expected" = "$got" ] ||
  die "the scalar versions differ from the intrinsics: '$expected' vs '$got'"
if python3 -I "$lower" "$fixtures/unknown-intrinsic.ll" "$work/unknown.ll" >/dev/null 2>&1; then
  die "the lowering accepted an intrinsic KLEE 3.1 cannot execute (unknown-intrinsic.ll)"
fi
echo "ok klee-lower-intrinsics.py"
echo "OK: post-processing self-tests pass ($("$LLI" --version | sed -n 's/.*LLVM version //p' | head -1))"
