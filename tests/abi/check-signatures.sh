#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Conformidade de assinaturas contra os headers do runtime C (Task 2.0).
#
# Uso: check-signatures.sh <vendor-header-dir> [--pending F] [--rust-header F]
#
# Para cada *.h do diretório compila com `clang -fsyntax-only -Werror` uma
# unidade que inclui o header C e depois include/map2check.h. A tag
# `enum ViolatedProperty` do C é renomeada na unidade (macro) porque o Rust a
# redefine com outros enumeradores por desenho (conferência de valores é da task
# que entrega PropertyGenerator).
# Cada diagnóstico "conflicting types for 'X'" é atribuído ao símbolo X:
#   PASS   nenhum erro, e nenhum símbolo pendente declarado nos dois headers
#   XFAIL  todo conflito é de um símbolo em pending.txt (esperado hoje)
#   FAIL   qualquer outro erro, ou conflito de símbolo que não está pendente
# Sai com 1 se houver FAIL. Também sai com 1 quando um símbolo pendente está
# declarado no header C e em map2check.h mas NÃO conflita (passou sem querer):
# atualize docs/runtime-abi/pending.txt (marcado como FAIL "pendente já conforme").
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
export LC_ALL=C
DIR="${1:?uso: check-signatures.sh <vendor-header-dir> [--pending F] [--rust-header F]}"; shift
PEND="$ROOT/docs/runtime-abi/pending.txt"
RH="$ROOT/include/map2check.h"
while [ $# -gt 0 ]; do
  case "$1" in
    --pending) PEND="$2"; shift 2 ;;
    --rust-header) RH="$2"; shift 2 ;;
    *) echo "opção desconhecida: $1" >&2; exit 2 ;;
  esac
done
[ -d "$DIR" ] && [ -f "$PEND" ] && [ -f "$RH" ] || { echo "entrada ausente" >&2; exit 2; }
DIR="$(cd "$DIR" && pwd)"; RH="$(cd "$(dirname "$RH")" && pwd)/$(basename "$RH")"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
rc=0
declares() { grep -qE "(^|[^A-Za-z0-9_])$2[[:space:]]*\(" "$1"; }

for h in "$DIR"/*.h; do
  name="$(basename "$h")"
  printf '#define ViolatedProperty C_ViolatedProperty\n#include "%s"\n#undef ViolatedProperty\n#include "%s"\n' "$h" "$RH" > "$T/u.c"
  clang -fsyntax-only -Werror -I"$DIR" "$T/u.c" > "$T/diag" 2>&1
  status=$?
  sed -nE "s/.*error: conflicting types for '([^']+)'.*/\1/p" "$T/diag" | sort -u > "$T/conf"
  grep -E 'error:' "$T/diag" | grep -v 'conflicting types for' > "$T/other" || true
  bad=""
  if [ -s "$T/other" ]; then bad="erro que não é conflito de tipos"; fi
  unexpected="$(comm -23 "$T/conf" "$PEND" | tr '\n' ' ')"
  [ -n "$unexpected" ] && bad="$bad conflito fora de pending: $unexpected"
  # pendente declarado nos dois headers mas sem conflito
  stale=""
  while read -r s; do
    [ -n "$s" ] || continue
    if declares "$h" "$s" && declares "$RH" "$s" && ! grep -qx "$s" "$T/conf"; then
      stale="$stale$s "
    fi
  done < "$PEND"
  [ -n "$stale" ] && bad="$bad pendente já conforme (tire de pending.txt): $stale"
  if [ -n "$bad" ]; then
    echo "FAIL  $name:$bad"; sed 's/^/        /' "$T/other" | head -5; rc=1
  elif [ -s "$T/conf" ]; then
    echo "XFAIL $name: $(tr '\n' ' ' < "$T/conf")"
  elif [ "$status" -ne 0 ]; then
    echo "FAIL  $name: clang falhou"; head -5 "$T/diag"; rc=1
  else
    echo "PASS  $name"
  fi
done
exit $rc
