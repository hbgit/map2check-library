#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 2.5b D1 re-measurement: sequential 30 s afl-fuzz campaigns, never two
# fuzzers at once. usage: bench.sh <build-dir> <reps>
# Same environment as the frontend (caller.cpp:919-925) minus
# AFL_BENCH_UNTIL_CRASH (the campaign must run its whole 30 s for exec/s);
# seed "A" as the frontend's placeholder (caller.cpp:904-907).
B=/bench/$1; REPS=$2
export AFL_NO_UI=1 AFL_NO_AFFINITY=1 AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_CRASHING_SEEDS_AS_NEW_CRASH=1
cd $B
mkdir -p seed && printf A > seed/seed
mkdir -p runs
echo -e "rep\tvariant\tprog\tcmplog\texecs_per_sec\texecs_done\tsaved_crashes\tstability\tfirst_crash"
for rep in $(seq 1 $REPS); do
  for prog in prog42 assume; do
    for cmp in no yes; do
      for v in b1 b2; do
        out=runs/$v-$prog-$cmp-$rep
        C=""; [ $cmp = yes ] && C="-c ./$v-$prog.cmplog.afl"
        afl-fuzz -i seed -o $out -V 30 $C -- ./$v-$prog.afl > $out.log 2>&1
        s=$out/default/fuzzer_stats
        first=$(ls $out/default/crashes 2>/dev/null | grep '^id:' | sort | head -1)
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" $rep $v $prog $cmp \
          "$(awk -F': ' '/^execs_per_sec/{print $2}' $s)" \
          "$(awk -F': ' '/^execs_done/{print $2}' $s)" \
          "$(awk -F': ' '/^saved_crashes/{print $2}' $s)" \
          "$(awk -F': ' '/^stability/{print $2}' $s)" "${first:--}"
      done
    done
  done
done
