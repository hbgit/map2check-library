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
#   dso    AnalysisModeAssert.bc passa a referenciar __dso_handle como
#          símbolo FORTE -> FAIL nas 24 combinações do modo assert (só a
#          referência weak é aceita)
#   drop   AnalysisModeMemtrack.bc perde map2check_wasm_malloc (que o
#          programa de fumaça não chama): com --ref <lib do C>, a paridade de
#          símbolos definidos falha exatamente nas 24 combinações memtrack;
#          --ref do C contra ele mesmo dá 120 PASS
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
mkdir -p "$work/dup" "$work/undef" "$work/dso" "$work/drop"
for f in dup undef dso drop; do cp "$C_LIB"/*.bc "$work/$f/"; done
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
cat > "$work/dso.ll" <<'EOF'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
@__dso_handle = external global i8
define ptr @m2c_link_matrix_dso() {
  ret ptr @__dso_handle
}
EOF
docker run --rm --user "$(id -u):$(id -g)" -v "$C_LIB:/l:ro" -v "$work:/w" "$IMG" bash -euc '
  llvm-as-16 /w/dup.ll -o /w/dup.bc
  llvm-link-16 /l/HeapLog.bc /w/dup.bc -o /w/dup/HeapLog.bc
  llvm-as-16 /w/undef.ll -o /w/undef.bc
  llvm-link-16 /l/AnalysisModeOverflow.bc /w/undef.bc -o /w/undef/AnalysisModeOverflow.bc
  llvm-as-16 /w/dso.ll -o /w/dso.bc
  llvm-link-16 /l/AnalysisModeAssert.bc /w/dso.bc -o /w/dso/AnalysisModeAssert.bc
  llvm-nm-16 --defined-only --extern-only /l/AnalysisModeMemtrack.bc | awk "{print \$NF}" \
    | grep -vx map2check_wasm_malloc > /w/drop.api
  opt-16 -passes=internalize,globaldce -internalize-public-api-file=/w/drop.api \
    /l/AnalysisModeMemtrack.bc -o /w/drop/AnalysisModeMemtrack.bc
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

# --- dso -------------------------------------------------------------------
rc=0
"$SCRIPT" "$work/dso" > "$work/dso.out" 2> "$work/dso.err" || rc=$?
[ "$rc" -eq 1 ] && ok "dso: exit 1" || bad "dso: exit $rc"
expected_fail="$(for ct in array btree; do for g in none symex afl; do for wa in 0 1; do for wi in 0 1; do
  echo "container=$ct mode=assert gen=$g wasm=$wa witness=$wi"; done; done; done; done | sort)"
got_fail="$(sed -n 's/^FAIL \(container=[a-z]* mode=[a-z]* gen=[a-z]* wasm=[01] witness=[01]\).*/\1/p' "$work/dso.out" | sort)"
[ "$got_fail" = "$expected_fail" ] && ok "dso: __dso_handle forte falha exatamente nas 24 combinações do modo assert" \
  || bad "dso: combinações FAIL diferentes do esperado: $(diff <(echo "$expected_fail") <(echo "$got_fail") | head -5 | tr '\n' ' ')"
grep -q '^FAIL container=array mode=assert gen=symex wasm=0 witness=0 undefined: __dso_handle$' "$work/dso.out" \
  && ok "dso: o FAIL nomeia __dso_handle" || bad "dso: $(grep '^FAIL.*gen=symex' "$work/dso.out" | head -1)"

# --- paridade (--ref) ------------------------------------------------------
rc=0
"$SCRIPT" --ref "$C_LIB" "$C_LIB" > "$work/ref-self.out" 2> "$work/ref-self.err" || rc=$?
n="$(grep -c '^PASS ' "$work/ref-self.out" || true)"
[ "$rc" -eq 0 ] && [ "$n" -eq 120 ] && ok "ref: o C contra ele mesmo dá 120 PASS" \
  || bad "ref: C contra C exit $rc, $n PASS"
rc=0
"$SCRIPT" --ref "$C_LIB" "$work/drop" > "$work/drop.out" 2> "$work/drop.err" || rc=$?
[ "$rc" -eq 1 ] && ok "drop: exit 1" || bad "drop: exit $rc"
expected_fail="$(for ct in array btree; do for g in none symex afl; do for wa in 0 1; do for wi in 0 1; do
  echo "container=$ct mode=memtrack gen=$g wasm=$wa witness=$wi"; done; done; done; done | sort)"
got_fail="$(sed -n 's/^FAIL \(container=[a-z]* mode=[a-z]* gen=[a-z]* wasm=[01] witness=[01]\).*/\1/p' "$work/drop.out" | sort)"
[ "$got_fail" = "$expected_fail" ] && ok "drop: paridade falha exatamente nas 24 combinações memtrack" \
  || bad "drop: combinações FAIL diferentes do esperado: $(diff <(echo "$expected_fail") <(echo "$got_fail") | head -5 | tr '\n' ' ')"
grep -q '^FAIL container=btree mode=memtrack gen=afl wasm=1 witness=1 parity: missing map2check_wasm_malloc$' "$work/drop.out" \
  && ok "drop: o FAIL nomeia o símbolo que falta" || bad "drop: $(grep '^FAIL' "$work/drop.out" | head -1)"
printf 'symbol\tside\treason\nmap2check_wasm_malloc\tc-only\tfixture\n' > "$work/policy.tsv"
rc=0
"$SCRIPT" --ref "$C_LIB" --policy "$work/policy.tsv" "$work/drop" > /dev/null 2>&1 || rc=$?
[ "$rc" -eq 0 ] && ok "drop: símbolo listado como c-only na política passa" || bad "drop com política: exit $rc"

# --- uso -------------------------------------------------------------------
rc=0
"$SCRIPT" > /dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] && ok "sem argumento: exit 2" || bad "sem argumento: exit $rc"
rc=0
"$SCRIPT" "$work/no-such-dir" > /dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] && ok "diretório inexistente: exit 2" || bad "diretório inexistente: exit $rc"
rc=0
"$SCRIPT" --ref "$work/no-such-dir" "$C_LIB" > /dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] && ok "--ref inexistente: exit 2" || bad "--ref inexistente: exit $rc"

exit $fail
