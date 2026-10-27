#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 2.7: the KLEE generator of the drop-in runtime (NonDetGeneratorKlee.bc
# and the Rust core) under the real KLEE 3.1 of the Map2Check image, against
# the C runtime on the same program.
#
#   klee_safe_program_drops_no_paths       tests/runtime-ir/klee/safe.c (three
#       nondet values, a bounded loop) in the five modes: no dropped path
#       (kleeDroppedPaths of the frontend) on either side, the same number of
#       .ktest files and of completed paths as the C, the same .ktest object
#       names (the type travels in the name), the same property files (NONE);
#   klee_unsafe_program_reports_same_line  unsafe-reach.c (none, assert),
#       unsafe-overflow.c (overflow), unsafe-deref.c (memtrack),
#       unsafe-leak.c (memcleanup): a violation, not NONE, the same property
#       files as the C (property, Line, Function) and the same .ktest total;
#       the witness files of the violating path (Task 3.1: the drop-in core
#       ends the run through WitnessGeneration.bc, as the C map2check_exit):
#       the same klee_log.csv as the C, pinned by the KLEE generator's
#       nondet_generate_aux_witness_files (__m2c_rt_nondet_log_* hooks), and
#       track_bb_log.st and map2check_checked_error written on both sides.
#       safe.c: no klee_log.csv (no violation) and the same witness files.
#       The split between completed and partially completed paths is not
#       compared: with --exit-on-error-type=Abort KLEE stops at the first
#       abort, and which states finished before it depends on the searcher's
#       scheduling, which the runtime's instruction counts change;
#   klee_cover_branches_matches_c          safe.c and unsafe-reach.c in the
#       Cover-Branches mode (--cover-branches: AnalysisModeNone, KLEE with
#       --search=dfs and no --exit-on-error-type, caller.cpp:1418-1441): the
#       same .ktest count and object names as the C;
#   klee_generator_driver_matches_c        gen-aux.c, gen-aux-big.c,
#       gen-prune.c call the generator functions directly (no pass): the
#       same dropped-path verdict, .ktest count, completed paths, object
#       names (map2check_pruned, non_det_memory, non_det_unsigned...),
#       property files and klee_log.csv (written, or not above 1024 rows,
#       by nondet_generate_aux_witness_files) as the C;
#   klee_symex_writes_result_files_atomically  tests/runtime-ir/write-mode.c
#       (driver): under symex the drop-in writes map2check_property through a
#       temporary file and a rename (SD-20; NonDetGeneratorKlee's nondet_init
#       turns it on, user decision of 2026-10-27), seen through a descriptor
#       held on the old file; the C writes in place ("plain"), recorded.
#       The NONE written after the TARGET-REACHED is kept out by the
#       never-downgrade rule (SD-20, user decision of 2026-10-27): the
#       drop-in ends with TARGET-REACHED, the C with NONE;
#   klee_rust_panic_aborts_without_symbolizer  tests/runtime-ir/klee-extra/
#       panic.c (driver) with a copy of the drop-in core given a panicking
#       entry point (panic_shim.py), RUST_BACKTRACE=0 and full: the x == 7
#       path ends with an abort (std's rust_panic_with_hook is an abort stub,
#       D7 post-processing) whose stack is in the panic code and names no
#       backtrace-symbolizer function, the other path completes, KLEE
#       finishes. Drop-in only: the C runtime has no panic. KLEE runs with
#       the Cover-Branches flags (no --exit-on-error-type), so both paths run;
#   klee_wasm_overflow_matches_c           klee-extra/wasm.wat lifted by the
#       image's wasm2c and klee-extra/wasm.c (driver), memtrack mode with
#       WasmRuntimeStubs.bc, frontend flags: a write past the block is
#       OVERFLOW at line 0 with no function (SD-19), the same property files
#       and .ktest total as the C.
# These two were checks of tests/klee_paths.sh (legacy KLEE route, removed
# in Task 2.10), ported to the drop-in modules.
#
# Instrumented cases (ruling R2 of Task 1.1): the installed C Map2Check
# (target/map2check-it/c) instruments the program in the mode and its
# <hash>-output.bc is kept. Driver cases: clang-16 -O0 -emit-llvm. Each is
# linked with llvm-link-16 once with the C modules and once with the drop-in
# ones, in the order of Caller::linkLLVM for the symex generator with the
# witness module (the -witness-result.bc KLEE runs, caller.cpp:1138-1215;
# drivers: mode none), and KLEE runs with the frontend's environment
# (map2check.cpp:368-399) and flags (caller.cpp:1294-1470: --max-time,
# --external-calls=all, --exit-on-error-type=Abort, --optimize,
# --use-cex-cache, --solver-backend=z3, --libc=uclibc).
#
# Usage: test-klee-generator.sh [<drop-in-lib-dir>]
#   default: builds target/runtime-ir/dropin-lib with scripts/build-runtime-bc.sh
# The KLEE flags are written once (klee_flags below); every instrumented case
# also compares them with the command the frontend itself logged for it
# (frontend-klee-command.txt, --max-time and the file name aside), so a
# change in caller.cpp fails the test.
# Exits 77 (skip) without docker, the image or the C install.
# Output: target/runtime-ir/klee-gen/ (results.tsv, one directory per case).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
commit="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION")"
IMAGE="${IMAGE:-map2check-dev:develop-${commit:0:12}}"
M2C_INSTALL="${M2C_INSTALL:-$ROOT/target/map2check-it/c}"
KLEE_MAX_TIME="${KLEE_MAX_TIME:-120}"

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "SKIP: docker unavailable" >&2; exit 77
fi
docker image inspect "$IMAGE" >/dev/null 2>&1 || { echo "SKIP: image $IMAGE missing" >&2; exit 77; }
[ -x "$M2C_INSTALL/bin/map2check" ] \
  || { echo "SKIP: $M2C_INSTALL/bin/map2check missing (scripts/it/build-map2check.sh)" >&2; exit 77; }
