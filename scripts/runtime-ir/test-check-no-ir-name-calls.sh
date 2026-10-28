#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Test of check-no-ir-name-calls.sh: a fixture archive in which an exported
# function calls another exported function of the same object by a name an IR
# module defines (the Task 2.9 recursion hazard) must be refused; the same
# archive with the call going through a differently named function must pass;
# the allow-list exempts exactly the listed caller>target pair.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
GUARD="$HERE/check-no-ir-name-calls.sh"
CC="${CC:-clang}"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir "$T/ll"
cat > "$T/ll/M.ll" <<'LL'
define void @wasm_rt_init() {
  ret void
}
LL
cat > "$T/bad.c" <<'C'
void wasm_rt_init(void) {}
void __m2c_rt_wasm_init(void) { wasm_rt_init(); }
C
cat > "$T/good.c" <<'C'
static void wasm_rt_init_impl(void) {}
void wasm_rt_init(void) { wasm_rt_init_impl(); }
void __m2c_rt_wasm_init(void) { wasm_rt_init_impl(); }
C
for k in bad good; do
  "$CC" --target=x86_64-pc-linux-gnu -O0 -fno-inline -fPIC -c "$T/$k.c" -o "$T/$k.o"
  ar rcs "$T/$k.a" "$T/$k.o"
done
rc=0
if "$GUARD" "$T/bad.a" "$T/ll" >"$T/bad.out" 2>&1; then
  echo "FAIL: the guard accepted a call to an IR-defined name" >&2; rc=1
else
  grep -qx '__m2c_rt_wasm_init>wasm_rt_init' "$T/bad.out" \
    || { echo "FAIL: wrong report:" >&2; cat "$T/bad.out" >&2; rc=1; }
fi
"$GUARD" "$T/good.a" "$T/ll" >/dev/null || { echo "FAIL: the guard refused a clean archive" >&2; rc=1; }
M2C_IR_CALL_ALLOW='__m2c_rt_wasm_init>wasm_rt_init' "$GUARD" "$T/bad.a" "$T/ll" >/dev/null \
  || { echo "FAIL: the allow-list did not exempt its pair" >&2; rc=1; }
if M2C_IR_CALL_ALLOW='other>wasm_rt_init' "$GUARD" "$T/bad.a" "$T/ll" >/dev/null 2>&1; then
  echo "FAIL: the allow-list exempted another pair" >&2; rc=1
fi
[ "$rc" = 0 ] && echo "OK: check-no-ir-name-calls.sh catches a reintroduced call"
exit $rc
