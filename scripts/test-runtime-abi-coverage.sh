#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Teste offline de scripts/runtime-abi-coverage.sh (Task 2.0), com inventário e
# biblioteca de fixture. Precisa de clang e nm.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
export LC_ALL=C
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
printf 'symbol\tkind\tsignature\tcanonical_signature\tmodule\treferenced_by\n' > "$T/inv.tsv"
for r in "alpha pass" "beta frontend,runtime" "gamma external" "delta runtime" "eps pass" "zeta pass" "internal_c pass"; do
  set -- $r; printf '%s\tfunc\tvoid (void)\tvoid (void)\tM.bc\t%s\n' "$1" "$2" >> "$T/inv.tsv"
done
printf 'symbol\tside\treason\ninternal_c\tc-only\tx\n__m2c_rt_*\trust-only\tx\n' > "$T/pol.tsv"
printf 'symbol\tstatus\trust_signature\trust_canonical_signature\nzeta\tdifferent\tint (void)\tint (void)\n' > "$T/gap.tsv"
# Biblioteca fixture: alpha e zeta (assinatura em conflito) exportados; beta,
# eps e gamma não estão na lib; __m2c_rt_core é extra do Rust (rust-only,
# ignorado) e local_fn é estático (não conta como export).
cat > "$T/lib.c" <<'C'
void alpha(void) {}
int zeta(void) { return 0; }
void __m2c_rt_core(void) {}
static void local_fn(void) {}
void use_local(void) { local_fn(); }
C
clang -c "$T/lib.c" -o "$T/lib.o"
ar rcs "$T/lib.a" "$T/lib.o"
# Módulo IR extra que entrega gamma
printf 'define void @gamma() {\n  ret void\n}\n' > "$T/extra.ll"

run() { "$HERE/runtime-abi-coverage.sh" --lib "$T/lib.a" --inventory "$T/inv.tsv" \
  --policy "$T/pol.tsv" --gap "$T/gap.tsv" --pending "$T/pend.txt" "$@"; }

# cobertura = alpha beta eps gamma zeta; entregues = alpha (zeta conflita)
# igualdade passa
printf 'beta\neps\ngamma\nzeta\n' > "$T/pend.txt"
run >"$T/out" 2>&1 || { cat "$T/out" >&2; echo "FALHA: igualdade deveria passar" >&2; exit 1; }

# pendência esquecida
printf 'beta\ngamma\nzeta\n' > "$T/pend.txt"
if run >"$T/out" 2>&1; then echo "FALHA: pendência esquecida passou" >&2; exit 1; fi
grep -q 'eps' "$T/out"

# símbolo entregue ainda listado
printf 'alpha\nbeta\neps\ngamma\nzeta\n' > "$T/pend.txt"
if run >"$T/out" 2>&1; then echo "FALHA: entregue ainda listado passou" >&2; exit 1; fi
grep -q 'alpha' "$T/out"

# zeta exportado mas com assinatura em conflito: removê-lo de pending falha
printf 'beta\neps\ngamma\n' > "$T/pend.txt"
if run >"$T/out" 2>&1; then echo "FALHA: conflito de assinatura escondido" >&2; exit 1; fi
grep -q 'zeta' "$T/out"

# artefato extra (.ll) entrega gamma
printf 'beta\neps\nzeta\n' > "$T/pend.txt"
run "$T/extra.ll" >/dev/null 2>&1 || { echo "FALHA: extra .ll não foi contado" >&2; exit 1; }

# símbolos fora do inventário, estáticos e rust-only não contam como pendência
printf 'beta\neps\nzeta\nlocal_fn\n' > "$T/pend.txt"
if run "$T/extra.ll" >/dev/null 2>&1; then echo "FALHA: linha desconhecida em pending passou" >&2; exit 1; fi
# tests/abi/check-signatures.sh com headers de fixture
CS="$HERE/../tests/abi/check-signatures.sh"
mkdir -p "$T/h"
printf 'void f_ok(int);\nvoid f_bad(int);\n' > "$T/h/A.h"
printf 'void f_ok(int x);\nvoid f_bad(long x);\n' > "$T/rust.h"
printf 'f_bad\n' > "$T/p.txt"
"$CS" "$T/h" --pending "$T/p.txt" --rust-header "$T/rust.h" > "$T/out" || { cat "$T/out" >&2; echo "FALHA: XFAIL esperado deveria sair 0" >&2; exit 1; }
grep -q '^XFAIL A.h' "$T/out"
: > "$T/p.txt"
if "$CS" "$T/h" --pending "$T/p.txt" --rust-header "$T/rust.h" >"$T/out"; then echo "FALHA: deriva fora de pending passou" >&2; exit 1; fi
grep -q '^FAIL  A.h' "$T/out"
printf 'f_bad\nf_ok\n' > "$T/p.txt"
if "$CS" "$T/h" --pending "$T/p.txt" --rust-header "$T/rust.h" >"$T/out"; then echo "FALHA: pendente conforme passou" >&2; exit 1; fi
grep -q 'f_ok' "$T/out"
# valores de enum: XFAIL com marcador, FAIL se batem com marcador, FAIL sem marcador
printf 'enum E { A = 0, B = 1 };\n' > "$T/h/A.h"
printf 'typedef enum E { X, Y } E;\n' > "$T/rust.h"
printf 'tag\tc_enumerator\trust_enumerator\nE\tA\tX\nE\tB\tY\n' > "$T/em.tsv"
: > "$T/p.txt"
ce() { "$CS" "$T/h" --pending "$T/p.txt" --rust-header "$T/rust.h" --enum-map "$T/em.tsv" --pending-enums "$T/pe.txt"; }
printf 'enum E { A = 0, B = 2 };\n' > "$T/h/A.h"
echo 'enum:E' > "$T/pe.txt"
ce > "$T/out" || { cat "$T/out" >&2; echo "FALHA: enum divergente com marcador deveria ser XFAIL" >&2; exit 1; }
grep -q '^XFAIL A.h' "$T/out"
: > "$T/pe.txt"
if ce >"$T/out"; then echo "FALHA: enum divergente sem marcador passou" >&2; exit 1; fi
grep -q '^FAIL  A.h' "$T/out"
printf 'enum E { A = 0, B = 1 };\n' > "$T/h/A.h"
echo 'enum:E' > "$T/pe.txt"
if ce >"$T/out"; then echo "FALHA: enum igual com marcador passou" >&2; exit 1; fi
grep -q 'remova o marcador' "$T/out"
: > "$T/pe.txt"
ce > "$T/out" || { cat "$T/out" >&2; echo "FALHA: enum igual sem marcador deveria passar" >&2; exit 1; }
grep -q '^PASS  A.h (n=0' "$T/out"
# o check de enum não falha aberto
printf 'enum E { A = 0, B = 1 };\n' > "$T/h/A.h"; : > "$T/pe.txt"
printf 'tag\tc_enumerator\trust_enumerator\nE\tA\tX\nE\tB\tNOPE\n' > "$T/em.tsv"
if ce >"$T/out"; then echo "FALHA: erro de compilação virou 0 divergências" >&2; exit 1; fi
grep -q 'NOPE' "$T/out"
printf 'tag\tc_enumerator\trust_enumerator\nE\tA\tX\n' > "$T/em.tsv"
if ce >"$T/out"; then echo "FALHA: enumerador C sem linha no mapa passou" >&2; exit 1; fi
grep -q 'sem linha.*B' "$T/out"
echo "test-runtime-abi-coverage: OK"
