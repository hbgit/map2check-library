#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Guarda de cobertura da ABI do runtime C (Task 2.0 do plano drop-in).
#
# Uso: runtime-abi-coverage.sh [--lib <libmap2check.a>] [--inventory F] [--policy F]
#                              [--gap F] [--pending F] [extra.bc|.ll|.o|.a ...]
#
# Conjunto de cobertura: símbolos de inventory.tsv cujo `referenced_by` contém
# pass, frontend ou external (consumidores unidos por "+", como em
# "pass+frontend", ou por ","), menos os `c-only` de export-policy.tsv (SD-22).
# Exports: símbolos externos definidos (nm --defined-only --extern-only) da
# --lib (padrão target/release/libmap2check.a). A lib medida é a do núcleo do
# drop-in: SEM as features legadas `libfuzzer` e `klee` (por exemplo
# `CARGO_TARGET_DIR=target/coverage-lib cargo build --release --features wasm`),
# cujos exports (`__VERIFIER_error`, `__VERIFIER_assert`...) o
# Map2CheckFunctions.bc não tem e que a Task 2.10 remove; medida com
# --all-features a guarda os contava como entregues (Task 2.7).
# unidos aos dos artefatos extras (os módulos IR das tasks seguintes; .bc usa
# llvm-nm, .ll é lido como texto; um define marcado `; m2c-stub` não conta).
# Símbolos `rust-only` da política são
# irrelevantes: só se intersecta com o conjunto de cobertura.
#
# Um símbolo exportado mas com assinatura canônica diferente do C (status
# `different` em rust-gap.tsv) continua pendente. A guarda exige:
#   pending.txt == cobertura - (exports - conflitantes)
# pending.txt: um símbolo por linha, em ordem LC_ALL=C, sem comentários.
# Sai com 1 se faltar ou sobrar linha.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
export LC_ALL=C
LIB="$ROOT/target/release/libmap2check.a"
INV="$ROOT/docs/runtime-abi/inventory.tsv"
POL="$ROOT/docs/runtime-abi/export-policy.tsv"
GAP="$ROOT/docs/runtime-abi/rust-gap.tsv"
PEND="$ROOT/docs/runtime-abi/pending.txt"
EXTRA=()
while [ $# -gt 0 ]; do
  case "$1" in
    --lib) LIB="$2"; shift 2 ;;
    --inventory) INV="$2"; shift 2 ;;
    --policy) POL="$2"; shift 2 ;;
    --gap) GAP="$2"; shift 2 ;;
    --pending) PEND="$2"; shift 2 ;;
    -*) echo "opção desconhecida: $1" >&2; exit 2 ;;
    *) EXTRA+=("$1"); shift ;;
  esac
done
for f in "$LIB" "$INV" "$POL" "$GAP" "$PEND" "${EXTRA[@]}"; do
  [ -f "$f" ] || { echo "arquivo ausente: $f" >&2; exit 2; }
done
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT

nm_exports() {
  case "$1" in
    *.ll)
      # A define marked `; m2c-stub` (scripts/runtime-ir/gen_ll.py) is a
      # placeholder, not the C function: it does not count as delivered.
      { grep -v '^define.*; m2c-stub$' "$1" || true; } | sed -nE 's/^define[^@]*@("([^"]+)"|[A-Za-z0-9_.$]+)\(.*/\1/p;
               s/^@("([^"]+)"|[A-Za-z0-9_.$]+) = (dso_local |weak |linkonce |common |hidden )*(global|constant|weak|common).*/\1/p' \
        | tr -d '"' ;;
    *.bc)
      local n; n="$(command -v llvm-nm-16 || command -v llvm-nm || true)"
      [ -n "$n" ] || { echo "llvm-nm ausente para $1" >&2; exit 2; }
      "$n" --defined-only --extern-only "$1" | awk 'NF==3 {print $3}' ;;
    *) nm --defined-only --extern-only "$1" 2>/dev/null | awk 'NF==3 {print $3}' ;;
  esac
}
{ nm_exports "$LIB"; for e in "${EXTRA[@]}"; do nm_exports "$e"; done; } | sort -u > "$T/exports"

awk -F'\t' 'NR>1 && $2=="c-only" {print $1}' "$POL" | sort -u > "$T/conly"
awk -F'\t' 'NR>1 { n=split($6, a, /[,+]/); for (i=1;i<=n;i++) if (a[i]=="pass"||a[i]=="frontend"||a[i]=="external") {print $1; break} }' "$INV" \
  | sort -u | comm -23 - "$T/conly" > "$T/cov"
awk -F'\t' 'NR>1 && $2=="different" {print $1}' "$GAP" | sort -u > "$T/conflict"
comm -23 "$T/exports" "$T/conflict" > "$T/delivered"
comm -23 "$T/cov" "$T/delivered" > "$T/expected"

if ! sort -c -u "$PEND" 2>/dev/null; then
  echo "FAIL: $PEND não está ordenado (LC_ALL=C) ou tem duplicatas" >&2; exit 1
fi
if grep -qE '^\s*(#|$)|\s' "$PEND"; then
  echo "FAIL: $PEND deve ter um símbolo por linha, sem comentários nem espaços" >&2; exit 1
fi
rc=0
if comm -23 "$T/expected" "$PEND" | grep -q .; then
  echo "FAIL: pendências esquecidas (faltam em pending.txt; a lib deve ser a do núcleo, sem as features libfuzzer/klee):" >&2
  comm -23 "$T/expected" "$PEND" | sed 's/^/  /' >&2; rc=1
fi
if comm -13 "$T/expected" "$PEND" | grep -q .; then
  echo "FAIL: entregues (ou fora da cobertura) ainda listados em pending.txt (a lib deve ser a do núcleo, sem as features libfuzzer/klee):" >&2
  comm -13 "$T/expected" "$PEND" | sed 's/^/  /' >&2; rc=1
fi
[ "$rc" = 0 ] && echo "OK: $(wc -l < "$T/cov") símbolos na cobertura, $(wc -l < "$PEND") pendentes"
exit $rc