M2C_INSTALL="$(cd "$M2C_INSTALL" && pwd)"

if [ $# -ge 1 ]; then
  LIB="$(cd "$1" && pwd)"
else
  LIB="$ROOT/target/runtime-ir/dropin-lib"
  "$ROOT/scripts/build-runtime-bc.sh" "$LIB"
fi

W="$ROOT/target/runtime-ir/klee-gen"
rm -rf "$W"; mkdir -p "$W/src"
cp "$ROOT"/tests/runtime-ir/klee/*.c "$ROOT/tests/runtime-ir/write-mode.c" "$W/src/"
mkdir -p "$W/extra"; cp "$ROOT"/tests/runtime-ir/klee-extra/* "$W/extra/"

# <program>:<mode>; mode "driver" = no instrumentation, linked in mode none.
CASES="safe.c:memtrack safe.c:memcleanup safe.c:overflow safe.c:assert safe.c:none
unsafe-reach.c:none unsafe-reach.c:assert unsafe-overflow.c:overflow unsafe-deref.c:memtrack unsafe-leak.c:memcleanup
gen-aux.c:driver gen-aux-big.c:driver gen-prune.c:driver write-mode.c:driver
safe.c:cover unsafe-reach.c:cover"

docker run --rm --network none --user "$(id -u):$(id -g)" -e HOME=/work \
  -e MAP2CHECK_PATH=/opt/m2c -e KLEE_RUNTIME_LIBRARY_PATH=/opt/m2c/lib/klee/runtime \
  -v "$M2C_INSTALL:/opt/m2c:ro" -v "$LIB:/rs:ro" -v "$W:/work" -w /work "$IMAGE" \
  bash -c '
set -uo pipefail
cases="$1"; max_time="$2"
flags() {
  case "$1" in
    memtrack) echo "--memtrack" ;; memcleanup) echo "--memcleanup-property" ;;
    overflow) echo "--check-overflow" ;; assert) echo "--check-asserts" ;;
    none) echo "--target-function --target-function-name reach_error" ;;
    cover) echo "--cover-branches" ;;
  esac
}
# The frontend'"'"'s KLEE flags (caller.cpp:1418-1470) after --max-time: the
# stop and search policies depend on Cover-Branches.
klee_flags() {
  case "$1" in
    cover) echo "--external-calls=all --search=dfs --optimize --use-cex-cache --solver-backend=z3 --libc=uclibc" ;;
    *) echo "--external-calls=all --exit-on-error-type=Abort --optimize --use-cex-cache --solver-backend=z3 --libc=uclibc" ;;
  esac
}
modules() { # <lib> <mode>: Caller::linkLLVM, Array, symex, witness
  local L="$1" m="$2" mods
  mods="$L/Map2CheckFunctions.bc $L/TrackBBLog.bc $L/NonDetLog.bc $L/PropertyGenerator.bc $L/ContainerRealloc.bc"
  case "$m" in
    memtrack) mods+=" $L/AnalysisModeMemtrack.bc $L/AllocationLog.bc $L/ListLog.bc $L/HeapLog.bc" ;;
    memcleanup) mods+=" $L/AnalysisModeMemcleanup.bc $L/AllocationLog.bc $L/ListLog.bc $L/HeapLog.bc" ;;
    overflow) mods+=" $L/AnalysisModeOverflow.bc" ;;
    assert) mods+=" $L/AnalysisModeAssert.bc" ;;
    none | driver | cover) mods+=" $L/AnalysisModeNone.bc" ;;
  esac
  echo "$mods $L/NonDetGeneratorKlee.bc $L/WitnessGeneration.bc"
}
dropped() { # kleeDroppedPaths of ktest_reader.cpp:368-415
  local d="$1" f
  grep -q "HaltTimer invoked" "$d/messages.txt" 2>/dev/null && { echo "halted on its timer"; return; }
  grep -q "silently concretizing" "$d/warnings.txt" 2>/dev/null && { echo "concretized a symbolic value"; return; }
  grep -qE "skipping fork|over memory cap" "$d/warnings.txt" 2>/dev/null && { echo "hit its memory cap"; return; }
  grep -q "KLEE: done: completed paths" "$d/info" 2>/dev/null || { echo "did not finish its run"; return; }
  f="$(ls "$d" | grep -E "\.(err|early)$" | head -1)"
  [ -z "$f" ] || { echo "terminated states early ($f)"; return; }
  echo "-"
}
props() { # every map2check_property* file, one string
  local d="$1" f out=""
  for f in $(cd "$d" && ls map2check_property* 2>/dev/null | sort); do
    out+="[$f]$(tr "\n" "|" < "$d/$f")"
  done
  echo "${out:--}"
}
objects() { # the distinct .ktest object names
  local n
  n="$(for t in "$1"/*.ktest; do [ -e "$t" ] && /opt/m2c/bin/ktest-tool "$t"; done 2>/dev/null \
    | sed -n "s/^object *[0-9]*: name: .\(.*\).$/\1/p" | sort -u | tr "\n" "," | sed "s/,$//")"
  echo "${n:--}"
}
printf "case\tside\tdropped\tktests\tcompleted\tpartial\tinstructions\tobjects\tklee_log\tproperties\twrite_mode\twitness_files\n" > results.tsv
for c in $cases; do
  prog="${c%%:*}"; mode="${c##*:}"
  name="${prog%.c}-$mode"; [ "$mode" = driver ] && name="${prog%.c}"
  mkdir -p "$name/inst"; cp "src/$prog" "$name/inst/"
  if [ "$mode" = driver ]; then
    clang-16 -O0 -c -emit-llvm "$name/inst/$prog" -o "$name/output.bc" \
      || { echo "$name: clang-16 failed" >&2; exit 1; }
  else
    ( cd "$name/inst" && /opt/m2c/bin/map2check --debug --nondet-generator symex --timeout 30 \
        $(flags "$mode") "$prog" > m2c.log 2>&1 )
    cp "$name"/inst/*.map2check/*.map2check-output.bc "$name/output.bc" \
      || { echo "$name: no <hash>-output.bc (see $name/inst/m2c.log)" >&2; exit 1; }
    sed "s/\x1b\[[0-9;]*m//g" "$name/inst/m2c.log" | sed -n "s/.*\(timeout -k .*klee .*\)/\1/p" \
      | head -1 > "$name/frontend-klee-command.txt"
    # The flags between --max-time and the program, spaces collapsed.
    got="$(sed -n "s/.*\/bin\/klee --max-time=[0-9]*s \(.*\) \.\/[^ ]*\.bc.*/\1/p" "$name/frontend-klee-command.txt" | tr -s " ")"
    [ "$got" = "$(klee_flags "$mode")" ] || echo "$got" > "$name/flag-drift.txt"
  fi
  for side in c rs; do
    case "$side" in c) L=/opt/m2c/lib ;; rs) L=/rs ;; esac
    d="$name/$side"; mkdir -p "$d"
    # shellcheck disable=SC2046
    llvm-link-16 "$name/output.bc" $(modules "$L" "$mode") -o "$d/witness-result.bc" 2> "$d/link.err" \
      || { echo "$name/$side: llvm-link-16 failed: $(head -3 "$d/link.err")" >&2; exit 1; }
    # shellcheck disable=SC2046
    ( cd "$d" && timeout -k 5 $((max_time + 30)) /opt/m2c/bin/klee --max-time=${max_time}s \
        $(klee_flags "$mode") ./witness-result.bc > ExecutionOutput.log 2> klee.stderr )
    k="$d/klee-last"
    log=-; [ -f "$d/klee_log.csv" ] && log="$(tr "\n" "|" < "$d/klee_log.csv")"
    wm=-; [ -f "$d/write-mode" ] && wm="$(cat "$d/write-mode")"
    wf=""; for f in klee_log.csv map2check_checked_error track_bb_log.st; do [ -f "$d/$f" ] && wf+="$f,"; done
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$name" "$side" "$(dropped "$k")" \
      "$(ls "$k" 2>/dev/null | grep -c "\.ktest$")" \
      "$(sed -n "s/.*completed paths = //p" "$k/info" 2>/dev/null | head -1)" \
      "$(sed -n "s/.*partially completed paths = //p" "$k/info" 2>/dev/null | head -1)" \
      "$(sed -n "s/^KLEE: done: total instructions = //p" "$k/info" 2>/dev/null | head -1)" \
      "$(objects "$k")" "$log" "$(props "$d")" "$wm" "${wf:--}" >> results.tsv
  done
