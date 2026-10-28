#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# The drop-in runtime as the 21 bitcode modules Map2Check links (the D7
# layout A-fwd, docs/cutover/d7-layout.md): exactly the file names the
# frontend's Caller::linkLLVM passes to llvm-link, nothing else in <out-dir>.
# Deterministic: two builds of the same tree give the same bytes
# (scripts/test-build-runtime-bc.sh). scripts/it/overlay-install.sh puts them
# into a copy of a C install of Map2Check.
#
#   Map2CheckFunctions.bc  the Rust core: klee/Cargo.toml with rustc 1.72.1
#                          (D1, route A'), features `dropin,wasm`, fat LTO,
#                          panic = abort, --emit=llvm-bc, then the D7
#                          post-processing below, linked with the IR glue
#                          (map2check_assume*);
#   the other 20           scripts/runtime-ir/gen_ll.py, assembled with
#                          llvm-as-16.
#
# D7 post-processing of the core ("Pós-processamento do núcleo"):
#   1. opt-16 --strip-debug (D1 condition 6);
#   2. scripts/klee-stub-symbolizer.py + opt-16 -passes=globaldce;
#   3. scripts/runtime-ir/stub_personality.py (rust_eh_personality and
#      std::panicking::rust_panic_with_hook -> abort; the hook approved by the
#      user on 2026-10-27);
#   4. scripts/klee-lower-intrinsics.py (KLEE 3.1 runs no vector intrinsic);
#   5. opt-16 -passes=internalize,globaldce, public = the names of
#      docs/runtime-abi/inventory.tsv that no IR module defines, plus __m2c_*
#      (the core never defines a name only a mode or generator module
#      defines: D7, Task 2.10 note);
#   6. one triple, x86_64-pc-linux-gnu, and no "Dwarf Version" module flag
#      (scripts/runtime-ir/drop_dwarf_flag.py).
# Guards: no `freeze` in the core after globaldce (KLEE 3.1 cannot execute
# it; scripts/runtime-ir/check_no_freeze.py names the functions, and the fix
# is in the Rust source, never a rewrite here); the core defines no name an
# IR module defines; every __m2c_rt_* an IR module references is defined by
# the core; the core references no klee_*/__afl_* intrinsic; the Rust part
# references no longjmp path (longjmp/setjmp, nondet_assume/cancel,
# map2check_assume*) and not the program (main, __map2check_main__), so the
# AFL++ generator's longjmp never crosses a Rust frame (D7 item 5);
# the final Map2CheckFunctions.bc has fewer than 9 500 instruction lines and
# fewer than 13 600 IR lines (the .ll that afl-clang-fast instruments and
# compiles three times per AFL++ run, and that KLEE loads and re-optimises:
# 125 829 instruction lines with std's backtrace symbolizer, 34 582 without
# it, 8 865 and 12 741 IR lines once Task 3.3 took core::fmt, std::io,
# std::fs and serde out of the drop-in build; the ceilings are those values
# plus about 7%) and no `llvm.bitreverse` (only miniz_oxide, part of the
# symbolizer, used it); the checks were in tests/klee_paths.sh until Task 2.10;
# llvm-dis-16 reads all 21 modules.
#
# Usage: build-runtime-bc.sh <out-dir>
#        build-runtime-bc.sh --check-core <final.ll>   (the two checks
#          above on a disassembled core; scripts/runtime-ir/test-core-checks.sh)
# Environment: M2C_CORE_MAX_LINES (default 9500), the instruction-line
# ceiling; M2C_CORE_MAX_IR_LINES (default 13600), the IR-line ceiling.
# The Rust step runs on the host (rustup toolchain KLEE_RUSTC_TOOLCHAIN,
# default 1.72.1). The LLVM 16 steps run on the host when opt-16, llvm-as-16,
# llvm-dis-16, llvm-link-16 and llvm-nm-16 are on PATH, otherwise in the
# Map2Check image (IMAGE, default map2check-dev:develop-<commit12>).
# Environment: CARGO_TARGET_DIR (default target/dropin-core).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
die() { echo "build-runtime-bc: error: $*" >&2; exit 1; }

MODULES="Map2CheckFunctions TrackBBLog NonDetLog PropertyGenerator ContainerRealloc ContainerBTree BTree AnalysisModeMemtrack AnalysisModeMemcleanup AnalysisModeOverflow AnalysisModeAssert AnalysisModeNone AllocationLog ListLog HeapLog NonDetGeneratorNone NonDetGeneratorKlee NonDetGeneratorAFL WasmRuntimeStubs WitnessGeneration WitnessGenerationNone"

