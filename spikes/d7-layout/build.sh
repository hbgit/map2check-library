#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# D7 spike (Task 1.1): builds the 21 runtime modules for one layout strategy.
#
# Usage: spikes/d7-layout/build.sh <strategy> <out-dir>
#   fwd     A refined: Rust core = Map2CheckFunctions.bc; the other 20 are IR
#           forwarders/stubs; generator IR holds the KLEE/AFL++ intrinsics,
#           main and setjmp/longjmp.
#   alit    A as written in the plan: generator logic in the core, klee_* and
#           the AFL reject hook extern_weak, selection by strong/weak global.
#   b       B: generator modules are Rust no_std crates (AFL: + IR main with
#           setjmp/longjmp).
#   b-loop  B with the AFL++ persistent loop in Rust and no longjmp (a failed
#           assume ends the process).
#
# Rust: rustc 1.72.1 (LLVM 16) on the host, fat LTO, --emit=llvm-bc (D1, A').
# LLVM 16 tools: inside the Map2Check image (IMAGE).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
[ $# -eq 2 ] || { echo "uso: $0 <fwd|alit|b|b-loop> <out-dir>" >&2; exit 2; }
strategy="$1"
mkdir -p "$2"
OUT="$(cd "$2" && pwd)"
commit="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION")"
IMAGE="${IMAGE:-map2check-dev:develop-${commit:0:12}}"
TOOLCHAIN="${D7_RUSTC:-1.72.1}"

work="$OUT/.work"
rm -rf "$work"
mkdir -p "$work/ll"