done
' inner "$CASES" "$KLEE_MAX_TIME" || { echo "FAIL: the KLEE runs did not complete" >&2; exit 1; }

# The ported checks (panic, wasm): their own runs and results.
docker run --rm --network none --user "$(id -u):$(id -g)" -e HOME=/work \
  -e MAP2CHECK_PATH=/opt/m2c -e KLEE_RUNTIME_LIBRARY_PATH=/opt/m2c/lib/klee/runtime \
  -v "$M2C_INSTALL:/opt/m2c:ro" -v "$LIB:/rs:ro" -v "$W:/work" -w /work "$IMAGE" \
  bash -c '
set -uo pipefail
max_time="$1"
FRONT="--external-calls=all --exit-on-error-type=Abort --optimize --use-cex-cache --solver-backend=z3 --libc=uclibc"
COVER="--external-calls=all --search=dfs --optimize --use-cex-cache --solver-backend=z3 --libc=uclibc"
SYMBOLIZER="gimli|addr2line|miniz_oxide|rustc_demangle|backtrace_rs"
base() { echo "$1/TrackBBLog.bc $1/NonDetLog.bc $1/PropertyGenerator.bc $1/ContainerRealloc.bc"; }
run() { # <dir> <flags> [env...]: KLEE on <dir>/witness-result.bc
  local d="$1" f="$2"; shift 2
  # shellcheck disable=SC2086
  ( cd "$d" && env "$@" timeout -k 5 $((max_time + 30)) /opt/m2c/bin/klee --max-time=${max_time}s \
      $f ./witness-result.bc > ExecutionOutput.log 2> klee.stderr )
}
props() {
  local d="$1" f out=""
  for f in $(cd "$d" && ls map2check_property* 2>/dev/null | sort); do out+="[$f]$(tr "\n" "|" < "$d/$f")"; done
  echo "${out:--}"
}
: > extra.tsv
# panic: drop-in only.
mkdir -p panic/rs-core
clang-16 -O0 -c -emit-llvm extra/panic.c -o panic/output.bc || { echo "panic: clang-16 failed" >&2; exit 1; }
llvm-dis-16 /rs/Map2CheckFunctions.bc -o panic/rs-core/core.ll
python3 -I extra/panic_shim.py panic/rs-core/core.ll panic/rs-core/core-panic.ll || exit 1
llvm-as-16 panic/rs-core/core-panic.ll -o panic/rs-core/Map2CheckFunctions.bc || exit 1
for bt in 0 full; do
  d="panic/rs-$bt"; mkdir -p "$d"
  # shellcheck disable=SC2046
  llvm-link-16 panic/output.bc panic/rs-core/Map2CheckFunctions.bc $(base /rs) /rs/AnalysisModeNone.bc \
    /rs/NonDetGeneratorKlee.bc /rs/WitnessGeneration.bc -o "$d/witness-result.bc" 2> "$d/link.err" \
    || { echo "panic: llvm-link-16 failed: $(head -3 "$d/link.err")" >&2; exit 1; }
  run "$d" "$COVER" RUST_BACKTRACE="$bt"
  k="$d/klee-last"
  errs="$(ls "$k" 2>/dev/null | grep "\.err$" | tr "\n" "," | sed "s/,$//")"
  err="$(ls "$k"/*.err 2>/dev/null | head -1)"
  x=-; panic_frames=0; symbolizer=0
  if [ -n "$err" ]; then
    x="$(/opt/m2c/bin/ktest-tool "${err%.*.err}.ktest" | sed -n "s/^object *0: int *: //p" | head -1)"
    grep -q "panicking" "$err" && panic_frames=1
    grep -Eq "$SYMBOLIZER" "$err" && symbolizer=1
  fi
  printf "panic-%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$bt" \
    "$(grep -c "KLEE: done: completed paths" "$k/info" 2>/dev/null)" \
    "$(sed -n "s/.*completed paths = //p" "$k/info" 2>/dev/null | head -1)" \
    "${errs:--}" "$x" "$panic_frames" "$symbolizer" "$(head -1 "$err" 2>/dev/null | tr "\t" " ")" >> extra.tsv
