#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# Builds B1 (Rust lib + AFL++ libFuzzer driver) and B2 (develop's C runtime,
# NonDetGeneratorAFL.c) for the Task 2.5b measurements, plus the
# differential type programs. Mounts: /src repo (rw: build.rs writes the
# header), /runtime develop's modules/backend/library (ro), /bench this dir.
set -euo pipefail
export CARGO_TARGET_DIR=/bench/target-docker RUSTUP_TOOLCHAIN=1.82.0
cd /src && cargo build --profile runtime --features libfuzzer 2>&1 | tail -1
L=$CARGO_TARGET_DIR/runtime/libmap2check.a
B=/bench/build-$1
mkdir "$B" && cd "$B"
# develop's runtime as bitcode, as modules/backend/library/lib/CMakeLists.txt
# compiles it (clang -c -emit-llvm), the reachability link of caller.cpp
for f in Map2CheckFunctions TrackBBLog NonDetLog PropertyGenerator ContainerRealloc \
  AnalysisModeNone NonDetGeneratorAFL WitnessGenerationNone; do
  clang-16 -c -emit-llvm -I/runtime/header /runtime/lib/$f.c -o $f.bc 2>/dev/null
done
RT="Map2CheckFunctions.bc TrackBBLog.bc NonDetLog.bc PropertyGenerator.bc ContainerRealloc.bc AnalysisModeNone.bc NonDetGeneratorAFL.bc WitnessGenerationNone.bc"
for p in prog42 assume; do
  # B1: main renamed by the pass, linked with the native staticlib
  clang-16 -emit-llvm -c -Dmain=__map2check_main__ /bench/$p.c -o ${p}_m.bc
  afl-clang-fast -g -O2 -fsanitize=fuzzer ${p}_m.bc $L -ldl -lpthread -lm -o b1-$p.afl 2>/dev/null
  AFL_LLVM_CMPLOG=1 afl-clang-fast -g -O2 -fsanitize=fuzzer ${p}_m.bc $L -ldl -lpthread -lm -o b1-$p.cmplog.afl 2>/dev/null
  # B2: as the passes leave it for the C runtime
  clang-16 -emit-llvm -c /bench/${p}_c.c -o ${p}_c.bc
  llvm-link-16 ${p}_c.bc $RT -o $p-result.bc
  afl-clang-fast -g -O2 $p-result.bc -o b2-$p.afl 2>/dev/null
  AFL_LLVM_CMPLOG=1 afl-clang-fast -g -O2 $p-result.bc -o b2-$p.cmplog.afl 2>/dev/null
done
# differential type programs
clang-16 -O2 -I/src/include /bench/types_b1.c $L -ldl -lpthread -lm -o types_b1
clang-16 -emit-llvm -c /bench/types_b2.c -o types_b2.bc
llvm-link-16 types_b2.bc $RT -o types-result.bc
afl-clang-fast -O2 types-result.bc -o types_b2 2>/dev/null
ls -la b1-* b2-* types_b*
nm b1-prog42.afl | grep -cE " T (LLVMFuzzerTestOneInput|__map2check_main__|__afl_persistent_loop)$"
strings b1-prog42.afl | grep -c SIG_AFL_PERSISTENT
