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
# Valores de enum: a tag do C é renomeada na unidade (o Rust redefine o enum),
# então tests/abi/enum-map.tsv liga cada enumerador C ao do Rust e uma unidade
# gerada tem um _Static_assert por par. Enquanto `enum:<Tag>` estiver em
# docs/runtime-abi/pending-enums.txt, valores diferentes dão XFAIL; valores
# iguais com o marcador ainda presente dão FAIL (a task dona remove o marcador),
# e valores diferentes sem marcador dão FAIL. Rust `Concurrency` não tem
# contraparte no C e fica fora do mapa.
# map2check_check_deref não é declarada em nenhum header do runtime C: só a
# guarda de cobertura (runtime-abi-coverage.sh) a cobre. PASS sem símbolos
# compartilhados (n=0) é vácuo: nada em map2check.h ainda corresponde ao header.
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
EMAP="$ROOT/tests/abi/enum-map.tsv"
PENUM="$ROOT/docs/runtime-abi/pending-enums.txt"
while [ $# -gt 0 ]; do
  case "$1" in
    --pending) PEND="$2"; shift 2 ;;
    --rust-header) RH="$2"; shift 2 ;;
    --enum-map) EMAP="$2"; shift 2 ;;
    --pending-enums) PENUM="$2"; shift 2 ;;
    *) echo "opção desconhecida: $1" >&2; exit 2 ;;
  esac
done
[ -d "$DIR" ] && [ -f "$PEND" ] && [ -f "$RH" ] && [ -f "$EMAP" ] && [ -f "$PENUM" ] || { echo "entrada ausente" >&2; exit 2; }
DIR="$(cd "$DIR" && pwd)"; RH="$(cd "$(dirname "$RH")" && pwd)/$(basename "$RH")"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
rc=0
declares() { grep -qE "(^|[^A-Za-z0-9_])$2[[:space:]]*\(" "$1"; }

for h in "$DIR"/*.h; do
  name="$(basename "$h")"
  tags="$(awk -F'\t' 'NR>1 {print $1}' "$EMAP" | sort -u)"
  { for t in $tags; do echo "#define $t C_$t"; done
    echo "#include \"$h\""
    for t in $tags; do echo "#undef $t"; done
    echo "#include \"$RH\""; } > "$T/u.c"
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
  # valores de enum
  enote=""; exfail=0
  for t in $tags; do
    grep -qE "enum[[:space:]]+$t[[:space:]]*\\{" "$h" || continue
    { echo "#define $t C_$t"; echo "#include \"$h\""; echo "#undef $t"; echo "#include \"$RH\"";
      awk -F'\t' -v t="$t" 'NR>1 && $1==t {printf "_Static_assert((int)%s == (int)%s, \"enum %s: %s != %s\");\n", $2, $3, t, $2, $3}' "$EMAP"; } > "$T/e.c"
    nbad="$(clang -fsyntax-only -Werror -I"$DIR" "$T/e.c" 2>&1 | grep -c 'static assertion failed\|static_assert failed' || true)"
    if grep -qx "enum:$t" "$PENUM"; then
      if [ "$nbad" -gt 0 ]; then enote="$enote [enum $t: $nbad valores diferem, pendente]"; exfail=1
      else bad="$bad marcador enum:$t em pending-enums.txt mas os valores já batem (remova o marcador);"; fi
    elif [ "$nbad" -gt 0 ]; then bad="$bad enum $t: $nbad valores diferem do Rust sem marcador em pending-enums.txt;"
    fi
  done
  nshared=0
  for s in $(grep -oE '[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(' "$h" | tr -d ' \t(' | sort -u); do
    declares "$RH" "$s" && nshared=$((nshared+1))
  done
  if [ -n "$bad" ]; then
    echo "FAIL  $name:$bad"; sed 's/^/        /' "$T/other" | head -5; rc=1
  elif [ -s "$T/conf" ]; then
    echo "XFAIL $name: $(tr '\n' ' ' < "$T/conf")$enote"
  elif [ "$exfail" = 1 ]; then
    echo "XFAIL $name:$enote"
  elif [ "$status" -ne 0 ]; then
    echo "FAIL  $name: clang falhou"; head -5 "$T/diag"; rc=1
  else
    echo "PASS  $name (n=$nshared símbolos compartilhados)"
  fi
done
exit $rc
