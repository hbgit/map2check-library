#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 2.6 (D7 A-fwd): generates AnalysisModeMemcleanup.ll and the empty
# container/log modules, syntax-checks them with clang and links
# tests/runtime-ir/memcleanup_link.c against the release staticlib twice: with
# the Array module set (ContainerRealloc) and with the --btree set
# (ContainerBTree + BTree), plus AllocationLog, ListLog and HeapLog. Every C
# name must reach its __m2c_rt_memcleanup_* entry point: the golden scenarios
# must write the files of tests/legacy_golden/<TAG>/ byte for byte (klee_log.csv
# only by presence, Task 3.1) and end as the C runtime does, and the other
# scenarios the property files of AnalysisModeMemcleanup.c / PropertyGenerator.c.
# The module has no map2check_wasm_*.
# Both module sets must give the same results (D3: one Rust container).
# Also checks that libmap2check.a defines none of the C names of the module.
#
# Usage: test-memtrack-link.sh [<libmap2check.a>]
#   default lib: target/release/libmap2check.a (cargo build --release --all-features)
# Output: target/runtime-ir/*.ll (not committed).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LIB="${1:-$ROOT/target/release/libmap2check.a}"
OUT="$ROOT/target/runtime-ir"
CLANG="${CLANG:-clang}"
TARGET=(--target=x86_64-pc-linux-gnu)
GOLDEN="$ROOT/tests/legacy_golden"
[ -f "$LIB" ] || { echo "missing $LIB (cargo build --release --all-features)" >&2; exit 2; }

MODULES=(AnalysisModeMemcleanup ContainerRealloc ContainerBTree BTree AllocationLog ListLog HeapLog)
for m in "${MODULES[@]}"; do
  python3 -I "$HERE/gen_ll.py" --module "$m" "$ROOT/docs/runtime-abi/inventory.tsv" "$OUT"
  "$CLANG" "${TARGET[@]}" -c -x ir "$OUT/$m.ll" -o /dev/null
done
echo "OK: ${MODULES[*]} (.ll) pass $("$CLANG" --version | head -1)"

# No placeholder left in the module, and the container/log modules (D3,
# SD-22) define nothing.
! grep -q 'm2c-stub' "$OUT/AnalysisModeMemcleanup.ll" \
  || { echo "FAIL: AnalysisModeMemcleanup.ll still has m2c-stub defines" >&2; exit 1; }
for m in ContainerRealloc ContainerBTree BTree AllocationLog ListLog HeapLog; do
  ! grep -qE '^(define|declare|@)' "$OUT/$m.ll" \
    || { echo "FAIL: $m.ll is not an empty module" >&2; exit 1; }
done

# The staticlib must not define the C names of the module (ruling: IR only).
# The legacy export map2check_check_deref stays until Task 2.10; it is the
# only name allowed to clash, and the linker keeps the IR's (listed before
# the library): the invalid-deref scenario shows the IR's empty body won.
# Every name the module defines, plus its C-only globals and helpers from
# the inventory (the logs, ERROR_DEREF, update_reference_list_log).
NAMES="$( { sed -nE 's/^define[^@]*@([A-Za-z0-9_.]+)\(.*/\1/p' "$OUT/AnalysisModeMemcleanup.ll"
  awk -F'\t' 'NR>1 && $5 ~ /(^|\+)AnalysisModeMemcleanup\.bc(\+|$)/ {print $1}' "$ROOT/docs/runtime-abi/inventory.tsv"; } \
  | sort -u | paste -sd'|')"
[ "$(sed -nE 's/^define[^@]*@([A-Za-z0-9_.]+)\(.*/\1/p' "$OUT/AnalysisModeMemcleanup.ll" | wc -l)" = 16 ] \
  || { echo "FAIL: AnalysisModeMemcleanup.ll does not define the 16 C names" >&2; exit 1; }
LEGACY='map2check_check_deref'
defined="$(nm --defined-only --extern-only "$LIB" 2>/dev/null | awk 'NF==3 {print $3}' | grep -xE "$NAMES" || true)"
leaks="$(printf '%s\n' "$defined" | grep -vxE "$LEGACY" | grep . || true)"
if [ -n "$leaks" ]; then
  echo "FAIL: $LIB defines C names of AnalysisModeMemcleanup:" >&2; echo "$leaks" >&2; exit 1
fi
legacy="$(printf '%s\n' "$defined" | grep . | tr '\n' ' ' || true)"
[ -z "$legacy" ] || echo "note: $LIB still defines the legacy $legacy(removed in Task 2.10)"

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
LINK=(-Wl,--allow-multiple-definition)
"$CLANG" "${TARGET[@]}" "${LINK[@]}" "$ROOT/tests/runtime-ir/memcleanup_link.c" \
  "$OUT/AnalysisModeMemcleanup.ll" "$OUT/ContainerRealloc.ll" "$OUT/AllocationLog.ll" \
  "$OUT/ListLog.ll" "$OUT/HeapLog.ll" "$LIB" -ldl -lpthread -lm -o "$T/array"
"$CLANG" "${TARGET[@]}" "${LINK[@]}" "$ROOT/tests/runtime-ir/memcleanup_link.c" \
  "$OUT/AnalysisModeMemcleanup.ll" "$OUT/ContainerBTree.ll" "$OUT/BTree.ll" "$OUT/AllocationLog.ll" \
  "$OUT/ListLog.ll" "$OUT/HeapLog.ll" "$LIB" -ldl -lpthread -lm -o "$T/btree"

