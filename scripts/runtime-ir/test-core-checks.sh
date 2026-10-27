#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Fixture test of the core checks of build-test-runtime-bc.sh (--check-core,
# Task 2.10 fix round 1): the instruction-line ceiling and no
# llvm.bitreverse, on synthetic .ll files (no LLVM tools needed).
#   small      3 instruction lines, no bitreverse          -> OK
#   ceiling    the same with M2C_CORE_MAX_LINES=3          -> FAIL (3 is not < 3)
#   bitreverse a declare of llvm.bitreverse.i32            -> FAIL
#   lines      only lines inside define bodies count       -> OK under 3 with 2 + globals
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
BUILD="$HERE/build-test-runtime-bc.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
cat > "$T/small.ll" <<'EOF'
@g = global i32 0
define i32 @f(i32 %x) {
  %a = add i32 %x, 1
  %b = mul i32 %a, 2
  ret i32 %b
}
EOF
cp "$T/small.ll" "$T/bitreverse.ll"
printf 'declare i32 @llvm.bitreverse.i32(i32)\n' >> "$T/bitreverse.ll"
cat > "$T/lines.ll" <<'EOF'
@a = global i32 0
@b = global i32 0
@c = global i32 0
define void @f() {
  store i32 1, ptr @a
  ret void
}
EOF
rc=0
run() { # <name> <file> <want 0|1> [max]
  local got=0
  M2C_CORE_MAX_LINES="${4:-80000}" "$BUILD" --check-core "$T/$2" > "$T/$1.out" 2>&1 || got=$?
  if [ "$got" != "$3" ]; then echo "FAIL $1: exit $got, want $3:" >&2; cat "$T/$1.out" >&2; rc=1
  else echo "ok $1: $(head -1 "$T/$1.out")"; fi
}
run small small.ll 0
run ceiling small.ll 1 3
run bitreverse bitreverse.ll 1
run lines lines.ll 0 3
[ "$rc" = 0 ] && echo "OK: the core checks refuse the ceiling and llvm.bitreverse"
exit $rc
