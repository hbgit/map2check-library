#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# D7 spike (Task 1.1): the symex run of the frontend on the link-smoke program
# (safe), for one installation, in the five modes. Prints one row per mode:
#   install mode verdict completed_paths partial_paths tests err_or_early dropped_reason
# verdict SUCCEEDED means the frontend's kleeDroppedPaths() returned "" (a TRUE
# needs an exhaustive KLEE run).
#
# Usage: spikes/d7-layout/measure-klee.sh <install-dir> <label>
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
INSTALL="$(cd "$1" && pwd)"
label="$2"
commit="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION")"
IMAGE="${IMAGE:-map2check-dev:develop-${commit:0:12}}"
work="$ROOT/target/map2check-it/d7/klee-$label"
rm -rf "$work"; mkdir -p "$work"
cp "$ROOT/scripts/it/smoke/link-smoke.c" "$work/"
docker run --rm --network none --user "$(id -u):$(id -g)" -e HOME=/work \
  -v "$INSTALL:/opt/m2c:ro" -v "$work:/work" -w /work "$IMAGE" bash -c '
  for m in memtrack memcleanup overflow assert none; do
    case $m in
      memtrack) f=--memtrack ;; memcleanup) f=--memcleanup-property ;;
      overflow) f=--check-overflow ;; assert) f=--check-asserts ;;
      none) f="--target-function --target-function-name reach_error" ;;
    esac
    rm -rf ./*.map2check
    /opt/m2c/bin/map2check --debug --nondet-generator symex --timeout 30 $f link-smoke.c > "log-$m.txt" 2>&1 || true
    d=$(ls -d ./*.map2check | head -1)
    cp -r "$d" "run-$m"
    v=$(sed "s/\x1b\[[0-9;]*m//g" "log-$m.txt" | sed -n "s/^VERIFICATION \([A-Z]*\).*/\1/p" | tail -1)
    info="$d/klee-out-0/info"
    cp=$(sed -n "s/.*completed paths = //p" "$info" 2>/dev/null | head -1)
    pp=$(sed -n "s/.*partially completed paths = //p" "$info" 2>/dev/null | head -1)
    gt=$(sed -n "s/.*generated tests = //p" "$info" 2>/dev/null | head -1)
    ee=$(ls "$d/klee-out-0" 2>/dev/null | grep -cE "\.err$|\.early$" || true)
    why=$(sed "s/\x1b\[[0-9;]*m//g" "log-$m.txt" | grep -m1 -E "KLEE (did not finish|halted|concretized|hit its|terminated states)" || true)
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "'"$label"'" "$m" "${v:-ERROR}" "${cp:-}" "${pp:-}" "${gt:-}" "$ee" "${why:--}"
  done
'
