#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Test of scripts/build-runtime-bc.sh (Task 3.1):
#   usage              no argument -> exit 2; an <out-dir> with a foreign
#                      file -> refused (exit 1), the file left alone;
#   exact_file_list    the output is exactly the 21 files of the global
#                      constraints (the modules Caller::linkLLVM links);
#   deterministic      two clean builds (each with its own new
#                      CARGO_TARGET_DIR) give the same sha256 for all 21;
#   readable           llvm-dis-16 reads all 21 (on the host when it has
#                      llvm-dis-16, otherwise in the Map2Check image);
#   link_matrix        scripts/it/check-link-matrix.sh on the output gives
#                      "matrix: PASS", with and without --ref <C lib>.
# The first build stays in target/runtime-bc-test/a/out, the sha256 of both
# in target/runtime-bc-test/sha256-{a,b}.txt.
#
# Environment:
#   MATRIX=0      skip link_matrix (for a runner without the image).
#   M2C_INSTALL   the C install for --ref (default target/map2check-it/c).
# Exits 77 (skip) when the build cannot run (no rustc 1.72.1, or neither the
# LLVM 16 tools nor docker with the image), or when link_matrix needs the
# image or the C install and they are missing.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
BUILD="$HERE/build-runtime-bc.sh"
commit="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION" 2>/dev/null || true)"
IMAGE="${IMAGE:-map2check-dev:develop-${commit:0:12}}"
M2C_INSTALL="${M2C_INSTALL:-$ROOT/target/map2check-it/c}"
MATRIX="${MATRIX:-1}"
# Global constraints of the plan: the 21 module names.
WANT="Map2CheckFunctions TrackBBLog NonDetLog PropertyGenerator ContainerRealloc ContainerBTree BTree AnalysisModeMemtrack AnalysisModeMemcleanup AnalysisModeOverflow AnalysisModeAssert AnalysisModeNone AllocationLog ListLog HeapLog NonDetGeneratorNone NonDetGeneratorKlee NonDetGeneratorAFL WasmRuntimeStubs WitnessGeneration WitnessGenerationNone"

fail=0
ok() { echo "ok $*"; }
bad() { echo "FAIL $*" >&2; fail=1; }

# usage, before anything is built.
st=0; "$BUILD" > /dev/null 2>&1 || st=$?
[ "$st" = 2 ] && ok "usage: no argument, exit 2" || bad "usage: no argument gave exit $st, want 2"
W="$ROOT/target/runtime-bc-test"
rm -rf "$W"; mkdir -p "$W/foreign"
echo keep > "$W/foreign/notes.txt"
st=0; "$BUILD" "$W/foreign" > "$W/foreign.log" 2>&1 || st=$?
if [ "$st" = 1 ] && [ "$(cat "$W/foreign/notes.txt")" = keep ] && grep -q "notes.txt" "$W/foreign.log"; then
  ok "usage: a foreign file in <out-dir> is refused and kept"
else
  bad "usage: a foreign file in <out-dir>: exit $st, $(head -1 "$W/foreign.log")"
fi

# Can the build run here?
RUSTUP_TOOLCHAIN="${KLEE_RUSTC_TOOLCHAIN:-1.72.1}" rustc -vV > /dev/null 2>&1 \
  || { echo "SKIP: rustc ${KLEE_RUSTC_TOOLCHAIN:-1.72.1} missing (rustup toolchain install 1.72.1)" >&2; exit 77; }
host_llvm=1
for t in opt-16 llvm-as-16 llvm-dis-16 llvm-link-16 llvm-nm-16; do command -v "$t" > /dev/null 2>&1 || host_llvm=0; done
have_image=0
command -v docker > /dev/null 2>&1 && docker image inspect "$IMAGE" > /dev/null 2>&1 && have_image=1
[ "$host_llvm" = 1 ] || [ "$have_image" = 1 ] \
  || { echo "SKIP: neither the LLVM 16 tools nor docker with $IMAGE" >&2; exit 77; }

for b in a b; do
  mkdir -p "$W/$b"
  CARGO_TARGET_DIR="$W/$b/cargo" "$BUILD" "$W/$b/out" > "$W/$b/build.log" 2>&1 \
    || { bad "build $b failed: $(tail -3 "$W/$b/build.log")"; exit 1; }
  rm -rf "$W/$b/cargo"
done

want="$(for m in $WANT; do echo "$m.bc"; done | sort)"
for b in a b; do
  got="$(cd "$W/$b/out" && ls -A | sort)"
  if [ "$got" = "$want" ]; then ok "exact_file_list build $b: 21 files"
  else bad "exact_file_list build $b: $(diff <(echo "$want") <(echo "$got") | grep '^[<>]' | tr '\n' ' ')"; fi
done

(cd "$W/a/out" && sha256sum $(ls | sort)) > "$W/sha256-a.txt"
(cd "$W/b/out" && sha256sum $(ls | sort)) > "$W/sha256-b.txt"
if diff -u "$W/sha256-a.txt" "$W/sha256-b.txt" > "$W/sha256.diff"; then
  ok "deterministic: the 21 sha256 of two clean builds are equal"
else
  bad "deterministic: the builds differ: $(grep '^[-+][0-9a-f]' "$W/sha256.diff" | awk '{print $2}' | sort -u | tr '\n' ' ')"
fi

dis='n=0; for f in "$0"/*.bc; do llvm-dis-16 "$f" -o /dev/null || exit 1; n=$((n+1)); done; echo $n'
if [ "$host_llvm" = 1 ]; then
  n="$(bash -c "$dis" "$W/a/out" 2>&1 || true)"
else
  n="$(docker run --rm --network none -v "$W/a/out:/o:ro" "$IMAGE" bash -c "$dis" /o 2>&1 || true)"
fi
[ "$n" = 21 ] && ok "readable: llvm-dis-16 reads the 21 modules" || bad "readable: llvm-dis-16: $n"

if [ "$MATRIX" = 0 ]; then
  echo "link_matrix: skipped (MATRIX=0)"
elif [ "$have_image" = 0 ] || [ ! -x "$M2C_INSTALL/bin/map2check" ]; then
  [ "$fail" = 0 ] || exit 1
  echo "SKIP: link_matrix needs docker, $IMAGE and $M2C_INSTALL (scripts/it/build-map2check.sh)" >&2; exit 77
else
  for ref in "" "--ref $M2C_INSTALL/lib"; do
    log="$W/matrix${ref:+-ref}.txt"
    # shellcheck disable=SC2086
    "$ROOT/scripts/it/check-link-matrix.sh" $ref "$W/a/out" > "$log" 2>&1 || true
    if [ "$(tail -1 "$log")" = "matrix: PASS" ]; then ok "link_matrix ${ref:-(no --ref)}: matrix: PASS"
    else bad "link_matrix ${ref:-(no --ref)}: $(grep -m3 '^FAIL' "$log" | tr '\n' ' ') $(tail -1 "$log")"; fi
  done
fi
[ "$fail" = 0 ] && echo "OK: build-runtime-bc.sh gives the 21 modules, deterministically"
exit $fail