emit() { # <crate-dir> <dest.bc> [cargo args...]
  local dir="$1" dest="$2"
  shift 2
  # A fresh crate build every time: cargo does not re-emit the .bc of a
  # crate it considers up to date.
  (cd "$dir" && RUSTUP_TOOLCHAIN="$TOOLCHAIN" cargo clean --quiet --release)
  (cd "$dir" && RUSTUP_TOOLCHAIN="$TOOLCHAIN" cargo rustc --quiet --release --lib "$@" -- --emit=llvm-bc)
  cp "$dir"/target/release/deps/*.bc "$dest"
}

case "$strategy" in
  fwd | b | b-loop) emit "$HERE/core" "$work/core.bc" ;;
  alit) emit "$HERE/core" "$work/core.bc" --features a_literal ;;
  *) echo "estratégia desconhecida: $strategy" >&2; exit 2 ;;
esac
case "$strategy" in
  b | b-loop)
    for g in none klee afl afl-loop; do emit "$HERE/gen-b/$g" "$work/gen-$g.bc"; done ;;
esac

ll_strategy="$strategy"
[ "$strategy" = b-loop ] && ll_strategy=b
tail -n +2 "$ROOT/docs/runtime-abi/inventory.tsv" | cut -f1 > "$work/abi.txt"
python3 -I "$HERE/scripts/gen_ll.py" "$ll_strategy" "$ROOT/docs/runtime-abi/inventory.tsv" "$work/ll"

docker run --rm --network none --user "$(id -u):$(id -g)" -v "$OUT:/out" \
  -v "$ROOT/scripts:/repo/scripts:ro" -v "$HERE:/spike:ro" "$IMAGE" bash -euc '
  s="$1"; w=/out/.work
  # D1 condition 6: the debug info of the precompiled std does not survive
  # llvm-link-16 + KLEE.
  opt-16 --strip-debug "$w/core.bc" -o "$w/core-s.bc"
  # The post-processing of scripts/build-klee-runtime.sh (std backtrace
  # symbolizer stubbed, vector intrinsics lowered for KLEE 3.1), plus
  # rust_eh_personality stubbed so the unwinder (libgcc_s) is not needed.
  llvm-dis-16 "$w/core-s.bc" -o "$w/c0.ll"
  python3 -I /repo/scripts/klee-stub-symbolizer.py "$w/c0.ll" "$w/c1.ll" >/dev/null
  python3 -I /spike/scripts/stub_personality.py "$w/c1.ll" "$w/c2.ll" >/dev/null
  llvm-as-16 "$w/c2.ll" -o "$w/c2.bc"
  opt-16 -passes=globaldce "$w/c2.bc" -o "$w/c3.bc"
  llvm-dis-16 "$w/c3.bc" -o "$w/c3.ll"
  python3 -I /repo/scripts/klee-lower-intrinsics.py "$w/c3.ll" "$w/c4.ll" >/dev/null
  llvm-as-16 "$w/c4.ll" -o "$w/c5.bc"
  # Only the C ABI (inventory.tsv) and the __m2c_rt_* entry points stay
  # external; std/core symbols (rust_panic, _ZN4core3fmt...) become internal,
  # so they cannot collide with the program or with another Rust module.
  keep() { # <in.bc> <out.bc>
    { cat /out/.work/abi.txt; llvm-nm-16 --defined-only "$1" | awk "{print \$3}" | grep -E "^(__m2c_|map2check_afl_)" || true; } > "$1.api"
    opt-16 -passes=internalize,globaldce -internalize-public-api-file="$1.api" "$1" -o "$2"
  }
  keep "$w/c5.bc" "$w/core-s.bc"
  if [ "$s" = alit ]; then
    llvm-dis-16 "$w/core-s.bc" -o "$w/core.ll"
    sed -i -e "s/^declare \(.*\)@klee_make_symbolic(/declare extern_weak \1@klee_make_symbolic(/" \
           -e "s/^declare \(.*\)@__m2c_afl_reject(/declare extern_weak \1@__m2c_afl_reject(/" \
           -e "s/^@__m2c_sel_generator = /@__m2c_sel_generator = weak /" "$w/core.ll"
    llvm-as-16 "$w/core.ll" -o "$w/core-s.bc"
  fi
  llvm-as-16 "$w/ll/Map2CheckFunctions-glue.ll" -o "$w/glue.bc"
  llvm-link-16 "$w/core-s.bc" "$w/glue.bc" -o /out/Map2CheckFunctions.bc
  for f in "$w"/ll/*.ll; do
    m="$(basename "$f" .ll)"
    case "$m" in Map2CheckFunctions-glue | b-afl-main) continue ;; esac
    llvm-as-16 "$f" -o "/out/$m.bc"
  done
  case "$s" in
    b | b-loop)
      opt-16 --strip-debug "$w/gen-none.bc" -o "$w/gn.bc"; keep "$w/gn.bc" /out/NonDetGeneratorNone.bc
      opt-16 --strip-debug "$w/gen-klee.bc" -o "$w/gk.bc"; keep "$w/gk.bc" /out/NonDetGeneratorKlee.bc
      if [ "$s" = b ]; then
        opt-16 --strip-debug "$w/gen-afl.bc" -o "$w/gen-afl-s.bc"
        llvm-as-16 "$w/ll/b-afl-main.ll" -o "$w/b-afl-main.bc"
        llvm-link-16 "$w/gen-afl-s.bc" "$w/b-afl-main.bc" -o "$w/ga.bc"
      else
        opt-16 --strip-debug "$w/gen-afl-loop.bc" -o "$w/ga.bc"
      fi
      keep "$w/ga.bc" /out/NonDetGeneratorAFL.bc ;;
  esac
  n=0
  for m in Map2CheckFunctions TrackBBLog NonDetLog PropertyGenerator ContainerRealloc ContainerBTree BTree AnalysisModeMemtrack AnalysisModeMemcleanup AnalysisModeOverflow AnalysisModeAssert AnalysisModeNone AllocationLog ListLog HeapLog NonDetGeneratorNone NonDetGeneratorKlee NonDetGeneratorAFL WasmRuntimeStubs WitnessGeneration WitnessGenerationNone; do
    llvm-dis-16 "/out/$m.bc" -o /dev/null
    n=$((n + 1))
  done
  echo "build: $s -> $n modules readable by llvm-dis-16"
' build "$strategy"
rm -rf "$work"
