#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Falha se algum arquivo rastreado for artefato de build/IDE/doc da era C
# (issue #27). Uso: check-no-c-era-artifacts.sh [--stdin]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Um padrão ERE por linha, aplicado ao caminho relativo à raiz.
PATTERNS='(^|/)\.clangd(/|$)
(^|/)compile_commands\.json$
(^|/)\.travis\.yml$
(^|/)\.vscode/
(^|/)Doxyfile$
\.xmi$
^docs/imgs/class-diagram\.png$
(^|/)CMakeLists\.txt$
\.cmake$
(^|/)build\.sh$
(^|/)run_klee_test\.sh$
(^|/)run_libfuzzer_test\.sh$'

case "${1:-}" in
  "") list="$(git -C "$ROOT" ls-files -z | tr '\0' '\n')" ;;
  --stdin) list="$(cat)" ;;
  *) echo "uso: $0 [--stdin]" >&2; exit 2 ;;
esac

# grep: 0 = achou ofensores, 1 = limpo, >1 = erro interno
rc=0
hits="$(grep -E -f <(printf '%s\n' "$PATTERNS") <<<"$list")" || rc=$?
if [ "$rc" -gt 1 ]; then
  echo "erro: grep falhou (status $rc)" >&2
  exit 2
fi
if [ -n "$hits" ]; then
  while IFS= read -r p; do echo "C-era artifact: $p" >&2; done <<<"$hits"
  exit 1
fi
