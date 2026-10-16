#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
#
# Integration test of the KLEE (`symex`) runtime, Task 2.7 / issue #20,
# D1 route A' (docs/cutover/decisoes.md, docs/klee-feasibility.md).
#
# Builds the runtime bitcode with scripts/build-klee-runtime.sh, links each
# program of tests/klee/ to it with llvm-link-16 and runs KLEE 3.1 with the
# flags of Map2Check's frontend (caller.cpp:815-830). Checks:
#
#   prog.c    both sides of x == 42 explored: 2 completed paths, one ktest
#             with x = 42 (the brief's Step 1);
#   reach.c   x == 42 reaches the error: an abort whose ktest holds 42, the
#             witness nondet log says 42, and still 2 paths (condition 7:
#             the log is formatted from concretised values);
#   range.c   x > 1000 reaches the error: the log formats a value with many
#             possible digits, still 2 paths (condition 7);
#   json.c    no mode: the JSON report formats an unconstrained x, 1 path
#             (the spike's 2 -> 22 case, condition 7);
#   deref.c   KLEE finds the off-by-one read and the property file says
#             FALSE-DEREF;
#   vererr_deref.c, vererr_target.c  __VERIFIER_error()/_assert(0) do
#             nothing with a mode set, as in develop: memtrack still ends in
#             FALSE-DEREF, target mode reports nothing without
#             map2check_reach_target;
#   layout.c  condition 9: the ktest of the error path, turned into a seed
#             as the frontend's exportKleeVectorsAsSeeds does, replayed
#             through the Rust libFuzzer reader (--features libfuzzer,
#             profile runtime), reaches the same error; a zero seed of the
#             same size does not.
#
# With DEVELOP_SRC=<checkout of Map2Check develop>, the same programs also
# run against develop's C KLEE runtime (built from
# modules/backend/library/lib), and the path counts of both are printed.
#
# Usage: tests/klee_paths.sh          (runs in docker, image below)
#        tests/klee_paths.sh --inside (already in the image)
# Environment: KLEE_TEST_IMAGE (default map2check-dev:cutover-klee-rust,
#              built from tests/klee/Dockerfile when missing),
#              DEVELOP_SRC, KLEE_RESULTS (file for the path-count table).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ "${1:-}" != "--inside" ]; then
  IMAGE="${KLEE_TEST_IMAGE:-map2check-dev:cutover-klee-rust}"
  if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    docker build -t "$IMAGE" "$ROOT/tests/klee"
  fi
  args=(--rm -v "$ROOT":/src -w /src)
  if [ -n "${DEVELOP_SRC:-}" ]; then
    args+=(-v "$(cd "$DEVELOP_SRC" && pwd)":/develop:ro -e DEVELOP_SRC=/develop)
  fi
  if [ -n "${KLEE_RESULTS:-}" ]; then
    args+=(-e KLEE_RESULTS=/src/"${KLEE_RESULTS#"$ROOT"/}")
  fi
  exec docker run "${args[@]}" "$IMAGE" /src/tests/klee_paths.sh --inside
fi

T="$ROOT/tests/klee"
mkdir -p "$ROOT/target"
W="$(mktemp -d "$ROOT/target/klee-paths.XXXXXX")"
WABT="${WABT:-/opt/wabt-1.0.41}"
failures=0
pass() { echo "PASS: $*"; }
fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

# Frontend flags (caller.cpp:815-830, z3 is the default --smt-solver);
# --max-time keeps a path blow-up from hanging the test.
KLEE_FLAGS=(--external-calls=all --optimize --use-cex-cache
  --solver-backend=z3 --libc=uclibc --max-time=300s)

# The lowering's self-tests (lli-16 equivalence on tests/klee/
# lower-intrinsics.ll, rejection of tests/klee/unknown-intrinsic.ll) run
# inside scripts/build-klee-runtime.sh, so the CI build runs them too.
echo "== a failing build leaves no bitcode"
touch "$W/broken.bc"
if LLI=false CARGO_TARGET_DIR="$ROOT/target/klee-docker" \
  "$ROOT/scripts/build-klee-runtime.sh" "$W/broken.bc" >"$W/broken.log" 2>&1; then
  fail "build-klee-runtime.sh succeeded with a broken lli"
