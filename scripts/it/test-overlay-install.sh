#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Test of scripts/it/overlay-install.sh (Task 3.1).
#
# Fixtures (host only): a fake C install with bin/ (a symlink and a file),
# the binary at the root, plugins in lib/, the 21 lib/*.bc and the two
# image-only symlinks of scripts/it/build-map2check.sh (lib/klee/runtime,
# lib/clang; dangling outside the image), and a directory with the 21 drop-in
# .bc.
#   overlay_replaces_only_the_modules  the overlay's lib/*.bc are the drop-in
#       ones; every other path (bin/, the binary, the plugins, the symlinks
#       with their targets) is the same as in the C install, byte for byte;
#       the C install is unchanged;
#   overlay_refuses                    a bc-dir without one module, with a
#       .bc that is not a runtime module, a C install without lib/, an
#       <out-install> inside the C install, an <out-install> that is not an
#       install, and wrong usage: non-zero exit, nothing created;
#   overlay_replaces_an_earlier_overlay  a second run on the same
#       <out-install> gives the same tree.
# Real install (when M2C_INSTALL and BC_DIR exist): the same checks on
# target/map2check-it/c with the output of scripts/build-runtime-bc.sh;
# bin/ and the binary byte-identical, lib/klee/runtime and lib/clang kept.
#
# Environment: M2C_INSTALL (default target/map2check-it/c), BC_DIR (default
# target/runtime-ir/dropin-lib), OUT (default target/map2check-it/rs, the
# overlay the corpus smoke runs on).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OVERLAY="$HERE/overlay-install.sh"
MODULES="Map2CheckFunctions TrackBBLog NonDetLog PropertyGenerator ContainerRealloc ContainerBTree BTree AnalysisModeMemtrack AnalysisModeMemcleanup AnalysisModeOverflow AnalysisModeAssert AnalysisModeNone AllocationLog ListLog HeapLog NonDetGeneratorNone NonDetGeneratorKlee NonDetGeneratorAFL WasmRuntimeStubs WitnessGeneration WitnessGenerationNone"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0
ok() { echo "ok $*"; }
bad() { echo "FAIL $*" >&2; fail=1; }

# A listing of a tree: path, type, symlink target or sha256, mode.
tree() { # <dir> [exclude-regex]
  (cd "$1" && find . -mindepth 1 | LC_ALL=C sort | while read -r p; do
    [ -n "${2:-}" ] && [[ "$p" =~ $2 ]] && continue
    if [ -L "$p" ]; then echo "$p L $(readlink "$p")"
    elif [ -d "$p" ]; then echo "$p d $(stat -c %a "$p")"
    else echo "$p f $(sha256sum < "$p" | cut -c1-16) $(stat -c %a "$p")"; fi
  done)
}

# Checks <c> <bc> <out>: the overlay against the C install and the modules.
check() {
  local c="$1" bc="$2" out="$3" label="$4" m why=""
  local mods_re='^\./lib/[A-Za-z0-9]+\.bc$'
  diff <(tree "$c" "$mods_re") <(tree "$out" "$mods_re") > "$T/diff" \
    || why+=" paths other than lib/*.bc differ: $(grep '^[<>]' "$T/diff" | head -5 | tr '\n' ' ');"
  for m in $MODULES; do
    cmp -s "$bc/$m.bc" "$out/lib/$m.bc" || why+=" lib/$m.bc is not the drop-in one;"
  done
  [ "$(cd "$out/lib" && ls *.bc | wc -l)" = 21 ] || why+=" lib/ has $(cd "$out/lib" && ls *.bc | wc -l) .bc;"
  [ "$(tree "$c/bin")" = "$(tree "$out/bin")" ] || why+=" bin/ differs;"
  if [ -z "$why" ]; then ok "$label"; else bad "$label:$why"; fi
}

# --- fixtures ---------------------------------------------------------------
C="$T/c"; BC="$T/bc"
mkdir -p "$C/bin" "$C/lib/klee" "$BC"
printf 'ELF-ish binary\n' > "$C/map2check"; chmod 755 "$C/map2check"
ln -s ../map2check "$C/bin/map2check"
printf '#!/bin/sh\n' > "$C/bin/ktest-tool"; chmod 755 "$C/bin/ktest-tool"
printf 'plugin\n' > "$C/lib/libMemoryTrackPass.so"
ln -s /opt/klee/lib/klee/runtime "$C/lib/klee/runtime"
ln -s /usr/lib/llvm-16/lib/clang "$C/lib/clang"
for m in $MODULES; do printf 'C %s\n' "$m" > "$C/lib/$m.bc"; printf 'RS %s\n' "$m" > "$BC/$m.bc"; done
before="$(tree "$C")"

"$OVERLAY" "$C" "$BC" "$T/out" > "$T/log" 2>&1 || bad "overlay_replaces_only_the_modules: exit $?: $(tail -2 "$T/log")"
[ -d "$T/out" ] && check "$C" "$BC" "$T/out" "overlay_replaces_only_the_modules (fixture)"
[ "$(tree "$C")" = "$before" ] && ok "overlay_replaces_only_the_modules: the C install is unchanged" \
  || bad "overlay_replaces_only_the_modules: the C install changed"