rc=0
run() { # binary scenario dir -> exit status
  local status=0
  { (ulimit -c 0; cd "$3" && exec "$T/$1" "$2") >/dev/null 2>&1 || status=$?; } 2>/dev/null
  echo "$status"
}
fail() { echo "FAIL $*" >&2; rc=1; }

# Golden scenarios: same files, bytes and end as the C runtime.
golden() {
  local bin="$1" tag="$2" d status want
  d="$T/$bin-$tag"; mkdir "$d"
  status="$(run "$bin" "$tag" "$d")"
  want="$(cat "$GOLDEN/$tag/.exit_status")"
  [ "$status" = "$want" ] || { fail "$bin $tag: status $status (want $want)"; return; }
  local got exp
  got="$(cd "$d" && ls -A | sort)"; exp="$(cd "$GOLDEN/$tag" && ls -A | grep -vx '.exit_status' | sort)"
  [ "$got" = "$exp" ] || { fail "$bin $tag: files [$got] (want [$exp])"; return; }
  for f in $exp; do
    [ "$f" = klee_log.csv ] && continue
    cmp -s "$d/$f" "$GOLDEN/$tag/$f" || { fail "$bin $tag: $f differs"; diff "$GOLDEN/$tag/$f" "$d/$f" >&2 || true; return; }
  done
  echo "ok $bin $tag"
}

# Other scenarios: exit status and the exact set and content of the files.
# Expected files are given as name=content pairs (printf escapes).
check() {
  local bin="$1" name="$2" want_status="$3" d status; shift 3
  d="$T/$bin-$name"; mkdir "$d"
  status="$(run "$bin" "$name" "$d")"
  [ "$status" = "$want_status" ] || { fail "$bin $name: status $status (want $want_status)"; return; }
  local names=() pair f
  for pair in "$@"; do
    f="${pair%%=*}"; names+=("$f")
    [ -f "$d/$f" ] || { fail "$bin $name: $f missing"; return; }
    if [ "${pair#*=}" != "*" ]; then
      [ "$(cat "$d/$f"; printf .)" = "$(printf "${pair#*=}"; printf .)" ] \
        || { fail "$bin $name: $f = $(cat "$d/$f" | od -c | head -3)"; return; }
    fi
  done
  local got exp
  got="$(cd "$d" && ls -A | sort)"; exp="$(printf '%s\n' "${names[@]}" | sort)"
  [ "$got" = "$exp" ] || { fail "$bin $name: files [$got] (want [$exp])"; return; }
  echo "ok $bin $name"
}

prop() { printf '%s\\nLine: %s\\nFunction: %s\\n' "$1" "$2" "$3"; }
for bin in array btree; do
  for tag in FALSE-MEMCLEANUP NONE UNKNOWN; do
    golden "$bin" "$tag"
  done
  # Task 2.6 Step 1: exit(0) with a reachable unfreed block. PropertyGenerator.c
  # :36-40 and :77-80 write FALSE-MEMCLEANUP to both property files.
  check "$bin" leak-at-exit 134 'map2check_property=FALSE-MEMCLEANUP\n' \
    'map2check_property_memcleanup=FALSE-MEMCLEANUP\n'
  # :141: no pointer variable refers to the leak, so the run is correct.
  check "$bin" unreferenced-leak 0 'map2check_property=NONE\n'
  # :342 error = FALSE: the second free is no FALSE-FREE (memtrack: it is).
  check "$bin" double-free 0 'map2check_property=NONE\n'
  # :158 and :294 are empty: no FALSE-DEREF (memtrack: FALSE-DEREF at 14). The
  # IR map2check_check_deref, not the legacy export, won the link.
  check "$bin" invalid-deref 0 'map2check_property=NONE\n'
  # :160 is empty: no FALSE-DEREF for a string with no terminator in the block.
  check "$bin" cstring-beyond 0 'map2check_property=NONE\n'
  # SD-23: develop SIGSEGVs at :353-354 (free) and :176-177 (resolved free) on
  # the NULL row of find_row_with_address; the core goes on, NONE.
  check "$bin" stack-free 0 'map2check_property=NONE\n'
  check "$bin" untracked-free 0 'map2check_property=NONE\n'
  # A correct run: the analysis_* hooks, then NONE.
  check "$bin" valid 0 'map2check_property=NONE\n' 'heap_log.csv=0x10000300;vla;8\n' \
    'allocation_log.csv=0x10000100;0;1\n' \
    'list_log.csv=0;0x10000000;0x10000100;1;0;1;s;21;main;0\n0;0x10000000;0x10000100;1;1;0;s;24;main;1\n'
  # :138-148 writes FALSE-MEMCLEANUP and returns FALSE without ending the run.
  check "$bin" leak-verdict 0 'map2check_property=FALSE-MEMCLEANUP\n' \
    'map2check_property_memcleanup=FALSE-MEMCLEANUP\n' 'heap_log.csv=' \
    'allocation_log.csv=0x10000100;16;0\n0x10000100;0;1\n' \
    'list_log.csv=0;0x10000000;0x10000100;1;0;1;p;11;main;0\n'
done

# D3: the Array and --btree builds wrote the same files.
for d in "$T"/array-*; do
  b="$T/btree-${d#"$T"/array-}"
  diff -r "$d" "$b" >/dev/null || fail "array and btree differ for ${d#"$T"/array-}"
done
[ "$rc" = 0 ] && echo "OK: AnalysisModeMemcleanup.ll forwarders reach the Rust core (Array and --btree sets)"
exit $rc