done
# wasm: both runtimes, memtrack + WasmRuntimeStubs, frontend flags.
mkdir -p wasm/lift
wat2wasm extra/wasm.wat -o wasm/lift/t.wasm && wasm2c wasm/lift/t.wasm -o wasm/lift/t.c \
  || { echo "wasm: wat2wasm/wasm2c failed" >&2; exit 1; }
clang-16 -O0 -c -emit-llvm -I/opt/wabt-1.0.41/include -Iwasm/lift wasm/lift/t.c -o wasm/lifted.bc \
  && clang-16 -O0 -c -emit-llvm -I/opt/wabt-1.0.41/include -Iwasm/lift extra/wasm.c -o wasm/driver.bc \
  && llvm-link-16 wasm/driver.bc wasm/lifted.bc -o wasm/output.bc || { echo "wasm: clang-16 failed" >&2; exit 1; }
for side in c rs; do
  case "$side" in c) L=/opt/m2c/lib ;; rs) L=/rs ;; esac
  d="wasm/$side"; mkdir -p "$d"
  # shellcheck disable=SC2046
  llvm-link-16 wasm/output.bc $L/Map2CheckFunctions.bc $(base $L) $L/AnalysisModeMemtrack.bc $L/AllocationLog.bc \
    $L/ListLog.bc $L/HeapLog.bc $L/NonDetGeneratorKlee.bc $L/WasmRuntimeStubs.bc $L/WitnessGeneration.bc \
    -o "$d/witness-result.bc" 2> "$d/link.err" || { echo "wasm/$side: llvm-link-16 failed: $(head -3 "$d/link.err")" >&2; exit 1; }
  run "$d" "$FRONT"
  k="$d/klee-last"
  printf "wasm-%s\t%s\t%s\t%s\t%s\t%s\n" "$side" \
    "$(grep -c "KLEE: done: completed paths" "$k/info" 2>/dev/null)" \
    "$(ls "$k" 2>/dev/null | grep -c "\.ktest$")" \
    "$(ls "$k" 2>/dev/null | grep "\.err$" | sed "s/^test[0-9]*\.//" | sort -u | tr "\n" "," | sed "s/,$//")" \
    "$(grep -c "failed external call" "$d/klee.stderr" "$k/messages.txt" 2>/dev/null | awk -F: "{s+=\$NF} END{print s+0}")" \
    "$(props "$d")" >> extra.tsv