elif [ -e "$W/broken.bc" ]; then
  fail "build-klee-runtime.sh failed but left $W/broken.bc"
else
  pass "build-klee-runtime.sh fails on a broken lowering self-test and leaves no .bc"
fi

echo "== building the KLEE runtime"
CARGO_TARGET_DIR="$ROOT/target/klee-docker" \
  "$ROOT/scripts/build-klee-runtime.sh" "$W/rust-rt.bc"

# develop's C runtime as the frontend links it for symex (caller.cpp:560-640:
# the common files, ContainerRealloc, the mode's files, NonDetGeneratorKlee
# and, for the witness binary KLEE runs, WitnessGeneration).
develop_runtime() { # <mode: target|memtrack> <out.bc>
  local lib="$DEVELOP_SRC/modules/backend/library/lib" files f
  files=(Map2CheckFunctions TrackBBLog NonDetLog PropertyGenerator
    ContainerRealloc NonDetGeneratorKlee WitnessGeneration)
  case "$1" in
    target) files+=(AnalysisModeNone) ;;
    memtrack) files+=(AnalysisModeMemtrack AllocationLog ListLog HeapLog WasmRuntimeStubs) ;;
  esac
  mkdir -p "$W/dev"
  local bcs=()
  for f in "${files[@]}"; do
    [ -f "$W/dev/$f.bc" ] || clang-16 -c -emit-llvm -I"$WABT/include" "$lib/$f.c" -o "$W/dev/$f.bc" 2>/dev/null
    bcs+=("$W/dev/$f.bc")
  done
  llvm-link-16 "${bcs[@]}" -o "$2"
}

# run_klee <program> <rust|develop> <full|frontend>
#   full:     explores every path (the counts);
#   frontend: stops at the first abort, as the frontend does for a property
#             (--exit-on-error-type=Abort), which fixes the final property
#             file.
# Leaves the run in $W/<program>-<runtime>-<kind>/ (cwd of KLEE, so the
# runtime's files land there) and sets PATHS_COMPLETED, PATHS_PARTIAL.
run_klee() {
  local prog="$1" rt="$2" kind="$3" dir="$W/$1-$2-$3" rtbc cflags=() mode=target
  mkdir -p "$dir"
  case "$prog" in deref | hugemalloc | vererr_deref | wasm) mode=memtrack ;; esac
  if [ "$rt" = develop ]; then
    cflags=(-DM2C_DEVELOP)
    rtbc="$W/dev-$mode.bc"
    [ -f "$rtbc" ] || develop_runtime "$mode" "$rtbc"
  else
    rtbc="$W/rust-rt.bc"
  fi
  clang-16 -g -emit-llvm -c "${cflags[@]}" -I"$T" -I"$W/wasm" -I"$WABT/include" \
    "$T/$prog.c" -o "$dir/prog.bc"
  local progs=("$dir/prog.bc")
  if [ "$prog" = wasm ]; then # the lifted module, as caller.cpp compiles it
    clang-16 -c -emit-llvm -I"$WABT/include" -I"$W/wasm" "$W/wasm/t.c" -o "$dir/lifted.bc"
    progs+=("$dir/lifted.bc")
  fi
  llvm-link-16 "${progs[@]}" "$rtbc" -o "$dir/linked.bc"
  local extra=()
  [ "$kind" = frontend ] && extra=(--exit-on-error-type=Abort)
  (cd "$dir" && klee "${KLEE_FLAGS[@]}" "${extra[@]}" --output-dir=klee-out linked.bc \
    >klee.log 2>&1) || true
  PATHS_COMPLETED="$(sed -n 's/.*KLEE: done: completed paths = \([0-9]*\).*/\1/p' "$dir/klee.log")"
  PATHS_PARTIAL="$(sed -n 's/.*KLEE: done: partially completed paths = \([0-9]*\).*/\1/p' "$dir/klee.log")"
  PATHS_COMPLETED="${PATHS_COMPLETED:-?}"
  PATHS_PARTIAL="${PATHS_PARTIAL:-0}"
  if grep -q 'HaltTimer invoked' "$dir/klee.log"; then
    fail "$prog/$rt/$kind: KLEE hit --max-time"
  fi
}