# ---------------------------------------------------------------------------
# Instruction-line and IR-line ceilings and no llvm.bitreverse, on the final
# core's .ll.
check_core() {
  local ll="$1" max="${M2C_CORE_MAX_LINES:-9500}" max_ir="${M2C_CORE_MAX_IR_LINES:-13600}" lines ir
  lines="$(awk '/^define/{f=1; next} f&&/^}/{f=0; next} f{n++} END{print n+0}' "$ll")"
  if [ "$lines" -ge "$max" ]; then
    echo "the core has $lines instruction lines, expected < $max: is the backtrace symbolizer, core::fmt or std::io back (Task 3.3)?" >&2
    return 1
  fi
  ir="$(wc -l < "$ll")"
  if [ "$ir" -ge "$max_ir" ]; then
    echo "the core has $ir IR lines, expected < $max_ir: afl-clang-fast compiles it three times per AFL++ run (Task 3.3)" >&2
    return 1
  fi
  if grep -q 'llvm\.bitreverse' "$ll"; then
    echo "the core still has llvm.bitreverse (miniz_oxide, part of the backtrace symbolizer)" >&2
    return 1
  fi
  echo "core checks: $lines instruction lines (< $max), $ir IR lines (< $max_ir), no llvm.bitreverse"
}

# ---------------------------------------------------------------------------
# LLVM 16 part. Runs with <repo> <work> <out>; the work dir holds core.bc,
# ll/*.ll and abi.txt.
postprocess() {
  local repo="$1" w="$2" out="$3" m
  # 1. D1 condition 6: the debug info of the precompiled std does not survive
  # llvm-link-16 + KLEE.
  opt-16 --strip-debug "$w/core.bc" -o "$w/c0.bc"
  llvm-dis-16 "$w/c0.bc" -o "$w/c0.ll"
  # 2-3. std's backtrace symbolizer stubbed (self-tests: scripts/test-klee-postprocess.sh)
  # and rust_eh_personality stubbed, so the unwinder (libgcc_s) is not needed.
  python3 -I "$repo/scripts/klee-stub-symbolizer.py" "$w/c0.ll" "$w/c1.ll" >/dev/null
  python3 -I "$repo/scripts/runtime-ir/stub_personality.py" "$w/c1.ll" "$w/c2.ll" >/dev/null
  llvm-as-16 "$w/c2.ll" -o "$w/c2.bc"
  opt-16 -passes=globaldce "$w/c2.bc" -o "$w/c3.bc"
  llvm-dis-16 "$w/c3.bc" -o "$w/c3.ll"
  # 4. Vector intrinsics KLEE 3.1 cannot execute, lowered to scalar code.
  python3 -I "$repo/scripts/klee-lower-intrinsics.py" "$w/c3.ll" "$w/c4.ll" >/dev/null
  python3 -I "$repo/scripts/klee-stub-symbolizer.py" --check "$w/c4.ll" >/dev/null \
    || { echo "the backtrace symbolizer is still in the core" >&2; return 1; }
  # 6. One target triple for every module (clang-16's), and no DWARF flag:
  # the frontend does not redirect llvm-link's stderr.
  sed -i 's/^target triple = "x86_64-unknown-linux-gnu"/target triple = "x86_64-pc-linux-gnu"/' "$w/c4.ll"
  grep -q '^target triple = "x86_64-pc-linux-gnu"' "$w/c4.ll" \
    || { echo "the core has another target triple" >&2; return 1; }
  python3 -I "$repo/scripts/runtime-ir/drop_dwarf_flag.py" "$w/c4.ll" "$w/c4.ll"
  if grep -q '"Dwarf Version"' "$w/c4.ll"; then echo "the core keeps the Dwarf Version flag" >&2; return 1; fi
  llvm-as-16 "$w/c4.ll" -o "$w/c5.bc"

  # The 20 IR modules (and the glue) assembled; what they define.
  mkdir -p "$w/irbc"
  # Assembled from inside ll/, so source_filename is "<module>.ll" and not
  # the work directory, which differs from build to build.
  for f in "$w"/ll/*.ll; do
    m="$(basename "$f" .ll)"
    (cd "$w/ll" && llvm-as-16 "$m.ll" -o "$w/irbc/$m.bc")
  done
  : > "$w/ir-defined.txt"
  for f in "$w"/irbc/*.bc; do
    [ "$(basename "$f")" = Map2CheckFunctions-glue.bc ] && continue
    llvm-nm-16 --defined-only --extern-only "$f" 2>/dev/null | awk 'NF==3 {print $3}' >> "$w/ir-defined.txt"
  done
  sort -u -o "$w/ir-defined.txt" "$w/ir-defined.txt"

  # 5. Only the C ABI the core owns and the __m2c_* entry points stay
  # external; std/core symbols (rust_panic, _ZN4core3fmt...) and the names a
  # mode or generator module defines become internal (since Task 2.10 the
  # staticlib exports none of the latter; scripts/check-export-set.sh).
  { sort -u "$w/abi.txt" | comm -23 - "$w/ir-defined.txt"
    llvm-nm-16 --defined-only "$w/c5.bc" | awk 'NF==3 {print $3}' | grep -E '^__m2c_' || true
  } > "$w/public.txt"
  opt-16 -passes=internalize,globaldce -internalize-public-api-file="$w/public.txt" "$w/c5.bc" -o "$w/core-s.bc"

  llvm-nm-16 --defined-only --extern-only "$w/core-s.bc" | awk 'NF==3 {print $3}' | sort -u > "$w/core-defined.txt"
  local clash
  clash="$(comm -12 "$w/core-defined.txt" "$w/ir-defined.txt" | tr '\n' ' ')"
  [ -z "$clash" ] || { echo "the core defines names of an IR module: $clash" >&2; return 1; }
  clash="$(llvm-nm-16 --undefined-only "$w/core-s.bc" | awk '{print $NF}' | grep -E '^(klee_|__afl_)' | tr '\n' ' ' || true)"
  [ -z "$clash" ] || { echo "the core references generator intrinsics: $clash" >&2; return 1; }
  # The AFL++ generator's longjmp (nondet_cancel) must never cross a Rust
  # frame (D7 item 5): the Rust part references neither the jump nor any IR
  # function that reaches it, nor the program (test_gen_ll.py
  # test_only_the_assume_entry_points_reach_longjmp checks the IR side).
  clash="$(llvm-nm-16 --undefined-only "$w/core-s.bc" | awk '{print $NF}' \
    | grep -xE '(_|__|sig)?longjmp|__longjmp_chk|_?setjmp|sigsetjmp|__sigsetjmp|nondet_assume|nondet_cancel|map2check_(crab_)?assume(_loop)?|__map2check_main__|main' \
    | tr '\n' ' ' || true)"
  [ -z "$clash" ] || { echo "the Rust core references a longjmp path or the program: $clash" >&2; return 1; }

  llvm-link-16 "$w/core-s.bc" "$w/irbc/Map2CheckFunctions-glue.bc" -o "$out/Map2CheckFunctions.bc"
  llvm-dis-16 "$out/Map2CheckFunctions.bc" -o "$w/final.ll"
  # Every function left is reachable from the exported API: no freeze.
  check_core "$w/final.ll" || return 1
  python3 -I "$repo/scripts/runtime-ir/check_no_freeze.py" "$w/final.ll" >/dev/null \
    || { echo "the core has a freeze KLEE 3.1 cannot execute (fix the Rust source)" >&2; return 1; }
  for f in "$w"/irbc/*.bc; do
    m="$(basename "$f" .bc)"
    [ "$m" = Map2CheckFunctions-glue ] && continue
    cp "$f" "$out/$m.bc"
  done
  llvm-nm-16 --defined-only --extern-only "$out/Map2CheckFunctions.bc" | awk 'NF==3 {print $3}' | sort -u > "$w/core-final.txt"
  local missing=""
  for f in "$out"/*.bc; do
    [ "$(basename "$f")" = Map2CheckFunctions.bc ] && continue
    while read -r s; do
      grep -qx "$s" "$w/core-final.txt" || missing+=" $(basename "$f" .bc):$s"
    done < <(llvm-nm-16 --undefined-only "$f" 2>/dev/null | awk '{print $NF}' | grep -E '^__m2c_rt_' || true)
  done
  [ -z "$missing" ] || { echo "core entry points the IR calls but the core does not define:$missing" >&2; return 1; }
  local n=0
  for m in $MODULES; do
    llvm-dis-16 "$out/$m.bc" -o /dev/null
    n=$((n + 1))
  done
  [ "$(ls "$out"/*.bc | wc -l)" = 21 ] || { echo "expected 21 modules in $out" >&2; return 1; }
  echo "build-runtime-bc: $n modules readable by llvm-dis-16"
}

if [ "${1:-}" = --check-core ]; then
  [ $# -eq 2 ] || { echo "usage: $0 --check-core <final.ll>" >&2; exit 2; }
  check_core "$2"
  exit $?
fi

if [ "${1:-}" = --postprocess ]; then
  shift
  MODULES="$MODULES" postprocess "$@"
  exit $?
fi

[ $# -eq 1 ] || { echo "usage: $0 <out-dir>" >&2; exit 2; }
mkdir -p "$1"
OUT="$(cd "$1" && pwd)"
# <out-dir> holds the 21 modules and nothing else: an earlier output is
# replaced, any other file is refused rather than deleted.
others="$(cd "$OUT" && ls -A | grep -vxF -f <(for m in $MODULES; do echo "$m.bc"; done; echo .work) || true)"
[ -z "$others" ] || die "$OUT has files that are not runtime modules: $(echo $others)"
rm -f "$OUT"/*.bc
TOOLCHAIN="${KLEE_RUSTC_TOOLCHAIN:-1.72.1}"
TARGET_DIR="${CARGO_TARGET_DIR:-$ROOT/target/dropin-core}"
commit="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION")"
IMAGE="${IMAGE:-map2check-dev:develop-${commit:0:12}}"

llvm_version="$(RUSTUP_TOOLCHAIN="$TOOLCHAIN" rustc -vV | sed -n 's/^LLVM version: //p')"
case "$llvm_version" in 16.*) ;; *) die "rustc $TOOLCHAIN uses LLVM '$llvm_version', not 16" ;; esac

work="$OUT/.work"
rm -rf "$work"; mkdir -p "$work/ll"
deps="$TARGET_DIR/release/deps"
# Always re-emit the crate's bitcode: cargo does not rebuild a crate it
# considers up to date, and a stale module would be picked up.
RUSTUP_TOOLCHAIN="$TOOLCHAIN" CARGO_TARGET_DIR="$TARGET_DIR" \
  cargo clean --release -p map2check-klee-runtime --manifest-path "$ROOT/klee/Cargo.toml" >/dev/null 2>&1 \
  || die "cargo clean failed"
[ -d "$deps" ] && find "$deps" -maxdepth 1 -name 'map2check-*.bc' -delete
RUSTUP_TOOLCHAIN="$TOOLCHAIN" CARGO_TARGET_DIR="$TARGET_DIR" \
  cargo rustc --quiet --locked --release --features dropin,wasm --lib \
  --manifest-path "$ROOT/klee/Cargo.toml" -- --emit=llvm-bc || die "cargo rustc failed"
mapfile -t bcs < <(find "$deps" -maxdepth 1 -name 'map2check-*.bc')
[ "${#bcs[@]}" -eq 1 ] || die "expected one map2check-*.bc in $deps, found ${#bcs[@]}"
cp "${bcs[0]}" "$work/core.bc"

python3 -I "$ROOT/scripts/runtime-ir/gen_ll.py" "$ROOT/docs/runtime-abi/inventory.tsv" "$work/ll"
tail -n +2 "$ROOT/docs/runtime-abi/inventory.tsv" | cut -f1 > "$work/abi.txt"

host_llvm=1
for t in opt-16 llvm-as-16 llvm-dis-16 llvm-link-16 llvm-nm-16; do
  command -v "$t" >/dev/null 2>&1 || host_llvm=0
done
if [ "$host_llvm" = 1 ]; then
  postprocess "$ROOT" "$work" "$OUT" || die "post-processing failed"
else
  command -v docker >/dev/null 2>&1 || die "no LLVM 16 tools on PATH and no docker"
  docker image inspect "$IMAGE" >/dev/null 2>&1 || die "no LLVM 16 tools on PATH and no image $IMAGE"
  docker run --rm --network none --user "$(id -u):$(id -g)" \
    -v "$ROOT:/repo:ro" -v "$OUT:/out" "$IMAGE" \
    /repo/scripts/build-runtime-bc.sh --postprocess /repo /out/.work /out \
    || die "post-processing failed (in $IMAGE)"
fi
rm -rf "$work"
[ "$(cd "$OUT" && ls -A | sort)" = "$(for m in $MODULES; do echo "$m.bc"; done | sort)" ] \
  || die "$OUT does not hold exactly the 21 modules"
echo "build-runtime-bc: wrote the 21 modules to $OUT (rustc $TOOLCHAIN, LLVM $llvm_version)"
