#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 3.1: the drop-in core ends a run through the witness module it is
# linked with, as the C map2check_exit does (Map2CheckFunctions.c:89-102):
# generate_aux_files(&trackbb_log, gotError), then on an error
# generate_confirmation_file and abort. WitnessGeneration.bc forwards both to
# __m2c_rt_witness_*; WitnessGenerationNone.bc defines them empty. The
# witness option of the core (config.witness, __m2c_rt_witness_enable) plays
# no part in the drop-in. In the C, generate_aux_files writes
# track_bb_log.st, runs analysis_generate_aux_witness_files of the mode and,
# on a violation or with MAP2CHECK_SEED_REPLAY set,
# nondet_generate_aux_witness_files of the generator, which alone writes
# klee_log.csv (WitnessGeneration.c:15-29): nothing under NonDetGeneratorNone.
#
#   witness_module_is_called_once     tests/runtime-ir/witness/witness_trace.c
#       stands in for the witness module: a success run records
#       "generate_aux_files 0" and a violation run (each mode)
#       "generate_aux_files 1", "generate_confirmation_file", on both sides;
#   witness_files_match_c             tests/runtime-ir/witness/witness_aux.c
#       with the real modules, generator none: the same exit status and the
#       same files as the C, byte for byte (the memory logs by name only: they
#       hold addresses), with WitnessGeneration.bc (track_bb_log.st, and
#       map2check_checked_error on a violation) and with
#       WitnessGenerationNone.bc (property files only);
#   klee_log_comes_from_the_generator witness_aux.c under the AFL++ generator
#       (NonDetGeneratorAFL.bc, tests/runtime-ir/afl/fake_afl_rt.c): a
#       violation writes klee_log.csv, as the C, byte for byte; a success
#       does not, unless MAP2CHECK_SEED_REPLAY is set; without witness, never.
#       Under generator none no run writes it (above). The KLEE generator is
#       checked under KLEE by test-klee-generator.sh;
#   wasm_trap_writes_checked_error    witness_aux.c -DM2C_TRAP with
#       WasmRuntimeStubs.bc: after wasm_rt_trap the drop-in writes
#       map2check_checked_error, as the C (whose map2check_error runs
#       map2check_exit), and track_bb_log.st as the C; the property files
#       differ by SD-19 (the drop-in records UNKNOWN) and are not compared.
#
# Each program: clang-16 -O0 -emit-llvm, llvm-link-16 with the modules in the
# order of Caller::linkLLVM (Array container), clang-16 -lm, run in a fresh
# directory. Once with the C runtime (target/map2check-it/c/lib) and once
# with the drop-in.
#
# Usage: test-witness-wiring.sh [<drop-in-lib-dir>]
#   default: builds target/runtime-ir/dropin-lib with scripts/build-runtime-bc.sh
# Exits 77 (skip) without docker, the image or the C install.
# Output: target/runtime-ir/witness-wiring/ (results.tsv, one directory per run).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
commit="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION")"
IMAGE="${IMAGE:-map2check-dev:develop-${commit:0:12}}"
M2C_INSTALL="${M2C_INSTALL:-$ROOT/target/map2check-it/c}"

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "SKIP: docker unavailable" >&2; exit 77
fi
docker image inspect "$IMAGE" >/dev/null 2>&1 || { echo "SKIP: image $IMAGE missing" >&2; exit 77; }
[ -f "$M2C_INSTALL/lib/Map2CheckFunctions.bc" ] \
  || { echo "SKIP: $M2C_INSTALL/lib missing (scripts/it/build-map2check.sh)" >&2; exit 77; }
CLIB="$(cd "$M2C_INSTALL/lib" && pwd)"

