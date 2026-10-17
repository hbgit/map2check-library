#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# Baseline: the library before Task 2.5b (0d5b1f6, a git worktree mounted
# at /old), B1 prog42 with CmpLog, 5 sequential 30 s campaigns.
set -euo pipefail
export CARGO_TARGET_DIR=/bench/target-old RUSTUP_TOOLCHAIN=1.82.0
cd /old && cargo build --profile runtime --features libfuzzer 2>&1 | tail -1
L=$CARGO_TARGET_DIR/runtime/libmap2check.a
mkdir /bench/build-old && cd /bench/build-old
clang-16 -emit-llvm -c -Dmain=__map2check_main__ /bench/prog42.c -o prog42_m.bc
afl-clang-fast -g -O2 -fsanitize=fuzzer prog42_m.bc $L -ldl -lpthread -lm -o b0-prog42.afl 2>/dev/null
AFL_LLVM_CMPLOG=1 afl-clang-fast -g -O2 -fsanitize=fuzzer prog42_m.bc $L -ldl -lpthread -lm -o b0-prog42.cmplog.afl 2>/dev/null
export AFL_NO_UI=1 AFL_NO_AFFINITY=1 AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_CRASHING_SEEDS_AS_NEW_CRASH=1
mkdir seed && printf A > seed/seed
for rep in 1 2 3 4 5; do
  out=out-$rep
  afl-fuzz -i seed -o $out -V 30 -c ./b0-prog42.cmplog.afl -- ./b0-prog42.afl > $out.log 2>&1
  printf "%s\tb0\tprog42\tyes\t%s\t%s\n" $rep "$(awk -F': ' '/^execs_per_sec/{print $2}' $out/default/fuzzer_stats)" "$(ls $out/default/crashes | grep '^id:' | head -1)"
done
