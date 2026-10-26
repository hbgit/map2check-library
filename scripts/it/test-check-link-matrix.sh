#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Teste de scripts/it/check-link-matrix.sh sobre três diretórios de fixture:
#   valid  os 21 .bc do C instalados em target/map2check-it/c/lib
#          -> 120 linhas PASS e "matrix: PASS" (exit 0)
#   dup    os mesmos .bc, mas HeapLog.bc também define wasm_rt_free_memory,
#          que WasmRuntimeStubs.bc já define -> FAIL exatamente nas 24
#          combinações que ligam os dois (memtrack/memcleanup com wasm),
#          PASS nas outras 96, "matrix: FAIL" (exit 1)
#   undef  AnalysisModeOverflow.bc passa a chamar uma função que nenhum
#          módulo nem a libc define -> FAIL exatamente nas 24 combinações do
#          modo overflow
#
# Pesado (roda a matriz três vezes na imagem do Map2Check). Precisa da
# instalação do C (scripts/it/build-map2check.sh). NÃO está ligado ao CI.
# Sem docker, termina com código 77 (skip).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/it/check-link-matrix.sh"
C_LIB="$ROOT/target/map2check-it/c/lib"
fail=0
ok() { echo "ok - $1"; }
bad() { echo "FAIL - $1"; fail=1; }

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "SKIP: docker indisponível" >&2
  exit 77
fi
[ -f "$C_LIB/Map2CheckFunctions.bc" ] \
  || { echo "FAIL - $C_LIB ausente (rode scripts/it/build-map2check.sh)"; exit 1; }
[ -x "$SCRIPT" ] || { echo "FAIL - $SCRIPT ausente ou não executável"; exit 1; }

commit12="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION" | cut -c1-12)"
IMG="map2check-dev:develop-${commit12}"

work="$ROOT/target/map2check-it/test-link-matrix"
rm -rf "$work"
mkdir -p "$work/dup" "$work/undef"
cp "$C_LIB"/*.bc "$work/dup/"
cp "$C_LIB"/*.bc "$work/undef/"
cat > "$work/dup.ll" <<'EOF'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
define void @wasm_rt_free_memory(ptr %m) {
  ret void
}
EOF
cat > "$work/undef.ll" <<'EOF'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
declare void @m2c_link_matrix_no_such_function()
define void @m2c_link_matrix_caller() {
  call void @m2c_link_matrix_no_such_function()
  ret void
}
EOF
docker run --rm --user "$(id -u):$(id -g)" -v "$C_LIB:/l:ro" -v "$work:/w" "$IMG" bash -euc '
  llvm-as-16 /w/dup.ll -o /w/dup.bc
  llvm-link-16 /l/HeapLog.bc /w/dup.bc -o /w/dup/HeapLog.bc
  llvm-as-16 /w/undef.ll -o /w/undef.bc
  llvm-link-16 /l/AnalysisModeOverflow.bc /w/undef.bc -o /w/undef/AnalysisModeOverflow.bc
'

# --- valid -----------------------------------------------------------------
rc=0
"$SCRIPT" "$C_LIB" > "$work/valid.out" 2> "$work/valid.err" || rc=$?
[ "$rc" -eq 0 ] && ok "valid: exit 0" || bad "valid: exit $rc (stderr: $(tail -n3 "$work/valid.err"))"
[ "$(tail -n1 "$work/valid.out")" = "matrix: PASS" ] && ok "valid: matrix: PASS" \
  || bad "valid: última linha '$(tail -n1 "$work/valid.out")'"
n="$(grep -c '^PASS ' "$work/valid.out" || true)"
[ "$n" -eq 120 ] && ok "valid: 120 combinações PASS" || bad "valid: $n combinações PASS"
lines="$(grep -cE '^(PASS|FAIL) ' "$work/valid.out" || true)"
[ "$lines" -eq 120 ] && ok "valid: 120 linhas de combinação" || bad "valid: $lines linhas"
# As 120 combinações são distintas e cobrem o produto inteiro.
uniq_combos="$(grep -E '^(PASS|FAIL) ' "$work/valid.out" | cut -d' ' -f2-6 | sort -u | wc -l)"
[ "$uniq_combos" -eq 120 ] && ok "valid: 120 combinações distintas" || bad "valid: $uniq_combos distintas"
for c in "container=btree mode=memcleanup gen=afl wasm=1 witness=1" \
         "container=array mode=none gen=symex wasm=0 witness=0" \
         "container=array mode=assert gen=none wasm=1 witness=0"; do
  grep -qxF "PASS $c" "$work/valid.out" && ok "valid: linha 'PASS $c'" || bad "valid: falta 'PASS $c'"
done

# --- dup -------------------------------------------------------------------
rc=0
"$SCRIPT" "$work/dup" > "$work/dup.out" 2> "$work/dup.err" || rc=$?
[ "$rc" -eq 1 ] && ok "dup: exit 1" || bad "dup: exit $rc"
[ "$(tail -n1 "$work/dup.out")" = "matrix: FAIL" ] && ok "dup: matrix: FAIL" \
  || bad "dup: última linha '$(tail -n1 "$work/dup.out")'"
expected_fail="$(for ct in array btree; do for m in memtrack memcleanup; do for g in none symex afl; do for wi in 0 1; do
  echo "container=$ct mode=$m gen=$g wasm=1 witness=$wi"; done; done; done; done | sort)"
got_fail="$(sed -n 's/^FAIL \(container=[a-z]* mode=[a-z]* gen=[a-z]* wasm=[01] witness=[01]\).*/\1/p' "$work/dup.out" | sort)"
[ "$got_fail" = "$expected_fail" ] && ok "dup: FAIL exatamente nas 24 combinações memtrack/memcleanup + wasm" \
  || bad "dup: combinações FAIL diferentes do esperado: $(diff <(echo "$expected_fail") <(echo "$got_fail") | head -5 | tr '\n' ' ')"