if [ $# -ge 1 ]; then
  LIB="$(cd "$1" && pwd)"
else
  LIB="$ROOT/target/runtime-ir/dropin-lib"
  "$ROOT/scripts/build-runtime-bc.sh" "$LIB"
fi

W="$ROOT/target/runtime-ir/witness-wiring"
rm -rf "$W"; mkdir -p "$W/src"
cp "$ROOT"/tests/runtime-ir/witness/*.c "$ROOT/tests/runtime-ir/afl/fake_afl_rt.c" "$W/src/"

cname="m2c-t31-witness-$$"
cleanup() { docker rm -f "$cname" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run --rm --name "$cname" --network none --user "$(id -u):$(id -g)" \
  -v "$CLIB:/c:ro" -v "$LIB:/rs:ro" -v "$W:/work" -w /work "$IMAGE" bash -c '
set -uo pipefail
mods() { # <lib> <mode> <gen> <witness: 0|1|trace> [wasm]: Caller::linkLLVM, Array
  local L="$1" m="$2" g="$3" w="$4" wa="${5:-0}" out
  out="$L/Map2CheckFunctions.bc $L/TrackBBLog.bc $L/NonDetLog.bc $L/PropertyGenerator.bc $L/ContainerRealloc.bc"
  case "$m" in
    memtrack) out+=" $L/AnalysisModeMemtrack.bc $L/AllocationLog.bc $L/ListLog.bc $L/HeapLog.bc" ;;
    memcleanup) out+=" $L/AnalysisModeMemcleanup.bc $L/AllocationLog.bc $L/ListLog.bc $L/HeapLog.bc" ;;
    overflow) out+=" $L/AnalysisModeOverflow.bc" ;;
    assert) out+=" $L/AnalysisModeAssert.bc" ;;
    none) out+=" $L/AnalysisModeNone.bc" ;;
  esac
  case "$g" in none) out+=" $L/NonDetGeneratorNone.bc" ;; afl) out+=" $L/NonDetGeneratorAFL.bc" ;; esac
  [ "$wa" = 1 ] && out+=" $L/WasmRuntimeStubs.bc"
  case "$w" in
    1) out+=" $L/WitnessGeneration.bc" ;;
    0) out+=" $L/WitnessGenerationNone.bc" ;;
    trace) out+=" trace.bc" ;;
  esac
  echo "$out"
}
files() { # every file a run wrote, "name=sha" (memory logs: name only), sorted
  local d="$1" f out=""
  for f in $(cd "$d" && ls | grep -vxE "a\.out|result\.bc|link\.err|native\.err|out\.txt" | sort); do
    case "$f" in
      heap_log.csv | allocation_log.csv | list_log.csv) out+="$f " ;;
      *) out+="$f=$(sha256sum < "$d/$f" | cut -c1-12) " ;;
    esac
  done
  echo "${out:--}"
}
clang-16 -O0 -c -emit-llvm src/witness_trace.c -o trace.bc || exit 1
clang-16 -O2 -c src/fake_afl_rt.c -o fake_afl_rt.o || exit 1
printf "\x05\x00\x00\x00\x07\x00\x00\x00" > input.bin
# <case> <define> <mode> <gen> <witness> <wasm> [env]
CASES="
success-none M2C_SUCCESS none none
success-memtrack M2C_SUCCESS memtrack none
viol-overflow M2C_MODE_overflow overflow none
viol-assert M2C_MODE_assert assert none
viol-none M2C_MODE_none none none
viol-memtrack M2C_MODE_memtrack memtrack none
viol-memcleanup M2C_MODE_memcleanup memcleanup none
afl-viol-none M2C_MODE_none none afl
afl-success-none M2C_SUCCESS none afl
afl-seed-success-none M2C_SUCCESS none afl
trap-memtrack M2C_TRAP memtrack none
trap-none M2C_TRAP none none"
printf "case\twitness\tside\texit\tfiles\ttrace\n" > results.tsv
echo "$CASES" | while read -r c def m g; do
  [ -n "$c" ] || continue
  wa=0; case "$c" in trap-*) wa=1 ;; esac
  env=""; case "$c" in afl-seed-*) env="MAP2CHECK_SEED_REPLAY=1" ;; esac
  clang-16 -O0 -c -emit-llvm -D"$def" src/witness_aux.c -o "prog-$c.bc" || exit 1
  for w in 0 1 trace; do
    for side in c rs; do
      d="$c/w$w-$side"; mkdir -p "$d"
      # shellcheck disable=SC2046
      llvm-link-16 "prog-$c.bc" $(mods "/$side" "$m" "$g" "$w" "$wa") -o "$d/result.bc" 2> "$d/link.err" \
        || { echo "$d: llvm-link-16: $(head -2 "$d/link.err")" >&2; exit 1; }
      extra=""; [ "$g" = afl ] && extra="fake_afl_rt.o"
      clang-16 "$d/result.bc" $extra -lm -o "$d/a.out" 2> "$d/native.err" \
        || { echo "$d: clang-16: $(head -2 "$d/native.err")" >&2; exit 1; }
      st=0
      { (cd "$d" && ulimit -c 0 && exec env $env M2C_AFL_INPUTS=/work/input.bin ./a.out) > "$d/out.txt" 2>&1 || st=$?; } 2>/dev/null
      tr=-; [ -f "$d/witness-trace.txt" ] && tr="$(tr "\n" "|" < "$d/witness-trace.txt")"
      printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$c" "$w" "$side" "$st" "$(files "$d")" "$tr" >> results.tsv
    done
  done
done
' || { echo "FAIL: the runs did not complete" >&2; exit 1; }

column -t -s $'\t' "$W/results.tsv" | cut -c1-230
fail=0
row() { awk -F'\t' -v c="$1" -v w="$2" -v s="$3" -v f="$4" '$1==c && $2==w && $3==s {print $f}' "$W/results.tsv"; }
has() { [[ " $(row "$1" "$2" "$3" 5) " == *" $4"[=\ ]* ]]; }
res() { if [ -z "$why" ]; then echo "ok $1"; else echo "FAIL $1:$why" >&2; fail=1; fi; }

for c in success-none success-memtrack viol-overflow viol-assert viol-none viol-memtrack viol-memcleanup; do
  why=""
  case "$c" in success-*) want="generate_aux_files 0|" ;; *) want="generate_aux_files 1|generate_confirmation_file|" ;; esac
  for side in c rs; do
    [ "$(row "$c" trace $side 6)" = "$want" ] || why+=" $side trace '$(row "$c" trace $side 6)', want '$want';"
  done
  res "witness_module_is_called_once $c"
done

for c in success-none success-memtrack viol-overflow viol-assert viol-none viol-memtrack viol-memcleanup; do
  for w in 0 1; do
    why=""
    for col in 4 5; do
      [ "$(row "$c" $w rs $col)" = "$(row "$c" $w c $col)" ] \
        || why+=" column $col: rust '$(row "$c" $w rs $col)' vs C '$(row "$c" $w c $col)';"
    done
    case "$c:$w" in
      success-*:1) has "$c" 1 c track_bb_log.st || why+=" the C wrote no track_bb_log.st;" ;;
      viol-*:1) has "$c" 1 c map2check_checked_error || why+=" the C wrote no map2check_checked_error;" ;;
      *:0) for f in track_bb_log.st map2check_checked_error klee_log.csv heap_log.csv; do
             has "$c" 0 rs $f && why+=" the drop-in wrote $f without witness;"
           done ;;
    esac
    has "$c" "$w" rs klee_log.csv && why+=" the drop-in wrote klee_log.csv under generator none;"
    res "witness_files_match_c $c witness=$w"
  done
done

for c in afl-viol-none afl-success-none afl-seed-success-none; do
  for w in 0 1; do
    why=""
    for col in 4 5; do
      [ "$(row "$c" $w rs $col)" = "$(row "$c" $w c $col)" ] \
        || why+=" column $col: rust '$(row "$c" $w rs $col)' vs C '$(row "$c" $w c $col)';"
    done
    case "$c:$w" in
      afl-success-none:*|*:0) has "$c" $w c klee_log.csv && why+=" the C wrote klee_log.csv;" ;;
      *) has "$c" $w c klee_log.csv || why+=" the C wrote no klee_log.csv;" ;;
    esac
    res "klee_log_comes_from_the_generator $c witness=$w"
  done
done

for c in trap-memtrack trap-none; do
  for w in 0 1; do
    why=""
    [ "$(row "$c" $w rs 4)" = "$(row "$c" $w c 4)" ] || why+=" exit rust $(row "$c" $w rs 4) vs C $(row "$c" $w c 4);"
    for f in map2check_checked_error track_bb_log.st klee_log.csv; do
      a="$(row "$c" $w c 5 | tr " " "\n" | grep "^$f" || true)"
      b="$(row "$c" $w rs 5 | tr " " "\n" | grep "^$f" || true)"
      [ "$a" = "$b" ] || why+=" $f: rust '${b:-absent}' vs C '${a:-absent}';"
    done
    if [ "$w" = 1 ]; then
      has "$c" 1 c map2check_checked_error || why+=" the C wrote no map2check_checked_error;"
    fi
    res "wasm_trap_writes_checked_error $c witness=$w"
  done
done
[ "$fail" = 0 ] && echo "OK: the drop-in core ends the run through the linked witness module"
exit $fail
