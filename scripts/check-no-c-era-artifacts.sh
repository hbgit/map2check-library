#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Falha se algum arquivo rastreado for artefato de build/IDE/doc da era C
# (issue #27). Uso: check-no-c-era-artifacts.sh [--stdin]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Um padrão ERE por linha, aplicado ao caminho relativo à raiz.
PATTERNS='(^|/)\.clangd$
(^|/)compile_commands\.json$
(^|/)\.travis\.yml$
(^|/)\.vscode/
(^|/)Doxyfile$
\.xmi$
^docs/imgs/class-diagram\.png$
(^|/)CMakeLists\.txt$
\.cmake$
(^|/)build\.sh$
(^|/)run_klee_test\.sh$'

case "${1:-}" in
  "") list="$(git -C "$ROOT" -c core.quotePath=false ls-files)" ;;
  --stdin) list="$(cat)" ;;
  *) echo "uso: $0 [--stdin]" >&2; exit 2 ;;
esac

hits="$(grep -E -f <(printf '%s\n' "$PATTERNS") <<<"$list" || true)"
if [ -n "$hits" ]; then
  while IFS= read -r p; do echo "C-era artifact: $p" >&2; done <<<"$hits"
  exit 1
fi