n="$(grep -c '^PASS ' "$work/dup.out" || true)"
[ "$n" -eq 96 ] && ok "dup: 96 combinações PASS" || bad "dup: $n PASS"
grep -q '^FAIL container=btree mode=memcleanup gen=afl wasm=1 witness=1 .*wasm_rt_free_memory' "$work/dup.out" \
  && ok "dup: o FAIL nomeia a combinação e o símbolo duplicado" \
  || bad "dup: FAIL sem a combinação ou sem o símbolo: $(grep '^FAIL' "$work/dup.out" | head -1)"

# --- undef -----------------------------------------------------------------
rc=0
"$SCRIPT" "$work/undef" > "$work/undef.out" 2> "$work/undef.err" || rc=$?
[ "$rc" -eq 1 ] && ok "undef: exit 1" || bad "undef: exit $rc"
expected_fail="$(for ct in array btree; do for g in none symex afl; do for wa in 0 1; do for wi in 0 1; do
  echo "container=$ct mode=overflow gen=$g wasm=$wa witness=$wi"; done; done; done; done | sort)"
got_fail="$(sed -n 's/^FAIL \(container=[a-z]* mode=[a-z]* gen=[a-z]* wasm=[01] witness=[01]\).*/\1/p' "$work/undef.out" | sort)"
[ "$got_fail" = "$expected_fail" ] && ok "undef: FAIL exatamente nas 24 combinações do modo overflow" \
  || bad "undef: combinações FAIL diferentes do esperado: $(diff <(echo "$expected_fail") <(echo "$got_fail") | head -5 | tr '\n' ' ')"
grep -q '^FAIL container=array mode=overflow gen=symex wasm=0 witness=0 .*m2c_link_matrix_no_such_function' "$work/undef.out" \
  && ok "undef: o FAIL de symex (sem link nativo) nomeia o símbolo indefinido" \
  || bad "undef: FAIL symex sem o símbolo: $(grep '^FAIL.*gen=symex' "$work/undef.out" | head -1)"

# --- uso -------------------------------------------------------------------
rc=0
"$SCRIPT" > /dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] && ok "sem argumento: exit 2" || bad "sem argumento: exit $rc"
rc=0
"$SCRIPT" "$work/no-such-dir" > /dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] && ok "diretório inexistente: exit 2" || bad "diretório inexistente: exit $rc"

exit $fail