done
' inner "$KLEE_MAX_TIME" || { echo "FAIL: the KLEE runs of the ported checks did not complete" >&2; exit 1; }

cut -f1-8 "$W/results.tsv" | column -t -s $'\t'
fail=0
row() { awk -F'\t' -v c="$1" -v s="$2" -v f="$3" '$1==c && $2==s {print $f}' "$W/results.tsv"; }
# same <case> <column> <label>: the column is equal on both sides.
same() {
  local a b
  a="$(row "$1" c "$2")"; b="$(row "$1" rs "$2")"
  [ "$a" = "$b" ] || why+=" $3: rust '$b' vs C '$a';"
}
for c in $CASES; do
  prog="${c%%:*}"; mode="${c##*:}"
  name="${prog%.c}-$mode"; [ "$mode" = driver ] && name="${prog%.c}"
  why=""
  if [ -f "$W/$name/flag-drift.txt" ]; then
    why+=" the frontend ran KLEE with '$(cat "$W/$name/flag-drift.txt")', the test with the flags of klee_flags;"
  elif [ "$mode" != driver ] && [ ! -s "$W/$name/frontend-klee-command.txt" ]; then
    why+=" no KLEE command in the frontend log;"
  fi
  case "$mode:$prog" in
    cover:*)
      t=klee_cover_branches_matches_c
      same "$name" 4 ktests; same "$name" 8 "ktest objects"
      [ "$(row "$name" c 4)" -gt 0 ] || why+=" the C wrote no ktest;"
      ;;
    *) case "$prog" in
    safe.c)
      t=klee_safe_program_drops_no_paths
      [ "$(row "$name" rs 3)" = - ] || why+=" rust dropped paths: $(row "$name" rs 3);"
      [ "$(row "$name" c 3)" = - ] || why+=" C dropped paths: $(row "$name" c 3);"
      same "$name" 4 ktests; same "$name" 5 "completed paths"; same "$name" 8 "ktest objects"
      same "$name" 10 properties; same "$name" 9 klee_log.csv; same "$name" 12 "witness files"
      [ "$(row "$name" c 9)" = - ] || why+=" the C wrote klee_log.csv on a safe program;"
      ;;
    unsafe-*)
      t=klee_unsafe_program_reports_same_line
      case "$(row "$name" c 10)" in -|"[map2check_property]NONE|") why+=" the C reports no violation;" ;; esac
      same "$name" 10 properties; same "$name" 4 "ktest total"
      same "$name" 9 klee_log.csv; same "$name" 12 "witness files"
      [ "$(row "$name" c 9)" != - ] || why+=" the C wrote no klee_log.csv;"
      [[ "$(row "$name" c 12)" == *map2check_checked_error* ]] || why+=" the C wrote no map2check_checked_error;"
      ;;
    write-mode.c)
      t=klee_symex_writes_result_files_atomically
      [ "$(row "$name" rs 11)" = atomic ] || why+=" the drop-in wrote '$(row "$name" rs 11)', not atomic;"
      [ "$(row "$name" c 11)" = plain ] || why+=" the C wrote '$(row "$name" c 11)', not plain (develop's fopen(\"w\"));"
      [ "$(row "$name" rs 3)" = - ] || why+=" rust dropped paths: $(row "$name" rs 3);"
      # Never downgrade (SD-20, user decision of 2026-10-27): the NONE written
      # after TARGET-REACHED leaves the violation under symex; the C replaces it.
      [ "$(row "$name" rs 10)" = "[map2check_property]TARGET-REACHED|Line: 10|Function: first|" ] \
        || why+=" the drop-in kept '$(row "$name" rs 10)', not the violation (never downgrade);"
      [ "$(row "$name" c 10)" = "[map2check_property]NONE|" ] \
        || why+=" the C kept '$(row "$name" c 10)', not NONE;"
      ;;
    gen-*)
      t=klee_generator_driver_matches_c
      same "$name" 3 "dropped paths"; same "$name" 4 ktests; same "$name" 5 "completed paths"
      same "$name" 8 "ktest objects"; same "$name" 9 klee_log.csv; same "$name" 10 properties
      ;;
    esac ;;
  esac
  if [ -z "$why" ]; then echo "ok $t $name"; else echo "FAIL $t $name:$why" >&2; fail=1; fi