[ "$(readlink "$T/out/lib/clang")" = /usr/lib/llvm-16/lib/clang ] && [ -L "$T/out/lib/klee/runtime" ] \
  && ok "overlay_replaces_only_the_modules: lib/clang and lib/klee/runtime stay symlinks" \
  || bad "overlay_replaces_only_the_modules: the image-only symlinks were not kept"

first="$(tree "$T/out")"
"$OVERLAY" "$C" "$BC" "$T/out" > "$T/log" 2>&1 || bad "overlay_replaces_an_earlier_overlay: exit $?"
[ "$(tree "$T/out")" = "$first" ] && ok "overlay_replaces_an_earlier_overlay" \
  || bad "overlay_replaces_an_earlier_overlay: the tree changed"

refuse() { # <label> <args...>: non-zero exit and no new output
  local label="$1" st=0; shift
  "$OVERLAY" "$@" > "$T/log" 2>&1 || st=$?
  if [ "$st" != 0 ] && [ ! -e "$T/new" ]; then ok "overlay_refuses $label (exit $st: $(head -1 "$T/log"))"
  else bad "overlay_refuses $label: exit $st"; fi
  rm -rf "$T/new"
}
cp -a "$BC" "$T/bc-missing"; rm "$T/bc-missing/HeapLog.bc"
refuse "a missing module" "$C" "$T/bc-missing" "$T/new"
cp -a "$BC" "$T/bc-extra"; printf 'x' > "$T/bc-extra/Extra.bc"
refuse "an unknown module" "$C" "$T/bc-extra" "$T/new"
mkdir -p "$T/c-nolib/bin"
refuse "a C install without lib/" "$T/c-nolib" "$BC" "$T/new"
st=0; "$OVERLAY" "$C" "$BC" "$C/inner" > "$T/log" 2>&1 || st=$?
if [ "$st" != 0 ] && [ ! -e "$C/inner" ]; then ok "overlay_refuses an <out-install> inside the C install"
else bad "overlay_refuses an <out-install> inside the C install: exit $st"; rm -rf "$C/inner"; fi
mkdir -p "$T/notinstall"; echo data > "$T/notinstall/file"
st=0; "$OVERLAY" "$C" "$BC" "$T/notinstall" > "$T/log" 2>&1 || st=$?
if [ "$st" != 0 ] && [ "$(cat "$T/notinstall/file")" = data ]; then ok "overlay_refuses an <out-install> that is not an install"
else bad "overlay_refuses an <out-install> that is not an install: exit $st"; fi
st=0; "$OVERLAY" "$C" "$BC" > "$T/log" 2>&1 || st=$?
[ "$st" = 2 ] && ok "overlay_refuses wrong usage (exit 2)" || bad "overlay_refuses wrong usage: exit $st, want 2"

# --- the real C install -------------------------------------------------------
M2C_INSTALL="${M2C_INSTALL:-$ROOT/target/map2check-it/c}"
BC_DIR="${BC_DIR:-$ROOT/target/runtime-ir/dropin-lib}"
OUT="${OUT:-$ROOT/target/map2check-it/rs}"
if [ -f "$M2C_INSTALL/lib/Map2CheckFunctions.bc" ] && [ -f "$BC_DIR/Map2CheckFunctions.bc" ]; then
  M2C_INSTALL="$(cd "$M2C_INSTALL" && pwd)"
  before="$(tree "$M2C_INSTALL")"
  if "$OVERLAY" "$M2C_INSTALL" "$BC_DIR" "$OUT" > "$T/log" 2>&1; then
    check "$M2C_INSTALL" "$BC_DIR" "$OUT" "overlay of $M2C_INSTALL with $BC_DIR into $OUT"
    for p in map2check bin/map2check; do
      cmp -s "$M2C_INSTALL/$p" "$OUT/$p" && ok "real: $p byte-identical ($(sha256sum < "$OUT/$p" | cut -c1-16))" \
        || bad "real: $p differs"
    done
    for l in lib/klee/runtime lib/clang; do
      [ -L "$OUT/$l" ] && [ "$(readlink "$OUT/$l")" = "$(readlink "$M2C_INSTALL/$l")" ] \
        && ok "real: $l -> $(readlink "$OUT/$l") kept" || bad "real: $l not kept as a symlink"
    done
    [ "$(tree "$M2C_INSTALL")" = "$before" ] && ok "real: the C install is unchanged" || bad "real: the C install changed"
  else
    bad "real overlay: $(tail -2 "$T/log")"
  fi
else
  echo "real install: skipped ($M2C_INSTALL/lib or $BC_DIR missing; scripts/it/build-map2check.sh, scripts/build-runtime-bc.sh)"
fi
[ "$fail" = 0 ] && echo "OK: overlay-install.sh replaces only lib/*.bc"
exit $fail
