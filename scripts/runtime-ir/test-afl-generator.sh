#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 2.8: the AFL++ generator of the drop-in runtime (NonDetGeneratorAFL.bc
# and the Rust core) in the AFL++ 4.40c of the Map2Check image, against the C
# runtime on the same program.
#
#   afl_persistent_iterations_start_from_clean_state  tests/runtime-ir/afl/
#       persist-leak.c in the memcleanup and memtrack modes, several inputs
#       in ONE process. In C a violation that is reported aborts the process
#       (map2check_exit), so afl-fuzz runs the next input in a new child; the
#       state that can reach the next input of the same process is a
#       violation the input created but that was not reported yet when the
#       input ended: a leaked block when __VERIFIER_assume rejects the input.
#       The C forgets it (map2check_init -> analysis_init + nondet_init give
#       new containers, Map2CheckFunctions.c:29-40); so must the drop-in. Also
#       a clean input followed by a leaking one, a leaking one followed by a
#       clean one (the process ends at the first), and three clean inputs;
#   afl_assume_rejection_cancels_only_current_input   assume-reject.c
#       (target mode): a rejected input (longjmp back to the __AFL_LOOP of
#       main) followed by a clean or a violating input, which runs from its
#       own first byte; the rejected one prints nothing after the assume;
#   afl_short_input_is_completed_with_zeros           short-input.c (target
#       mode): "A" reads a = 0x41, b = c = 0 and reaches the error, also after
#       a longer input in the same process (no stale bytes); the empty input
#       reads zeros. gen-read.c calls the 21 generators, memory and pchar
#       directly (no pass) and prints their bytes: identical to the C on an
#       empty, a short, a long input and pchar lengths 0, 3 and > 4096 (cap);
#   afl_iterations_do_not_accumulate_records          SD-21: assume-reject.c
#       for 1 and for 50000 inputs in one process; the drop-in's peak RSS
#       grows by less than 2 MiB (the C's is reported, not asserted);
#   afl_writes_result_files_in_place_like_c           tests/runtime-ir/
#       write-mode.c (driver): under the AFL++ generator map2check_property is
#       truncated and written in place, as develop's fopen("w"), on both sides
#       (SD-20's temporary file + rename is KLEE-only in the drop-in: user
#       decision of 2026-10-27), seen through a descriptor held on the file;
#   afl_crash_replay_matches_c                        magic.c under the real
#       afl-fuzz with the frontend's environment and flags (CmpLog included)
#       until the first crash, on each side; each side's crashing input
#       replayed, standalone from stdin as the frontend does, through both
#       sides' -fuzzed.out: exit 134 and the same property files.
#   info: the replay through -witness-fuzzed.out (the frontend's
#       confirmation, caller.cpp:1656-1680) is printed, not asserted: the
#       drop-in core does not call the external generate_confirmation_file
#       yet (Task 3.1, plan Step 1), so map2check_checked_error differs.
#
# Programs: the installed C Map2Check (target/map2check-it/c) instruments
# each one (--debug --nondet-generator afl <mode>) and its <hash>-output.bc
# is kept (R2 of Task 1.1); drivers: clang-16 -O0 -emit-llvm. Each is linked
# with llvm-link-16 in the order Caller::linkLLVM logged for it (checked
# against the frontend's own log), with the C modules and with the drop-in
# ones. The in-process runs link the -result.bc natively with clang-16 -O2 and
# tests/runtime-ir/afl/fake_afl_rt.c, which feeds a list of inputs through
# the persistent loop (the real afl-compiler-rt runs one input per process
# outside afl-fuzz). The afl-fuzz runs build the three binaries as
# Caller::applyNonDetGenerator does (afl-clang-fast -g -O2 ... -lm; witness
# without -O2; AFL_LLVM_CMPLOG=1 for the companion) and run afl-fuzz as
# Caller::executeAnalysis does; the fragments of caller.cpp those commands
# come from are checked below, so a change there fails the test.
#
# Usage: test-afl-generator.sh [<drop-in-lib-dir>]
#   default: builds target/runtime-ir/dropin-lib with build-test-runtime-bc.sh
# Environment: AFL_CRASH_SECS (default 60), the cap of each afl-fuzz run.
# Exits 77 (skip) without docker, the image or the C install.
# Output: target/runtime-ir/afl-gen/ (results.tsv, one directory per case).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
commit="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION")"
IMAGE="${IMAGE:-map2check-dev:develop-${commit:0:12}}"
M2C_INSTALL="${M2C_INSTALL:-$ROOT/target/map2check-it/c}"
AFL_CRASH_SECS="${AFL_CRASH_SECS:-60}"
CALLER="$ROOT/vendor/map2check/modules/frontend/caller.cpp"

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "SKIP: docker unavailable" >&2; exit 77
fi
docker image inspect "$IMAGE" >/dev/null 2>&1 || { echo "SKIP: image $IMAGE missing" >&2; exit 77; }
[ -x "$M2C_INSTALL/bin/map2check" ] \
  || { echo "SKIP: $M2C_INSTALL/bin/map2check missing (scripts/it/build-map2check.sh)" >&2; exit 77; }
