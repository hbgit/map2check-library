#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# clang-16 / afl-clang-fast (the pipeline's compilers): attributes of the
# harness's __map2check_main__ and the -O2 harness run per flag set.
export CARGO_TARGET_DIR=/bench/target-docker RUSTUP_TOOLCHAIN=1.82.0
cd /src && cargo build --release --all-features 2>&1 | tail -1
L=$CARGO_TARGET_DIR/release/libmap2check.a
mkdir -p /bench/flags16 && cd /bench/flags16
for cc in clang-16 afl-clang-fast; do
  for fl in "" "-fexceptions" "-funwind-tables" "-fno-asynchronous-unwind-tables -fno-unwind-tables" "-fexceptions -fno-asynchronous-unwind-tables -fno-unwind-tables"; do
    clang-16 -O2 -S -emit-llvm $fl /src/tests/ffi_harness.c -o h.ll 2>/dev/null
    a=$(grep -E "^define .*@__map2check_main__" h.ll | grep -o '#[0-9]*' | tail -1)
    attrs=$(grep "^attributes $a " h.ll | grep -oE 'nounwind|uwtable(=[a-z]+)?' | tr '\n' ' ')
    $cc -O2 $fl /src/tests/ffi_harness.c $L -ldl -lpthread -lm -o h 2>/dev/null || { echo "$cc [$fl] build failed"; continue; }
    ./h >/dev/null 2>h.err; rc=$?
    echo "$cc [${fl:-default}] main attrs: ${attrs}| rc=$rc $(grep -m1 -E 'failed to initiate|ended before' h.err)"
  done
done
