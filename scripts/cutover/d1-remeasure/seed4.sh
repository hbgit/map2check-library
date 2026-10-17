#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# Informational: prog42 with CmpLog and a 4-byte seed "AAAA", stopping at the first crash.
cd /bench/build-v1
export AFL_NO_UI=1 AFL_NO_AFFINITY=1 AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_CRASHING_SEEDS_AS_NEW_CRASH=1 AFL_BENCH_UNTIL_CRASH=1
mkdir seed4 && printf AAAA > seed4/seed
for rep in 1 2 3 4 5; do for v in b1 b2; do
  out=runs4/$v-$rep; mkdir -p runs4
  afl-fuzz -i seed4 -o $out -V 30 -c ./$v-prog42.cmplog.afl -- ./$v-prog42.afl > $out.log 2>&1
  printf "%s\t%s\t%s\n" $rep $v "$(ls $out/default/crashes | grep '^id:' | head -1)"
done; done
