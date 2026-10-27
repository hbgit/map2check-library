#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 2.8: afl-fuzz throughput and time to the first crash of the drop-in
# AFL++ generator against the C runtime (criterion: median execs/s of the
# drop-in >= 90% of the C's on the smoke program). Recipe of the D7 spike
# (spikes/d7-layout/measure-afl.sh), with the runs interleaved C, Rust, C,
# Rust, ... so that drift of the shared host hits both sides alike.
#
# The installed C Map2Check (target/map2check-it/c) instruments each program
# once (--debug --nondet-generator afl, target mode reach_error: the same
# work per execution on both runtimes); its <hash>-output.bc is linked with
# llvm-link-16 in the Caller::linkLLVM order with the C modules and with the
# drop-in ones, and each side gets the frontend's two binaries
# (Caller::applyNonDetGenerator):
#   afl-clang-fast  -g -O2  -o fuzzed.out result.bc -lm
#   AFL_LLVM_CMPLOG=1 afl-clang-fast  -g -O2  -o cmplog.out result.bc -lm
# and runs afl-fuzz as Caller::executeAnalysis does:
#   AFL_NO_UI=1 AFL_NO_AFFINITY=1 AFL_SKIP_CPUFREQ=1
#   AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_CRASHING_SEEDS_AS_NEW_CRASH=1
#   AFL_BENCH_UNTIL_CRASH=1 timeout -k 5 <secs> afl-fuzz -i <seed "A"> -o afl-out
#   -c ./cmplog.out -- ./fuzzed.out
# (test-afl-generator.sh checks those caller.cpp fragments.)
#
#   link-smoke  scripts/it/smoke/link-smoke.c, safe: execs/s over SECS;
#   assume      the D7 spike's progs/assume.c, inlined below (rejects almost
#               every input: the longjmp path): execs/s over SECS;
#   magic       tests/runtime-ir/afl/magic.c: ms and execs to the first crash
#               (CmpLog solves the guard), capped at CRASH_SECS.
#
# Usage: measure-afl-generator.sh [<drop-in-lib-dir>]
#   default: builds target/runtime-ir/dropin-lib with build-test-runtime-bc.sh
# Environment: REPS (5), SECS (20), CRASH_SECS (30).
# Output: target/runtime-ir/afl-perf/runs.tsv and summary.txt; exits 1 when
# the median ratio on link-smoke is below 0.90.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
commit="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION")"
IMAGE="${IMAGE:-map2check-dev:develop-${commit:0:12}}"
M2C_INSTALL="${M2C_INSTALL:-$ROOT/target/map2check-it/c}"
REPS="${REPS:-5}"; SECS="${SECS:-20}"; CRASH_SECS="${CRASH_SECS:-30}"

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "SKIP: docker unavailable" >&2; exit 77
fi
docker image inspect "$IMAGE" >/dev/null 2>&1 || { echo "SKIP: image $IMAGE missing" >&2; exit 77; }
[ -x "$M2C_INSTALL/bin/map2check" ] || { echo "SKIP: $M2C_INSTALL/bin/map2check missing" >&2; exit 77; }
M2C_INSTALL="$(cd "$M2C_INSTALL" && pwd)"
if [ $# -ge 1 ]; then
  LIB="$(cd "$1" && pwd)"
else
  LIB="$ROOT/target/runtime-ir/dropin-lib"
  "$HERE/build-test-runtime-bc.sh" "$LIB"
fi

W="$ROOT/target/runtime-ir/afl-perf"
rm -rf "$W"; mkdir -p "$W/src"
cp "$ROOT/scripts/it/smoke/link-smoke.c" "$W/src/link-smoke.c"
cp "$ROOT/tests/runtime-ir/afl/magic.c" "$W/src/magic.c"
cat > "$W/src/assume.c" <<'EOF'
/* D7 spike progs/assume.c: safe, most inputs rejected by __VERIFIER_assume. */
#include <stdlib.h>
extern void __assert_fail(const char *, const char *, unsigned int, const char *);
void reach_error(void) { __assert_fail("0", "assume.c", 6, "reach_error"); }
extern int __VERIFIER_nondet_int(void);
extern void __VERIFIER_assume(int);
int main(void) {
  int n = __VERIFIER_nondet_int();
  __VERIFIER_assume(n >= 0 && n <= 8);
  int *a = malloc(sizeof(int) * 9);
  if (a == NULL)
    return 0;
  int s = 0;
  for (int i = 0; i <= n; i++) {
    a[i] = i;
    s += a[i];
  }
  if (s != n * (n + 1) / 2)
    reach_error();
  free(a);
  return 0;
}
EOF

cname="m2c-t28-perf-$$"
cleanup() { docker rm -f "$cname" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run --rm --name "$cname" --network none --user "$(id -u):$(id -g)" -e HOME=/work \
  -e MAP2CHECK_PATH=/opt/m2c \
  -v "$M2C_INSTALL:/opt/m2c:ro" -v "$LIB:/rs:ro" -v "$W:/work" -w /work "$IMAGE" bash -c '
set -uo pipefail
reps="$1"; secs="$2"; crash_secs="$3"
for p in link-smoke assume magic; do
  mkdir -p "$p/inst"; cp "src/$p.c" "$p/inst/"
  ( cd "$p/inst" && /opt/m2c/bin/map2check --debug --nondet-generator afl --timeout 10 \
      --target-function --target-function-name reach_error "$p.c" > m2c.log 2>&1 )
  cp "$p"/inst/*.map2check/*.map2check-output.bc "$p/output.bc" || { echo "$p: no output.bc" >&2; exit 1; }
  for side in c rs; do
    case "$side" in c) L=/opt/m2c/lib ;; rs) L=/rs ;; esac
    d="$p/$side"; mkdir -p "$d"
    llvm-link-16 "$p/output.bc" $L/Map2CheckFunctions.bc $L/TrackBBLog.bc $L/NonDetLog.bc \
      $L/PropertyGenerator.bc $L/ContainerRealloc.bc $L/AnalysisModeNone.bc $L/NonDetGeneratorAFL.bc \
      $L/WitnessGenerationNone.bc -o "$d/result.bc" || exit 1
    ( cd "$d" && afl-clang-fast  -g -O2  -o fuzzed.out result.bc -lm > afl-build.log 2>&1 \
      && AFL_LLVM_CMPLOG=1 afl-clang-fast  -g -O2  -o cmplog.out result.bc -lm >> afl-build.log 2>&1 ) \
      || { echo "$d: afl-clang-fast failed" >&2; exit 1; }
  done
done
run() { # <prog> <side> <rep> <secs>
  local d="$1/$2" st c ct ce op
  ( cd "$d" && rm -rf afl-in afl-out && mkdir afl-in && printf A > afl-in/seed \
    && AFL_NO_UI=1 AFL_NO_AFFINITY=1 AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
       AFL_CRASHING_SEEDS_AS_NEW_CRASH=1 AFL_BENCH_UNTIL_CRASH=1 \
       timeout -k 5 "$4" afl-fuzz -i afl-in -o afl-out -c ./cmplog.out -- ./fuzzed.out > "fuzz-$3.log" 2>&1 )
  st="$d/afl-out/default/fuzzer_stats"
  g() { sed -n "s/^$1 *: //p" "$st" 2>/dev/null | head -1; }
  c="$(ls "$d/afl-out/default/crashes" 2>/dev/null | grep "^id:" | sort | head -1)"
  ct="$(echo "$c" | sed -n "s/.*,time:\([0-9]*\).*/\1/p")"; ce="$(echo "$c" | sed -n "s/.*,execs:\([0-9]*\).*/\1/p")"
  op="$(echo "$c" | sed -n "s/.*,op:\([a-z0-9]*\).*/\1/p")"
  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$1" "$2" "$3" "$(g execs_per_sec)" "$(g execs_done)" \
    "$(g run_time)" "$(g saved_crashes)" "${ct:--}" "${ce:--}" "${op:--}"
}
printf "prog\tside\trep\texecs_per_sec\texecs_done\trun_time_s\tsaved_crashes\tfirst_crash_ms\tfirst_crash_execs\tcrash_op\n" > runs.tsv
for p in link-smoke assume magic; do
  s="$secs"; [ "$p" = magic ] && s="$crash_secs"
  for r in $(seq 1 "$reps"); do
    for side in c rs; do run "$p" "$side" "$r" "$s" >> runs.tsv; done
  done
done
' perf "$REPS" "$SECS" "$CRASH_SECS" || { echo "FAIL: the runs did not complete" >&2; exit 1; }

python3 -I - "$W/runs.tsv" > "$W/summary.txt" <<'EOF'
import csv, statistics, sys
rows = list(csv.DictReader(open(sys.argv[1]), delimiter="\t"))
def col(p, s, k):
    return [float(r[k]) for r in rows if r["prog"] == p and r["side"] == s and r[k] not in ("", "-")]
out = []
for p in ("link-smoke", "assume"):
    c, r = col(p, "c", "execs_per_sec"), col(p, "rs", "execs_per_sec")
    mc, mr = statistics.median(c), statistics.median(r)
    out.append(f"{p}\texecs/s\tC median {mc:.0f} (range {min(c):.0f}-{max(c):.0f})\t"
               f"Rust median {mr:.0f} (range {min(r):.0f}-{max(r):.0f})\tratio {mr / mc:.3f}")
for k, label in (("first_crash_ms", "ms to 1st crash"), ("first_crash_execs", "execs to 1st crash")):
    c, r = col("magic", "c", k), col("magic", "rs", k)
    out.append(f"magic\t{label}\tC median {statistics.median(c) if c else float('nan'):.0f} "
               f"(range {min(c, default=0):.0f}-{max(c, default=0):.0f}, {len(c)} crashes)\t"
               f"Rust median {statistics.median(r) if r else float('nan'):.0f} "
               f"(range {min(r, default=0):.0f}-{max(r, default=0):.0f}, {len(r)} crashes)")
print("\n".join(out))
c, r = col("link-smoke", "c", "execs_per_sec"), col("link-smoke", "rs", "execs_per_sec")
ratio = statistics.median(r) / statistics.median(c)
print(f"criterion: link-smoke median ratio {ratio:.3f} {'>=' if ratio >= 0.9 else '<'} 0.90 -> {'PASS' if ratio >= 0.9 else 'FAIL'}")
EOF
column -t -s $'\t' "$W/runs.tsv"; echo; cat "$W/summary.txt"
grep -q -- "-> PASS" "$W/summary.txt"
