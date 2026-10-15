#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Cruza os símbolos de runtime emitidos pelos passes do Map2Check, traduzidos
# por docs/cutover/abi-mapping.tsv, com os declarados em include/map2check.h.
# Sai com 1 se algum símbolo não tiver mapeamento ou se o alvo não existir.
# Uso: symbol-matrix.sh <dir-do-Map2Check> <abi-mapping.tsv>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
M2C="$1"; MAP="$2"
PASSES=("$M2C"/modules/backend/pass/*.cpp "$M2C"/modules/backend/pass/*.hpp)
# Nomes de valores do IR (Twine de casts), não chamadas ao runtime.
IR_VALUE_NAMES='^(map2check_pointer_cast|map2check_nondet_cast_.*)$'
literais="$(grep -ohE '"(map2check_|__VERIFIER_|__map2check)[A-Za-z0-9_]*[A-Za-z0-9]"' \
  "${PASSES[@]}" 2>/dev/null | tr -d '"' | grep -vE "$IR_VALUE_NAMES" || true)"
# Famílias por tipo geradas por macro (o nome é concatenado com #c_type e não
# aparece como literal): NON_DET_FUNCTIONS_HELPER(X, t) declara
# map2check_nondet_<t>; CALL_IF_HELPER(X, X, t) casa map2check_non_det_<t>.
nondet="$(grep -ohE 'NON_DET_FUNCTIONS_HELPER(_DOUBLE)?\([A-Z][A-Za-z_]*, *[a-z_]+\)' \
  "${PASSES[@]}" 2>/dev/null | sed -E 's/.*, *([a-z_]+)\)/map2check_nondet_\1/' || true)"
non_det="$(grep -ohE 'CALL_IF_HELPER\([A-Z][A-Za-z_]*, *[A-Z_]+, *[a-z_]+\)' \
  "${PASSES[@]}" 2>/dev/null | sed -E 's/.*, *([a-z_]+)\)/map2check_non_det_\1/' || true)"
# Primeiro argumento literal de getOrInsertFunction, qualquer prefixo (a chamada
# pode quebrar linha); mantém os padrões por prefixo acima.
callees="$(cat "${PASSES[@]}" 2>/dev/null | tr '\n' ' ' \
  | grep -oE 'getOrInsertFunction\( *"[A-Za-z0-9_.]+"' | sed -E 's/.*"([^"]+)"/\1/' \
  | grep -vE "$IR_VALUE_NAMES" || true)"
pass="$(printf '%s\n%s\n%s\n%s\n' "$literais" "$nondet" "$non_det" "$callees" | grep -v '^$' | sort -u || true)"
hdr="$(grep -oE '\b(map2check_[a-z0-9_]+|__VERIFIER_[a-z0-9_]+)\s*\(' \
  "$ROOT/include/map2check.h" | tr -d '( ' | sort -u)"
missing=0
printf 'symbol\tcore_symbol\tin_rust_header\n'
while IFS= read -r s; do
  [ -z "$s" ] && continue
  core="$(awk -F'\t' -v s="$s" 'NR>1 && $1==s {print $2}' "$MAP")"
  if [ -z "$core" ]; then printf '%s\t-\t0\n' "$s"; missing=1; continue; fi
  ok=1
  if [ "$core" != "-" ] && [ "$core" != "__map2check_main__" ]; then
    IFS='+' read -ra parts <<<"$core"
    for c in "${parts[@]}"; do grep -qxF "$c" <<<"$hdr" || ok=0; done
  fi
  [ "$ok" = 1 ] || missing=1
  printf '%s\t%s\t%s\n' "$s" "$core" "$ok"
done <<<"$pass"
exit "$missing"