# Prints "name size hex" per object of a ktest, writes the seed to $2.
ktest_objects() { python3 -I "$T/ktest_to_seed.py" "$1" "$2"; }

abort_ktest() { # <run dir>: the ktest of the (single) abort, or nothing
  local err
  err="$(find "$1/klee-out" -name '*.abort.err' | sort | head -n 1)"
  [ -n "$err" ] && echo "${err%.abort.err}.ktest"
}

declare -A COUNT
count() { COUNT["$1/$2"]="$PATHS_COMPLETED+$PATHS_PARTIAL"; }

# ── prog.c: two paths, x = 42 among the ktests ────────────────────────────────
echo "== prog.c"
run_klee prog rust full
count prog rust
if [ "$PATHS_COMPLETED" = 2 ]; then
  pass "prog.c: KLEE: done: completed paths = 2"
else
  fail "prog.c: completed paths = $PATHS_COMPLETED, expected 2 (see $W/prog-rust-full/klee.log)"
fi
found42=0
for k in "$W"/prog-rust-full/klee-out/*.ktest; do
  if ktest_objects "$k" "$W/seed.tmp" | grep -qx 'non_det_int 4 2a000000'; then found42=1; fi
done
if [ "$found42" = 1 ]; then
  pass "prog.c: a ktest has non_det_int = 42 (2a000000)"
else
  fail "prog.c: no ktest with x = 42"
fi

# ── reach.c: the error path, concretised witness log ──────────────────────────
echo "== reach.c"
run_klee reach rust full
count reach rust
total=$((PATHS_COMPLETED + PATHS_PARTIAL))
if [ "$total" = 2 ]; then
  pass "reach.c: 2 paths ($PATHS_COMPLETED completed + $PATHS_PARTIAL partially completed)"
else
  fail "reach.c: $PATHS_COMPLETED completed + $PATHS_PARTIAL partial paths, expected 2 in all"
fi
run_klee reach rust frontend
d="$W/reach-rust-frontend"
k="$(abort_ktest "$d")"
if [ -n "$k" ] && ktest_objects "$k" "$W/seed.tmp" | grep -qx 'non_det_int 4 2a000000'; then
  pass "reach.c: the abort's ktest has x = 42"
else
  fail "reach.c: no abort with x = 42"
fi
if [ "$(head -n 1 "$d/map2check_property" 2>/dev/null)" = TARGET-REACHED ]; then
  pass "reach.c: map2check_property says TARGET-REACHED"
else
  fail "reach.c: map2check_property is '$(cat "$d/map2check_property" 2>/dev/null)'"
fi
# klee_log.csv: the value is the 6th field (see range.c below)
if [ "$(cut -d';' -f6 "$d/klee_log.csv" 2>/dev/null | head -n 1)" = 42 ]; then
  pass "reach.c: klee_log.csv logs the concretised value 42"
else
  fail "reach.c: klee_log.csv does not log 42: '$(cat "$d/klee_log.csv" 2>/dev/null)'"
fi

# ── multistate.c: many states on the exit path, one violation ────────────────
# The legacy files are written through a temporary file and a rename, so a
# state that exits cleanly cannot truncate the violation of another one.
echo "== multistate.c"
run_klee multistate rust full
count multistate rust
for rep in 1 2 3; do
  run_klee multistate rust frontend
  d="$W/multistate-rust-frontend"
  if [ -n "$(abort_ktest "$d")" ] &&
    [ "$(head -n 1 "$d/map2check_property" 2>/dev/null)" = TARGET-REACHED ] &&
    [ -z "$(find "$d" -maxdepth 1 -name '.*.tmp')" ]; then
    pass "multistate.c ($rep): the property file ends with TARGET-REACHED, no temporary file left"
  else
    fail "multistate.c ($rep): property '$(cat "$d/map2check_property" 2>/dev/null)', tmp: '$(find "$d" -maxdepth 1 -name '.*.tmp')'"
  fi
  rm -rf "$d"
done

# ── range.c, json.c: formatting a non-unique value (condition 7) ─────────────
echo "== range.c"
run_klee range rust full
count range rust
total=$((PATHS_COMPLETED + PATHS_PARTIAL))
if [ "$total" = 2 ]; then
  pass "range.c: 2 paths, the witness log of x > 1000 does not fork"
else
  fail "range.c: $PATHS_COMPLETED completed + $PATHS_PARTIAL partial paths, expected 2 in all"
fi
run_klee range rust frontend
d="$W/range-rust-frontend"
# klee_log.csv row: step;line;scope;function;?;value;type, as develop's
# nondet_log_to_file writes it (same file from both runtimes).
logged="$(cut -d';' -f6 "$d/klee_log.csv" 2>/dev/null | head -n 1)"
if [[ "$logged" =~ ^[0-9]+$ ]] && [ "$logged" -gt 1000 ]; then
  pass "range.c: klee_log.csv logs a concrete x = $logged > 1000"
else
  fail "range.c: klee_log.csv value is '$logged'"
fi
echo "== json.c"
run_klee json rust full
count json rust
total=$((PATHS_COMPLETED + PATHS_PARTIAL))
if [ "$total" = 1 ] && grep -q '"Container_NonDetLog"' "$W/json-rust-full/klee.log"; then
  pass "json.c: the JSON report of an unconstrained x takes 1 path"
else
  fail "json.c: $PATHS_COMPLETED completed + $PATHS_PARTIAL partial paths, expected 1 (spike: 22 unconcretised)"
fi

# ── deref.c: FALSE-DEREF ──────────────────────────────────────────────────────
echo "== deref.c"
run_klee deref rust full
count deref rust
run_klee deref rust frontend
d="$W/deref-rust-frontend"
if [ -n "$(abort_ktest "$d")" ]; then
  pass "deref.c: KLEE reports the violation as an abort"
else
  fail "deref.c: no .abort.err ($(ls "$d/klee-out" | grep err || true))"
fi
if [ "$(head -n 1 "$d/map2check_property" 2>/dev/null)" = FALSE-DEREF ]; then
  pass "deref.c: map2check_property says FALSE-DEREF"
else
  fail "deref.c: map2check_property is '$(cat "$d/map2check_property" 2>/dev/null)'"
fi
k="$(abort_ktest "$d")"
if [ -n "$k" ] && ktest_objects "$k" "$W/seed.tmp" | grep -qx 'non_det_int 4 04000000'; then
  pass "deref.c: the abort's ktest has i = 4"
else
  fail "deref.c: the abort's ktest does not have i = 4"
fi

# ── hugemalloc.c: a failed malloc of a symbolic size is UNKNOWN ──────────────
# lis_unsafe: KLEE returns NULL for 4 * n > 2^31 and the pass hands the
# runtime a negative int size. The NULL block must end the run as UNKNOWN,
# as develop does; dropping the call let the state reach the second malloc,
# which KLEE bound to a concrete 2 GiB object (4.4 GB RSS, task 2.7c).
echo "== hugemalloc.c"
run_klee hugemalloc rust frontend
d="$W/hugemalloc-rust-frontend"
if [ -n "$(abort_ktest "$d")" ] && [ -e "$d/map2check_property__unknown" ] &&
  [ ! -e "$d/map2check_property" ]; then
  pass "hugemalloc.c: the NULL block of a huge malloc aborts as UNKNOWN"
else
  fail "hugemalloc.c: abort '$(abort_ktest "$d")', files: $(ls "$d" | tr '\n' ' ')"
fi
if grep -q 'Large alloc\|over memory cap' "$d/klee.log"; then
  fail "hugemalloc.c: KLEE: $(grep 'Large alloc\|over memory cap' "$d/klee.log" | head -n 1)"
else
  pass "hugemalloc.c: no state reaches a concrete multi-GiB object"
fi

# ── vererr_*.c: __VERIFIER_error/_assert are no-ops with a mode set ─────────
echo "== vererr_deref.c"
run_klee vererr_deref rust full
count vererr_deref rust
run_klee vererr_deref rust frontend
d="$W/vererr_deref-rust-frontend"
if [ "$(head -n 1 "$d/map2check_property" 2>/dev/null)" = FALSE-DEREF ] &&
  k="$(abort_ktest "$d")" && [ -n "$k" ] &&
  ktest_objects "$k" "$W/seed.tmp" | grep -qx 'non_det_int 4 04000000'; then
  pass "vererr_deref.c: __VERIFIER_error is a no-op in memtrack mode; FALSE-DEREF with i = 4"
else
  fail "vererr_deref.c: property '$(cat "$d/map2check_property" 2>/dev/null)'"
fi
echo "== vererr_target.c"
run_klee vererr_target rust full
count vererr_target rust
d="$W/vererr_target-rust-full"
if [ "$PATHS_COMPLETED" = 2 ] && [ "$PATHS_PARTIAL" = 0 ] && [ -z "$(abort_ktest "$d")" ] &&
  [ "$(head -n 1 "$d/map2check_property" 2>/dev/null)" = NONE ]; then
  pass "vererr_target.c: __VERIFIER_error alone reports nothing (2 paths, no abort, NONE)"
else
  fail "vererr_target.c: $PATHS_COMPLETED+$PATHS_PARTIAL paths, property '$(cat "$d/map2check_property" 2>/dev/null)'"
fi

# ── wasm.c: the --wasm mode, wasm2c-lifted code against the wasm stubs ────────
echo "== wasm.c"
mkdir -p "$W/wasm"
"$WABT/bin/wat2wasm" "$T/wasm.wat" -o "$W/wasm/t.wasm"
"$WABT/bin/wasm2c" "$W/wasm/t.wasm" -o "$W/wasm/t.c"
run_klee wasm rust full
count wasm rust
run_klee wasm rust frontend
d="$W/wasm-rust-frontend"
if grep -q 'failed external call' "$d/klee.log"; then
  fail "wasm.c: KLEE: $(grep 'failed external call' "$d/klee.log" | head -n 1)"
fi
# SD-19: a bad access is OVERFLOW at line 0, with no function (develop:
# write_property(FALSE_OVERFLOW, 0, "")); the same file from both runtimes.
if [ -n "$(abort_ktest "$d")" ] &&
  [ "$(head -n 1 "$d/map2check_property" 2>/dev/null)" = OVERFLOW ] &&
  [ "$(sed -n 2p "$d/map2check_property" 2>/dev/null)" = "Line: 0" ]; then
  pass "wasm.c: KLEE aborts on the access past the block; property OVERFLOW at line 0"
else
  fail "wasm.c: property '$(tr '\n' ' ' <"$d/map2check_property" 2>/dev/null)', abort: '$(abort_ktest "$d")'"
fi

# ── layout.c: ktest -> seed -> Rust libFuzzer reader (condition 9) ────────────
echo "== layout.c"
run_klee layout rust full
count layout rust
run_klee layout rust frontend
d="$W/layout-rust-frontend"
k="$(abort_ktest "$d")"
expected_objects='non_det_char 1 41
non_det_short 2 feff
non_det_ushort 2 efbe
non_det_int 4 2a000000
non_det_uint 4 efbeadde
non_det_long 8 fbffffffffffffff
non_det_ulong 8 efcdab8967452301
non_det_uchar 1 7f'
if [ -n "$k" ] && [ "$(ktest_objects "$k" "$W/layout.seed")" = "$expected_objects" ]; then
  pass "layout.c: ktest objects are sizeof(type) little-endian bytes, in order, named non_det_<type>"
else
  fail "layout.c: ktest objects differ: $( [ -n "$k" ] && ktest_objects "$k" "$W/layout.seed" | tr '\n' ',')"
fi

echo "== building the libFuzzer runtime (--features libfuzzer, profile runtime)"
MAIN_TARGET="$ROOT/target/klee-docker-main"
(cd "$ROOT" && CARGO_TARGET_DIR="$MAIN_TARGET" cargo build --locked --profile runtime \
  --features libfuzzer >"$W/cargo-main.log" 2>&1) || {
  cat "$W/cargo-main.log" >&2
  fail "cargo build --profile runtime --features libfuzzer"
}
clang-16 -g -fsanitize=fuzzer -I"$T" "$T/layout.c" "$MAIN_TARGET/runtime/libmap2check.a" \
  -ldl -lpthread -lm -o "$W/layout.fuzz"
replay() { # <seed> <dir>: runs the seed as the frontend replays (argument)
  mkdir -p "$2"
  (cd "$2" && "$W/layout.fuzz" "$1" >replay.log 2>&1) && echo 0 || echo $?
}
if [ -s "$W/layout.seed" ]; then
  rc="$(replay "$W/layout.seed" "$W/replay-klee")"
  if [ "$rc" != 0 ] && [ "$(head -n 1 "$W/replay-klee/map2check_property" 2>/dev/null)" = TARGET-REACHED ]; then
    pass "layout.c: the KLEE seed replayed by the libFuzzer reader reaches the error (rc=$rc, TARGET-REACHED)"
  else
    fail "layout.c: replay of the KLEE seed: rc=$rc, property '$(cat "$W/replay-klee/map2check_property" 2>/dev/null)'"
  fi
  head -c "$(stat -c %s "$W/layout.seed")" /dev/zero >"$W/zero.seed"
  rc="$(replay "$W/zero.seed" "$W/replay-zero")"
  if [ "$rc" = 0 ] && [ "$(head -n 1 "$W/replay-zero/map2check_property" 2>/dev/null)" = NONE ]; then
    pass "layout.c: a zero seed of the same size does not reach it (control)"
  else
    fail "layout.c: zero seed: rc=$rc, property '$(cat "$W/replay-zero/map2check_property" 2>/dev/null)'"
  fi
else
  fail "layout.c: no seed from KLEE"
fi

# ── develop's C runtime, same programs ────────────────────────────────────────
if [ -n "${DEVELOP_SRC:-}" ]; then
  echo "== develop C runtime ($DEVELOP_SRC)"
  for prog in prog reach multistate range deref hugemalloc vererr_deref vererr_target wasm layout; do
    run_klee "$prog" develop full
    count "$prog" develop
    run_klee "$prog" develop frontend
    echo "develop $prog: property '$(head -n 1 "$W/$prog-develop-frontend/map2check_property" 2>/dev/null)'," \
      "abort: $([ -n "$(abort_ktest "$W/$prog-develop-frontend")" ] && echo yes || echo no)"
  done
fi

table="$(
  echo "| program | Rust runtime (completed+partial) | develop C runtime (completed+partial) |"
  echo "|---|---|---|"
  for prog in prog reach multistate range json deref vererr_deref vererr_target wasm layout; do
    echo "| $prog.c | ${COUNT[$prog/rust]:-?} | ${COUNT[$prog/develop]:-not run} |"
  done
)"
echo "== KLEE paths (full exploration, $(klee --version 2>&1 | head -n 1))"
echo "$table"
[ -n "${KLEE_RESULTS:-}" ] && echo "$table" >"$KLEE_RESULTS"

echo "work directory: $W"
if [ "$failures" -ne 0 ]; then
  echo "$failures check(s) failed" >&2
  exit 1
fi
echo "all KLEE checks passed"
