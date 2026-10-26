#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# D7 spike (Task 1.1): AFL++ throughput and time to first crash for one
# installation. The frontend itself builds the binaries (map2check --debug
# --nondet-generator afl: afl-clang-fast -g -O2 on <hash>-result.bc, plus the
# AFL_LLVM_CMPLOG=1 companion); then afl-fuzz runs REPS times, in sequence,
# with the frontend's environment and flags (Caller::executeAnalysis):
#   AFL_NO_UI=1 AFL_NO_AFFINITY=1 AFL_SKIP_CPUFREQ=1
#   AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_CRASHING_SEEDS_AS_NEW_CRASH=1
#   AFL_BENCH_UNTIL_CRASH=1 afl-fuzz -i <seed "A"> -o afl-out -c <cmplog> -- <fuzzed>
# under `timeout SECS`.
#
# Usage: measure-afl.sh <install-dir> <label> <prog.c> <secs> <reps> [map2check flags]
# Output rows: label prog rep execs_per_sec execs_done run_time_s saved_crashes first_crash_ms first_crash_execs crash_op
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
INSTALL="$(cd "$1" && pwd)"
label="$2"; prog="$(cd "$(dirname "$3")" && pwd)/$(basename "$3")"; secs="$4"; reps="$5"; shift 5
flags="${*:---target-function --target-function-name reach_error}"
commit="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION")"
IMAGE="${IMAGE:-map2check-dev:develop-${commit:0:12}}"
name="$(basename "$prog" .c)"
work="$ROOT/target/map2check-it/d7/afl-$label-$name"
rm -rf "$work"; mkdir -p "$work"
cp "$prog" "$work/"
docker run --rm --network none --user "$(id -u):$(id -g)" -e HOME=/work \
  -v "$INSTALL:/opt/m2c:ro" -v "$work:/work" -w /work "$IMAGE" bash -c '
  label="$1"; name="$2"; secs="$3"; reps="$4"; flags="$5"
  /opt/m2c/bin/map2check --debug --nondet-generator afl --timeout 20 $flags "$name.c" > build.log 2>&1 || true
  d=$(ls -d ./*.map2check | grep -v "\.build$" | head -1)
  fz=$(ls "$d"/*-fuzzed.out | grep -v witness | head -1); cl=$(ls "$d"/*-cmplog.out | head -1)
  [ -x "$fz" ] && [ -x "$cl" ] || { echo "no AFL++ binaries for $label $name" >&2; exit 1; }
  for r in $(seq 1 "$reps"); do
    rm -rf afl-in afl-out; mkdir afl-in; printf A > afl-in/seed
    AFL_NO_UI=1 AFL_NO_AFFINITY=1 AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
      AFL_CRASHING_SEEDS_AS_NEW_CRASH=1 AFL_BENCH_UNTIL_CRASH=1 \
      timeout -k 5 "$secs" afl-fuzz -i afl-in -o afl-out -c "$cl" -- "$fz" > "fuzz-$r.log" 2>&1 || true
    st=afl-out/default/fuzzer_stats
    g() { sed -n "s/^$1 *: //p" "$st" | head -1; }
    c=$(ls afl-out/default/crashes 2>/dev/null | grep "^id:" | sort | head -1)
    ct=$(echo "$c" | sed -n "s/.*,time:\([0-9]*\).*/\1/p"); ce=$(echo "$c" | sed -n "s/.*,execs:\([0-9]*\).*/\1/p")
    op=$(echo "$c" | sed -n "s/.*,op:\([a-z0-9]*\).*/\1/p")
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$label" "$name" "$r" "$(g execs_per_sec)" "$(g execs_done)" "$(g run_time)" "$(g saved_crashes)" "${ct:--}" "${ce:--}" "${op:--}"
  done
' run "$label" "$name" "$secs" "$reps" "$flags"
