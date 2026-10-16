#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
#
# Builds each driver against the C runtime of Map2Check develop, as
# Caller::linkLLVM does (modules/frontend/caller.cpp:550-640, witness
# binary: WitnessGeneration.bc), runs it in a fresh directory and copies
# every file it writes to $OUT/<TAG>/. Run inside map2check-dev (see
# ../README.md):
#
#   RUNTIME  develop's modules/backend/library (read-only)
#   DRIVERS  this directory (read-only)
#   OUT      tests/legacy_golden (written)
set -euo pipefail

RUNTIME=${RUNTIME:-/runtime}
DRIVERS=${DRIVERS:-/drivers}
OUT=${OUT:-/out}
CC=${CC:-clang-16}
LINK=${LINK:-llvm-link-16}
WORK=$(mktemp -d)

bc() { "$CC" -c -emit-llvm -I"$RUNTIME/header" "$1" -o "$2"; }

# Files that linkLLVM links in every run (:560-564), the Array container
# (:567-569), the witness generation (:627) and the nondet generator.
for f in Map2CheckFunctions TrackBBLog NonDetLog PropertyGenerator \
  ContainerRealloc WitnessGeneration AnalysisModeMemtrack \
  AnalysisModeMemcleanup AnalysisModeOverflow AnalysisModeAssert \
  AnalysisModeNone AllocationLog ListLog HeapLog; do
  bc "$RUNTIME/lib/$f.c" "$WORK/$f.bc"
done
bc "$DRIVERS/NonDetGeneratorLog.c" "$WORK/NonDetGeneratorLog.bc"

COMMON="Map2CheckFunctions TrackBBLog NonDetLog PropertyGenerator ContainerRealloc"
MEMORY="AllocationLog ListLog HeapLog"

# tag -> analysis mode files (:578-612)
declare -A MODE=(
  [FALSE-FREE]="AnalysisModeMemtrack $MEMORY"
  [FALSE-FREE-RESOLVED]="AnalysisModeMemtrack $MEMORY"
  [FALSE-DEREF]="AnalysisModeMemtrack $MEMORY"
  [FALSE-MEMTRACK]="AnalysisModeMemtrack $MEMORY"
  [FALSE-MEMCLEANUP]="AnalysisModeMemcleanup $MEMORY"
  [NONE]="AnalysisModeMemtrack $MEMORY"
  [UNKNOWN]="AnalysisModeMemtrack $MEMORY"
  [OVERFLOW]="AnalysisModeOverflow"
  [DIVBYZERO]="AnalysisModeOverflow"
  [POSIX-MEMALIGN]="AnalysisModeMemtrack $MEMORY"
  [ASSERT]="AnalysisModeAssert"
  [TARGET-REACHED]="AnalysisModeNone"
  [NONDET-TYPES]="AnalysisModeAssert"
)

for tag in FALSE-FREE FALSE-FREE-RESOLVED FALSE-DEREF FALSE-MEMTRACK FALSE-MEMCLEANUP NONE \
  UNKNOWN OVERFLOW DIVBYZERO POSIX-MEMALIGN ASSERT TARGET-REACHED \
  NONDET-TYPES; do
  bc "$DRIVERS/$tag.c" "$WORK/$tag-output.bc"
  inputs=("$WORK/$tag-output.bc")
  for f in $COMMON ${MODE[$tag]} NonDetGeneratorLog WitnessGeneration; do
    inputs+=("$WORK/$f.bc")
  done
  "$LINK" "${inputs[@]}" -o "$WORK/$tag-witness-result.bc"
  "$CC" "$WORK/$tag-witness-result.bc" -Wl,--wrap=free -o "$WORK/$tag"

  run="$WORK/run-$tag"
  mkdir "$run"
  status=0
  (cd "$run" && "$WORK/$tag" >stdout.txt 2>stderr.txt) || status=$?
  echo "$tag: exit status $status; files: $(ls "$run" | grep -v -e stdout.txt -e stderr.txt | tr '\n' ' ')"
  mkdir -p "$OUT/$tag"
  for f in "$run"/*; do
    case "$(basename "$f")" in stdout.txt | stderr.txt) continue ;; esac
    cp "$f" "$OUT/$tag/"
  done
  echo "$status" >"$OUT/$tag/.exit_status"
done