[ -f "$CALLER" ] || { echo "SKIP: $CALLER missing (scripts/fetch-map2check.sh)" >&2; exit 77; }
M2C_INSTALL="$(cd "$M2C_INSTALL" && pwd)"

# The frontend's AFL++ commands, as written in caller.cpp (the build
# commands are not logged). Each fragment must still be there.
drift=""
for frag in \
  'flags << "-O2 ";' \
  '<< "  -g " << Caller::postOptimizationFlags()' \
  '<< " -o " + programHash + "-fuzzed.out"' \
  '<< " -lm > afl-build.log 2>&1";' \
  '<< " -o " + programHash + "-witness-fuzzed.out"' \
  '<< " " + programHash + "-witness-result.bc -lm";' \
  'commandCmplog << "AFL_LLVM_CMPLOG=1 " << bound()' \
  '<< " " + programHash + "-result.bc -lm";' \
  'command << "AFL_NO_UI=1 AFL_NO_AFFINITY=1 AFL_SKIP_CPUFREQ=1"' \
  '<< " AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1"' \
  '<< " AFL_CRASHING_SEEDS_AS_NEW_CRASH=1"' \
  '<< " AFL_BENCH_UNTIL_CRASH=1 ";' \
  'seed << "A";' \
  'if (hasCmplog) command << " -c ./" << programHash << "-cmplog.out";' \
  '<< "-witness-fuzzed.out < '"'"'" << entry.path().string()'; do
  grep -qF -- "$frag" "$CALLER" || drift+=" [$frag]"
done
[ -z "$drift" ] || { echo "FAIL: caller.cpp no longer has the AFL++ command fragments:$drift" >&2; exit 1; }

