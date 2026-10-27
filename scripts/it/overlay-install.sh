#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# A Map2Check install that runs the drop-in runtime: a copy of a C install
# (scripts/it/build-map2check.sh) in which only lib/*.bc, the 21 runtime
# modules Caller::linkLLVM links, are replaced by the output of
# scripts/build-runtime-bc.sh. Everything else is copied with cp -a: bin/,
# the binary, the pass plugins and the symlinks lib/klee/runtime and
# lib/clang, whose targets exist only inside the Map2Check image, stay as
# they are.
#
# Usage: overlay-install.sh <c-install> <bc-dir> <out-install>
#   <c-install>    a Map2Check install whose lib/ holds the 21 C modules;
#   <bc-dir>       exactly the 21 drop-in modules (other .bc are refused);
#   <out-install>  created; an earlier overlay there (it has the marker
#                  file .map2check-overlay this script writes) is replaced,
#                  anything else (a C install included) is refused and left
#                  alone. It may not lie inside <c-install>.
# The C install is never written. The overlay gets one file the C install
# does not have: .map2check-overlay, with the source install and the sha256
# of the 21 modules. Test: scripts/it/test-overlay-install.sh.
set -euo pipefail
die() { echo "overlay-install: error: $*" >&2; exit 1; }
[ $# -eq 3 ] || { echo "usage: $0 <c-install> <bc-dir> <out-install>" >&2; exit 2; }
MODULES="Map2CheckFunctions TrackBBLog NonDetLog PropertyGenerator ContainerRealloc ContainerBTree BTree AnalysisModeMemtrack AnalysisModeMemcleanup AnalysisModeOverflow AnalysisModeAssert AnalysisModeNone AllocationLog ListLog HeapLog NonDetGeneratorNone NonDetGeneratorKlee NonDetGeneratorAFL WasmRuntimeStubs WitnessGeneration WitnessGenerationNone"
want="$(for m in $MODULES; do echo "$m.bc"; done | sort)"

[ -d "$1/lib" ] || die "$1 is not a Map2Check install (no lib/)"
C="$(cd "$1" && pwd)"
[ -d "$2" ] || die "$2: no such directory"
BC="$(cd "$2" && pwd)"
[ "$(cd "$C/lib" && ls -A | grep '\.bc$' | sort)" = "$want" ] \
  || die "$C/lib does not hold exactly the 21 runtime modules"
got="$(cd "$BC" && ls -A | grep '\.bc$' | sort || true)"
[ "$got" = "$want" ] \
  || die "$BC does not hold exactly the 21 runtime modules: $(diff <(echo "$want") <(echo "$got") | grep '^[<>]' | tr '\n' ' ')"

mkdir -p "$(dirname "$3")"
OUT="$(cd "$(dirname "$3")" && pwd)/$(basename "$3")"
case "$OUT/" in "$C/"*) die "$OUT lies inside $C" ;; esac
case "$C/" in "$OUT/"*) die "$C lies inside $OUT" ;; esac
MARKER=.map2check-overlay
if [ -e "$OUT" ] || [ -L "$OUT" ]; then
  # Only a directory this script made is ever deleted: a C install has
  # lib/Map2CheckFunctions.bc too, so that is no proof.
  [ -d "$OUT" ] && [ ! -L "$OUT" ] && [ -f "$OUT/$MARKER" ] && [ ! -L "$OUT/$MARKER" ] \
    && head -1 "$OUT/$MARKER" | grep -q '^map2check-overlay ' \
    || die "$OUT exists and is not an earlier overlay (no $MARKER); not touched"
  rm -rf "$OUT"
fi

tmp="$OUT.tmp.$$"
trap 'rm -rf "$tmp"' EXIT
cp -a "$C" "$tmp"
for m in $MODULES; do
  # Same mode as the C module it replaces; the content is the drop-in one.
  cp --no-preserve=all "$BC/$m.bc" "$tmp/lib/$m.bc.new"
  chmod --reference="$C/lib/$m.bc" "$tmp/lib/$m.bc.new"
  mv -f "$tmp/lib/$m.bc.new" "$tmp/lib/$m.bc"
done
[ ! -e "$tmp/$MARKER" ] || die "$C has a $MARKER: it is an overlay, not a C install"
{
  echo "map2check-overlay 1"
  echo "c-install $C"
  echo "bc-dir $BC"
  (cd "$BC" && for m in $MODULES; do sha256sum "$m.bc"; done)
} > "$tmp/$MARKER"
mv "$tmp" "$OUT"
trap - EXIT
echo "overlay-install: $OUT = $C with the 21 modules of $BC"