done

# The ported checks.
column -t -s $'\t' "$W/extra.tsv"
xrow() { awk -F'\t' -v c="$1" -v f="$2" '$1==c {print $f}' "$W/extra.tsv"; }
for bt in 0 full; do
  why=""
  [ "$(xrow "panic-$bt" 2)" = 1 ] || why+=" KLEE did not finish;"
  [ "$(xrow "panic-$bt" 3)" = 1 ] || why+=" completed paths '$(xrow "panic-$bt" 3)', want 1 (x != 7);"
  case "$(xrow "panic-$bt" 4)" in *.abort.err) ;; *) why+=" error files '$(xrow "panic-$bt" 4)', want one .abort.err;" ;; esac
  [ "$(xrow "panic-$bt" 5)" = 7 ] || why+=" the error path has x = '$(xrow "panic-$bt" 5)', want 7;"
  [ "$(xrow "panic-$bt" 6)" = 1 ] || why+=" the error stack is not in the panic code;"
  [ "$(xrow "panic-$bt" 7)" = 0 ] || why+=" the error stack names symbolizer code;"
  if [ -z "$why" ]; then echo "ok klee_rust_panic_aborts_without_symbolizer RUST_BACKTRACE=$bt ($(xrow "panic-$bt" 8))"
  else echo "FAIL klee_rust_panic_aborts_without_symbolizer RUST_BACKTRACE=$bt:$why" >&2; fail=1; fi