if [ $# -ge 1 ]; then
  LIB="$(cd "$1" && pwd)"
else
  LIB="$ROOT/target/runtime-ir/dropin-lib"
  "$HERE/build-test-runtime-bc.sh" "$LIB"
fi

W="$ROOT/target/runtime-ir/afl-gen"
rm -rf "$W"; mkdir -p "$W/src"
cp "$ROOT"/tests/runtime-ir/afl/*.c "$ROOT/tests/runtime-ir/write-mode.c" "$W/src/"

# <program>:<mode>; mode "driver" = no instrumentation, linked in mode none.
PROGS="persist-leak.c:memcleanup persist-leak.c:memtrack assume-reject.c:none short-input.c:none
gen-read.c:driver write-mode.c:driver magic.c:none"

cname="m2c-t28-afl-$$"
cleanup() { docker rm -f "$cname" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run --rm --name "$cname" --network none --user "$(id -u):$(id -g)" -e HOME=/work \
  -e MAP2CHECK_PATH=/opt/m2c \
  -v "$M2C_INSTALL:/opt/m2c:ro" -v "$LIB:/rs:ro" -v "$W:/work" -w /work "$IMAGE" \
  bash -c '
set -uo pipefail
progs="$1"; crash_secs="$2"
flags() {
  case "$1" in
    memtrack) echo "--memtrack" ;; memcleanup) echo "--memcleanup-property" ;;
    none) echo "--target-function --target-function-name reach_error" ;;
  esac
}
modules() { # <lib> <mode>: Caller::linkLLVM, Array, afl (no witness module)
  local L="$1" m="$2" mods
  mods="$L/Map2CheckFunctions.bc $L/TrackBBLog.bc $L/NonDetLog.bc $L/PropertyGenerator.bc $L/ContainerRealloc.bc"
  case "$m" in
    memtrack) mods+=" $L/AnalysisModeMemtrack.bc $L/AllocationLog.bc $L/ListLog.bc $L/HeapLog.bc" ;;
    memcleanup) mods+=" $L/AnalysisModeMemcleanup.bc $L/AllocationLog.bc $L/ListLog.bc $L/HeapLog.bc" ;;
    none | driver) mods+=" $L/AnalysisModeNone.bc" ;;
  esac
  echo "$mods $L/NonDetGeneratorAFL.bc"
}
props() { # every map2check_property* file, one string
  local d="$1" f out=""
  for f in $(cd "$d" && ls map2check_property* 2>/dev/null | sort); do
    out+="[$f]$(tr "\n" "|" < "$d/$f")"
  done
  echo "${out:--}"
}
mkdir -p in
b() { printf "$2" > "in/$1"; } # <name> <printf bytes>
b clean "\x00\x00\x00\x00"; b cancelled-leak "\x01\x00\x00\x00"; b leak "\x02\x00\x00\x00"
b rejected "\x05\x00\x00\x00\x07\x00\x00\x00"; b safe "\x03\x00\x00\x00\x04\x00\x00\x00"
b violating "\x07\x00\x00\x00\x09\x00\x00\x00"
b A "A"; b empty ""; b long "AAAABBBBC"
b short3 "\x01\x02\x03"
head -c 200 /dev/urandom > in/random200
pre="$(head -c 110 /dev/zero | tr "\0" "\021")"
printf "%s\xff\xff\xff\xffhello" "$pre" > in/pchar-cap
printf "%s\x03\x00\x00\x00xyz" "$pre" > in/pchar-3
printf "%s\x00\x00\x00\x00\x2a" "$pre" > in/pchar-0

# <build dir> <sequence name> <input,input,...>
SEQS="
persist-leak-memcleanup cancelled-leak,clean cancelled-leak,clean
persist-leak-memcleanup clean,leak clean,leak
persist-leak-memcleanup leak,clean leak,clean
persist-leak-memcleanup clean-x3 clean,clean,clean
persist-leak-memtrack cancelled-leak,clean cancelled-leak,clean
persist-leak-memtrack clean,leak clean,leak
persist-leak-memtrack leak,clean leak,clean
persist-leak-memtrack clean-x3 clean,clean,clean
assume-reject-none rejected,safe rejected,safe
assume-reject-none rejected,violating rejected,violating
assume-reject-none rejected-x2,safe rejected,rejected,safe
assume-reject-none violating violating
short-input-none A A
short-input-none long,A long,A
short-input-none empty empty
short-input-none long long
gen-read empty empty
gen-read short3 short3
gen-read random200 random200
gen-read pchar-cap pchar-cap
gen-read pchar-3 pchar-3
gen-read pchar-0 pchar-0
gen-read all empty,short3,random200,pchar-cap,pchar-3,pchar-0"

cp src/fake_afl_rt.c .
clang-16 -O2 -g -c fake_afl_rt.c -o fake_afl_rt.o || { echo "fake_afl_rt.c: clang-16 failed" >&2; exit 1; }

: > link-drift.tsv
for p in $progs; do
  prog="${p%%:*}"; mode="${p##*:}"
  case="${prog%.c}-$mode"; [ "$mode" = driver ] && case="${prog%.c}"
  mkdir -p "$case/inst"; cp "src/$prog" "$case/inst/"
  # persist-leak.c leaves its block the way the mode reports it.
  [ "$mode" = memcleanup ] && sed -i "1i #define M2C_MEMCLEANUP 1" "$case/inst/$prog"
  if [ "$mode" = driver ]; then
    clang-16 -O0 -c -emit-llvm "$case/inst/$prog" -o "$case/output.bc" \
      || { echo "$case: clang-16 failed" >&2; exit 1; }
  else
    ( cd "$case/inst" && /opt/m2c/bin/map2check --debug --nondet-generator afl --timeout 10 \
        $(flags "$mode") "$prog" > m2c.log 2>&1 )
    cp "$case"/inst/*.map2check/*.map2check-output.bc "$case/output.bc" \
      || { echo "$case: no <hash>-output.bc (see $case/inst/m2c.log)" >&2; exit 1; }
    # The modules of the -result.bc link the frontend logged (Caller::linkLLVM).
    got="$(sed "s/\x1b\[[0-9;]*m//g" "$case/inst/m2c.log" | grep "llvm-link .*-result\.bc$" | grep -v witness-result \
      | head -1 | tr " " "\n" | sed -n "s|^\${MAP2CHECK_PATH}/lib/||p" | tr "\n" " ")"
    want="$(modules "" "$mode" | tr " " "\n" | sed -n "s|^/||p" | tr "\n" " ")WitnessGenerationNone.bc "
    [ "$got" = "$want" ] || printf "%s\t%s\t%s\n" "$case" "$got" "$want" >> link-drift.tsv
  fi
  for side in c rs; do
    case "$side" in c) L=/opt/m2c/lib ;; rs) L=/rs ;; esac
    d="$case/$side"; mkdir -p "$d"
    # shellcheck disable=SC2046
    llvm-link-16 "$case/output.bc" $(modules "$L" "$mode") "$L/WitnessGenerationNone.bc" -o "$d/result.bc" 2> "$d/link.err" \
      && llvm-link-16 "$case/output.bc" $(modules "$L" "$mode") "$L/WitnessGeneration.bc" -o "$d/witness-result.bc" 2>> "$d/link.err" \
      || { echo "$d: llvm-link-16 failed: $(head -3 "$d/link.err")" >&2; exit 1; }
    clang-16 -O2 -g "$d/result.bc" fake_afl_rt.o -lm -o "$d/persist.out" 2> "$d/native.err" \
      || { echo "$d: clang-16 failed: $(head -3 "$d/native.err")" >&2; exit 1; }
  done
done

# In-process sequences.
printf "case\tside\tseq\texit\titerations\toutput\tproperties\n" > results.tsv
echo "$SEQS" | while read -r bd seq inputs; do
  [ -n "$bd" ] || continue
  list=""; for i in ${inputs//,/ }; do list+="${list:+:}/work/in/$i"; done
  for side in c rs; do
    d="$bd/$side/run-$seq"; rm -rf "$d"; mkdir -p "$d"
    st=0
    { (cd "$d" && ulimit -c 0 && M2C_AFL_INPUTS="$list" exec ../persist.out) > "$d/out.txt" 2> "$d/err.txt" || st=$?; } 2>/dev/null
    its="$(grep -c "^iteration " "$d/out.txt")"
    out="$(grep -v "^iteration " "$d/out.txt" | tr "\n" "|")"
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$bd" "$side" "$seq" "$st" "$its" "${out:--}" "$(props "$d")" >> results.tsv
  done
done

# SD-20 scope: how map2check_property is written under the AFL++ generator.
printf "side\twrite_mode\n" > write-mode.tsv
for side in c rs; do
  d="write-mode/$side/run"; rm -rf "$d"; mkdir -p "$d"
  (cd "$d" && M2C_AFL_INPUTS=/work/in/empty ../persist.out > out.txt 2> err.txt)
  printf "%s\t%s\n" "$side" "$(cat "$d/write-mode" 2>/dev/null || echo -)" >> write-mode.tsv
done

# SD-21: peak RSS for 1 and for 50000 inputs in one process.
printf "side\tinputs\tmaxrss_kb\n" > rss.tsv
for side in c rs; do
  for n in 1 50000; do
    d="assume-reject-none/$side/rss-$n"; rm -rf "$d"; mkdir -p "$d"
    (cd "$d" && M2C_AFL_INPUTS=/work/in/safe M2C_AFL_REPEAT=$n ../persist.out > /dev/null 2> err.txt)
    printf "%s\t%s\t%s\n" "$side" "$n" "$(sed -n "s/^maxrss_kb //p" "$d/err.txt")" >> rss.tsv
  done
done

# afl-fuzz until the first crash, then the replays.
case=magic-none
for side in c rs; do
  d="$case/$side"
  ( cd "$d" \
    && afl-clang-fast  -g -O2  -o fuzzed.out result.bc -lm > afl-build.log 2>&1 \
    && afl-clang-fast  -g  -o witness-fuzzed.out witness-result.bc -lm >> afl-build.log 2>&1 \
    && AFL_LLVM_CMPLOG=1 afl-clang-fast  -g -O2  -o cmplog.out result.bc -lm >> afl-build.log 2>&1 ) \
    || { echo "$d: afl-clang-fast failed: $(tail -3 "$d/afl-build.log")" >&2; exit 1; }
  ( cd "$d" && rm -rf afl-in afl-out && mkdir afl-in && printf A > afl-in/seed \
    && AFL_NO_UI=1 AFL_NO_AFFINITY=1 AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
       AFL_CRASHING_SEEDS_AS_NEW_CRASH=1 AFL_BENCH_UNTIL_CRASH=1 \
       timeout -k 5 "$crash_secs" afl-fuzz -i afl-in -o afl-out -c ./cmplog.out -- ./fuzzed.out > fuzzer.output 2>&1 )
  c="$(ls "$d/afl-out/default/crashes" 2>/dev/null | grep -v README | sort | head -1)"
  [ -n "$c" ] && cp "$d/afl-out/default/crashes/$c" "$d/crash.bin"
done
printf "input\tbinary\texit\tproperties\tchecked_error\n" > replay.tsv
for from in c rs; do
  [ -f "$case/$from/crash.bin" ] || { printf "%s\t-\tno-crash\t-\t-\n" "$from" >> replay.tsv; continue; }
  for side in c rs; do
    for bin in fuzzed witness-fuzzed; do
      d="$case/$side/replay-$from-$bin"; rm -rf "$d"; mkdir -p "$d"
      st=0
      { (cd "$d" && ulimit -c 0 && exec timeout -k 1 5 ../$bin.out < "../../$from/crash.bin") > "$d/out.txt" 2>&1 || st=$?; } 2>/dev/null
      ce=no; [ -f "$d/map2check_checked_error" ] && ce=yes
      printf "%s\t%s/%s\t%s\t%s\t%s\n" "$from" "$side" "$bin" "$st" "$(props "$d")" "$ce" >> replay.tsv
    done
  done
done
' inner "$PROGS" "$AFL_CRASH_SECS" || { echo "FAIL: the runs did not complete" >&2; exit 1; }

column -t -s $'\t' "$W/results.tsv" | cut -c1-220
fail=0
if [ -s "$W/link-drift.tsv" ]; then
  while IFS=$'\t' read -r c got want; do
    echo "FAIL link order $c: the frontend linked '$got', the test '$want'" >&2; fail=1
  done < "$W/link-drift.tsv"
fi
row() { awk -F'\t' -v c="$1" -v s="$2" -v q="$3" -v f="$4" '$1==c && $2==s && $3==q {print $f}' "$W/results.tsv"; }
# check <test> <case> <seq> <exit> <iterations> <output regex> <properties regex>
check() {
  local t="$1" c="$2" q="$3" why="" side col
  for col in 4 5 6 7; do
    [ "$(row "$c" rs "$q" $col)" = "$(row "$c" c "$q" $col)" ] \
      || why+=" column $col: rust '$(row "$c" rs "$q" $col)' vs C '$(row "$c" c "$q" $col)';"
  done
  for side in c rs; do
    [ "$(row "$c" $side "$q" 4)" = "$4" ] || why+=" $side exit $(row "$c" $side "$q" 4), want $4;"
    [ "$(row "$c" $side "$q" 5)" = "$5" ] || why+=" $side ran $(row "$c" $side "$q" 5) iterations, want $5;"
    [[ "$(row "$c" $side "$q" 6)" =~ $6 ]] || why+=" $side output '$(row "$c" $side "$q" 6)' !~ $6;"
    [[ "$(row "$c" $side "$q" 7)" =~ $7 ]] || why+=" $side properties '$(row "$c" $side "$q" 7)' !~ $7;"
  done
  if [ -z "$why" ]; then echo "ok $t $c $q: exit $4, $5 iteration(s), $(row "$c" rs "$q" 7)"
  else echo "FAIL $t $c $q:$why" >&2; fail=1; fi
}
NONE='^\[map2check_property\]NONE\|$'
for m in memcleanup memtrack; do
  case $m in memcleanup) V='^\[map2check_property\]FALSE-MEMCLEANUP\|' ;; memtrack) V='^\[map2check_property\]FALSE-MEMTRACK\|' ;; esac
  t=afl_persistent_iterations_start_from_clean_state
  check $t persist-leak-$m cancelled-leak,clean 0 2 '^main end 0\|loop done\|$' "$NONE"
  check $t persist-leak-$m clean,leak 134 2 '^main end 0\|main end 2 \(leak\)\|$' "$V"
  check $t persist-leak-$m leak,clean 134 1 '^main end 2 \(leak\)\|$' "$V"
  check $t persist-leak-$m clean-x3 0 3 '^main end 0\|main end 0\|main end 0\|loop done\|$' "$NONE"
done
T='^\[map2check_property\]TARGET-REACHED\|'
t=afl_assume_rejection_cancels_only_current_input
check $t assume-reject-none rejected,safe 0 2 '^main end 3 4\|loop done\|$' "$NONE"
check $t assume-reject-none rejected,violating 134 2 '^main end 7 9\|$' "$T"
check $t assume-reject-none rejected-x2,safe 0 3 '^main end 3 4\|loop done\|$' "$NONE"
check $t assume-reject-none violating 134 1 '^main end 7 9\|$' "$T"
t=afl_short_input_is_completed_with_zeros
check $t short-input-none A 134 1 '^a=65 b=0 c=0\|$' "$T"
check $t short-input-none long,A 134 2 '^a=1094795585 b=1111638594 c=67\|a=65 b=0 c=0\|$' "$T"
check $t short-input-none empty 0 1 '^a=0 b=0 c=0\|loop done\|$' "$NONE"
check $t short-input-none long 0 1 '^a=1094795585 b=1111638594 c=67\|loop done\|$' "$NONE"
for q in empty short3 random200 pchar-cap pchar-3 pchar-0; do
  check $t gen-read "$q" 0 1 '^char:.*\|loop done\|$' "$NONE"
done
check $t gen-read all 0 6 '^char:.*\|loop done\|$' "$NONE"
# The reader, pinned on the C side: zeros past the end, pchar capped / NULL.
for q in "empty:pchar:NULL" "pchar-cap:pchar:len=5 bytes:68656c6c6f" "pchar-3:pchar:len=2 bytes:7879" "pchar-0:pchar:NULL"; do
  s="${q%%:*}"; want="${q#*:}"
  [[ "|$(row gen-read c "$s" 6)" == *"|$want|"* ]] || { echo "FAIL $t gen-read $s: the C output lacks '$want'" >&2; fail=1; }
done
[[ "$(row gen-read c empty 6)" == "char:00|pointer:0000000000000000|"* ]] \
  || { echo "FAIL $t gen-read empty: the C does not read zeros" >&2; fail=1; }

t=afl_writes_result_files_in_place_like_c
wm() { awk -F'\t' -v s="$1" '$1==s {print $2}' "$W/write-mode.tsv"; }
if [ "$(wm c)" = plain ] && [ "$(wm rs)" = plain ]; then echo "ok $t: C plain, drop-in plain"
else echo "FAIL $t: C '$(wm c)', drop-in '$(wm rs)', want plain on both" >&2; fail=1; fi

echo; column -t -s $'\t' "$W/rss.tsv"
rss() { awk -F'\t' -v s="$1" -v n="$2" '$1==s && $2==n {print $3}' "$W/rss.tsv"; }
t=afl_iterations_do_not_accumulate_records
g_rs=$(( $(rss rs 50000) - $(rss rs 1) )); g_c=$(( $(rss c 50000) - $(rss c 1) ))
if [ "$g_rs" -lt 2048 ]; then echo "ok $t: drop-in +${g_rs} KiB over 50000 inputs (C +${g_c} KiB, SD-21)"
else echo "FAIL $t: drop-in peak RSS grew ${g_rs} KiB over 50000 inputs (C ${g_c} KiB)" >&2; fail=1; fi

echo; column -t -s $'\t' "$W/replay.tsv"
t=afl_crash_replay_matches_c
rrow() { awk -F'\t' -v i="$1" -v b="$2" -v f="$3" '$1==i && $2==b {print $f}' "$W/replay.tsv"; }
for from in c rs; do
  why=""
  if [ "$(awk -F'\t' -v i="$from" '$1==i {print $3}' "$W/replay.tsv" | head -1)" = no-crash ]; then
    why+=" afl-fuzz found no crash in ${AFL_CRASH_SECS}s;"
  else
    for side in c rs; do
      [ "$(rrow "$from" "$side/fuzzed" 3)" = 134 ] || why+=" $side/fuzzed exit $(rrow "$from" "$side/fuzzed" 3), want 134;"
      [[ "$(rrow "$from" "$side/fuzzed" 4)" =~ $T ]] || why+=" $side/fuzzed properties $(rrow "$from" "$side/fuzzed" 4);"
    done
    [ "$(rrow "$from" rs/fuzzed 4)" = "$(rrow "$from" c/fuzzed 4)" ] \
      || why+=" properties rust '$(rrow "$from" rs/fuzzed 4)' vs C '$(rrow "$from" c/fuzzed 4)';"
    [ "$(rrow "$from" rs/witness-fuzzed 4)" = "$(rrow "$from" c/witness-fuzzed 4)" ] \
      || why+=" witness properties rust '$(rrow "$from" rs/witness-fuzzed 4)' vs C '$(rrow "$from" c/witness-fuzzed 4)';"
    echo "info $t $from-crash: map2check_checked_error C $(rrow "$from" c/witness-fuzzed 5), rust $(rrow "$from" rs/witness-fuzzed 5) (Task 3.1)"
  fi
  if [ -z "$why" ]; then echo "ok $t $from-crash: $(rrow "$from" rs/fuzzed 4)"
  else echo "FAIL $t $from-crash:$why" >&2; fail=1; fi
done
[ "$fail" = 0 ] && echo "OK: the drop-in AFL++ generator matches the C runtime"
exit $fail
