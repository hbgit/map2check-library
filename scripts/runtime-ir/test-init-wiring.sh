#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 2.7 (pulled forward from Task 3.1, plan Step 1): a program linked to
# the .bc modules that never calls analysis_init by hand writes the property
# files and aborts in each mode, because map2check_init of the core calls the
# external analysis_init and then nondet_init (Map2CheckFunctions.c:37-38).
#
# tests/runtime-ir/init_wiring.c, compiled per mode with clang-16, is linked
# with llvm-link-16 to Map2CheckFunctions TrackBBLog NonDetLog
# PropertyGenerator ContainerRealloc <mode modules> NonDetGeneratorNone
# WitnessGenerationNone (Caller::linkLLVM, generator none, the -result.bc),
# natively with clang-16 -lm, and run; once with the C runtime
# (target/map2check-it/c/lib) and once with the drop-in. Expected on both: exit
# 134 (abort) and the same, non-empty property files.
#
# Usage: test-init-wiring.sh [<drop-in-lib-dir>]
#   default: builds target/runtime-ir/dropin-lib with build-test-runtime-bc.sh
# Exits 77 (skip) without docker, the image or the C install.
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
  "$HERE/build-test-runtime-bc.sh" "$LIB"
fi

W="$ROOT/target/runtime-ir/init-wiring"
rm -rf "$W"; mkdir -p "$W"
cp "$ROOT/tests/runtime-ir/init_wiring.c" "$W/"

docker run --rm --network none --user "$(id -u):$(id -g)" \
  -v "$CLIB:/c:ro" -v "$LIB:/rs:ro" -v "$W:/work" -w /work "$IMAGE" bash -c '
set -uo pipefail
modules() { # <lib> <mode>
  local L="$1" m="$2" mods
  mods="$L/Map2CheckFunctions.bc $L/TrackBBLog.bc $L/NonDetLog.bc $L/PropertyGenerator.bc $L/ContainerRealloc.bc"
  case "$m" in
    memtrack) mods+=" $L/AnalysisModeMemtrack.bc $L/AllocationLog.bc $L/ListLog.bc $L/HeapLog.bc" ;;
    memcleanup) mods+=" $L/AnalysisModeMemcleanup.bc $L/AllocationLog.bc $L/ListLog.bc $L/HeapLog.bc" ;;
    overflow) mods+=" $L/AnalysisModeOverflow.bc" ;;
    assert) mods+=" $L/AnalysisModeAssert.bc" ;;
    none) mods+=" $L/AnalysisModeNone.bc" ;;
  esac
  echo "$mods $L/NonDetGeneratorNone.bc $L/WitnessGenerationNone.bc"
}
for m in memtrack memcleanup overflow assert none; do
  clang-16 -O0 -c -emit-llvm -DM2C_MODE_$m init_wiring.c -o "prog-$m.bc" || exit 1
  for side in c rs; do
    d="$m-$side"; mkdir -p "$d"
    # shellcheck disable=SC2046
    llvm-link-16 "prog-$m.bc" $(modules "/$side" "$m") -o "$d/result.bc" 2> "$d/link.err" \
      || { echo "$d: llvm-link-16: $(head -2 "$d/link.err")" >&2; exit 1; }
    clang-16 "$d/result.bc" -lm -o "$d/a.out" 2> "$d/native.err" \
      || { echo "$d: clang-16: $(head -2 "$d/native.err")" >&2; exit 1; }
    st=0; { (cd "$d" && ulimit -c 0 && exec ./a.out) > "$d/out.txt" 2>&1 || st=$?; } 2>/dev/null
    p=""; for f in $(cd "$d" && ls map2check_property* 2>/dev/null | sort); do p+="[$f]$(tr "\n" "|" < "$d/$f")"; done
    printf "%s\t%s\t%s\t%s\n" "$m" "$side" "$st" "${p:--}"
  done
done > results.tsv
' || { echo "FAIL: the runs did not complete" >&2; exit 1; }

fail=0
row() { awk -F'\t' -v m="$1" -v s="$2" -v f="$3" '$1==m && $2==s {print $f}' "$W/results.tsv"; }
for m in memtrack memcleanup overflow assert none; do
  why=""
  for side in c rs; do
    [ "$(row "$m" "$side" 3)" = 134 ] || why+=" $side exit $(row "$m" "$side" 3), not 134 (abort);"
  done
  case "$(row "$m" c 4)" in -|"[map2check_property]NONE|") why+=" the C wrote no violation;" ;; esac
  [ "$(row "$m" rs 4)" = "$(row "$m" c 4)" ] || why+=" properties rust '$(row "$m" rs 4)' vs C '$(row "$m" c 4)';"
  if [ -z "$why" ]; then
    echo "ok map2check_init_selects_the_linked_mode $m: $(row "$m" rs 4)"
  else
    echo "FAIL map2check_init_selects_the_linked_mode $m:$why" >&2; fail=1
  fi
done
[ "$fail" = 0 ] && echo "OK: map2check_init calls the linked analysis_init and nondet_init"
exit $fail
