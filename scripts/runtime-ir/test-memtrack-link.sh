#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Task 2.5 (D7 A-fwd): generates AnalysisModeMemtrack.ll and the empty
# container/log modules, syntax-checks them with clang and links
# tests/runtime-ir/memtrack_link.c against the release staticlib twice: with
# the Array module set (ContainerRealloc) and with the --btree set
# (ContainerBTree + BTree), plus AllocationLog, ListLog and HeapLog. Every C
# name must reach its __m2c_rt_memtrack_* entry point: the golden scenarios
# must write the files of tests/legacy_golden/<TAG>/ byte for byte (klee_log.csv
# only by presence, Task 3.1) and end as the C runtime does, and the other
# scenarios the property files of AnalysisModeMemtrack.c / PropertyGenerator.c.
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

MODULES=(AnalysisModeMemtrack ContainerRealloc ContainerBTree BTree AllocationLog ListLog HeapLog)
for m in "${MODULES[@]}"; do
  python3 -I "$HERE/gen_ll.py" --module "$m" "$ROOT/docs/runtime-abi/inventory.tsv" "$OUT"
  "$CLANG" "${TARGET[@]}" -c -x ir "$OUT/$m.ll" -o /dev/null
done
echo "OK: ${MODULES[*]} (.ll) pass $("$CLANG" --version | head -1)"

# No placeholder left in the module, and the container/log modules (D3,
# SD-22) define nothing.
! grep -q 'm2c-stub' "$OUT/AnalysisModeMemtrack.ll" \
  || { echo "FAIL: AnalysisModeMemtrack.ll still has m2c-stub defines" >&2; exit 1; }
for m in ContainerRealloc ContainerBTree BTree AllocationLog ListLog HeapLog; do
  ! grep -qE '^(define|declare|@)' "$OUT/$m.ll" \
    || { echo "FAIL: $m.ll is not an empty module" >&2; exit 1; }
done

# The staticlib must not define the C names of the module (ruling: IR only).
# The legacy exports map2check_check_deref and map2check_wasm_{malloc,free,
# check_access} stay until Task 2.10; they are the only names allowed to
# clash, and the linker keeps the IR's (listed before the library).
# Every name the module defines, plus its C-only globals and helpers from
# the inventory (the logs, ERROR_DEREF, update_reference_list_log).
NAMES="$( { sed -nE 's/^define[^@]*@([A-Za-z0-9_.]+)\(.*/\1/p' "$OUT/AnalysisModeMemtrack.ll"
  awk -F'\t' 'NR>1 && $5 ~ /(^|\+)AnalysisModeMemtrack\.bc(\+|$)/ {print $1}' "$ROOT/docs/runtime-abi/inventory.tsv"; } \
  | sort -u | paste -sd'|')"
[ "$(sed -nE 's/^define[^@]*@([A-Za-z0-9_.]+)\(.*/\1/p' "$OUT/AnalysisModeMemtrack.ll" | wc -l)" = 19 ] \
  || { echo "FAIL: AnalysisModeMemtrack.ll does not define the 19 C names" >&2; exit 1; }
LEGACY='map2check_check_deref|map2check_wasm_(malloc|free|check_access)'
defined="$(nm --defined-only --extern-only "$LIB" 2>/dev/null | awk 'NF==3 {print $3}' | grep -xE "$NAMES" || true)"
leaks="$(printf '%s\n' "$defined" | grep -vxE "$LEGACY" | grep . || true)"
if [ -n "$leaks" ]; then
  echo "FAIL: $LIB defines C names of AnalysisModeMemtrack:" >&2; echo "$leaks" >&2; exit 1
fi
legacy="$(printf '%s\n' "$defined" | grep . | tr '\n' ' ' || true)"
[ -z "$legacy" ] || echo "note: $LIB still defines the legacy $legacy(removed in Task 2.10)"

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
LINK=(-Wl,--allow-multiple-definition)
"$CLANG" "${TARGET[@]}" "${LINK[@]}" "$ROOT/tests/runtime-ir/memtrack_link.c" \
  "$OUT/AnalysisModeMemtrack.ll" "$OUT/ContainerRealloc.ll" "$OUT/AllocationLog.ll" \
  "$OUT/ListLog.ll" "$OUT/HeapLog.ll" "$LIB" -ldl -lpthread -lm -o "$T/array"
"$CLANG" "${TARGET[@]}" "${LINK[@]}" "$ROOT/tests/runtime-ir/memtrack_link.c" \
  "$OUT/AnalysisModeMemtrack.ll" "$OUT/ContainerBTree.ll" "$OUT/BTree.ll" "$OUT/AllocationLog.ll" \
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
  for tag in FALSE-DEREF FALSE-FREE FALSE-FREE-RESOLVED FALSE-MEMTRACK NONE UNKNOWN POSIX-MEMALIGN; do
    golden "$bin" "$tag"
  done
  # AnalysisModeMemtrack.c:367-370 (is_invalid_free of a STATIC row).
  check "$bin" non-heap-free 134 "map2check_property=$(prop FALSE-FREE 50 main)" \
    "map2check_property_free=$(prop FALSE-FREE 50 main)"
  # :159-166 stops at the fifth byte; :309-315 reports it.
  check "$bin" cstring-beyond 134 "map2check_property=$(prop FALSE-DEREF 51 main)" \
    "map2check_property_deref=$(prop FALSE-DEREF 51 main)"
  # :418-428: unknown offset, FALSE_FREE at the line, function "".
  check "$bin" wasm-free 134 "map2check_property=$(prop FALSE-FREE 61 '')" \
    "map2check_property_free=$(prop FALSE-FREE 61 '')"
  # :430-436: FALSE_OVERFLOW, line 0, function "".
  check "$bin" wasm-access 134 "map2check_property=$(prop OVERFLOW 0 '')" \
    "map2check_property_overflow=$(prop OVERFLOW 0 '')"
  # The IR map2check_wasm_* (not the legacy exports) won the link: they
  # share the allocation log with map2check_malloc, so only the wasm leak is
  # reported (the legacy table would report OVERFLOW at the access).
  check "$bin" wasm-shared-log 134 'map2check_property=FALSE-MEMTRACK\n' \
    'map2check_property_memtrack=FALSE-MEMTRACK\n'
  # A correct run: the analysis_* hooks, then NONE.
  check "$bin" valid 0 'map2check_property=NONE\n' 'heap_log.csv=0x10000300;vla;8\n' \
    'allocation_log.csv=0x10000100;0;1\n' \
    'list_log.csv=0;0x10000000;0x10000100;1;0;1;s;21;main;0\n0;0x10000000;0x10000100;1;1;0;s;24;main;1\n'
  # :138-146 writes FALSE-MEMTRACK and returns FALSE without ending the run.
  check "$bin" leak-verdict 0 'map2check_property=FALSE-MEMTRACK\n' \
    'map2check_property_memtrack=FALSE-MEMTRACK\n' 'heap_log.csv=' \
    'allocation_log.csv=0x10000100;16;0\n0x10000100;0;1\n' 'list_log.csv='
done

# D3: the Array and --btree builds wrote the same files.
for d in "$T"/array-*; do
  b="$T/btree-${d#"$T"/array-}"
  diff -r "$d" "$b" >/dev/null || fail "array and btree differ for ${d#"$T"/array-}"
done
[ "$rc" = 0 ] && echo "OK: AnalysisModeMemtrack.ll forwarders reach the Rust core (Array and --btree sets)"
exit $rc