done
why=""
for side in c rs; do
  [ "$(xrow "wasm-$side" 2)" = 1 ] || why+=" $side: KLEE did not finish;"
  [ "$(xrow "wasm-$side" 5)" = 0 ] || why+=" $side: failed external calls;"
  case "$(xrow "wasm-$side" 6)" in "[map2check_property]OVERFLOW|Line: 0|Function: |"*) ;;
    *) why+=" $side: properties '$(xrow "wasm-$side" 6)', want OVERFLOW at line 0;" ;; esac
done
[ "$(xrow wasm-c 6)" = "$(xrow wasm-rs 6)" ] || why+=" properties differ;"
[ "$(xrow wasm-c 3)" = "$(xrow wasm-rs 3)" ] || why+=" ktest total: rust '$(xrow wasm-rs 3)' vs C '$(xrow wasm-c 3)';"
[ "$(xrow wasm-c 4)" = "$(xrow wasm-rs 4)" ] || why+=" error kinds: rust '$(xrow wasm-rs 4)' vs C '$(xrow wasm-c 4)';"
if [ -z "$why" ]; then echo "ok klee_wasm_overflow_matches_c wasm ($(xrow wasm-rs 6))"
else echo "FAIL klee_wasm_overflow_matches_c wasm:$why" >&2; fail=1; fi
[ "$fail" = 0 ] && echo "OK: the drop-in KLEE generator matches the C runtime under KLEE"
exit $fail
