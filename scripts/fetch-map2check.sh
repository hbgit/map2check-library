#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Baixa o branch develop do Map2Check como cópia local sem versionamento.
#
# Uso: scripts/fetch-map2check.sh [--with-submodules] [<dest>]
#   <dest> padrão: vendor/map2check (precisa ficar dentro deste repositório).
#   MAP2CHECK_URL: padrão https://github.com/hbgit/Map2Check
# Escreve MAP2CHECK_VERSION (chave=valor) ao lado de <dest>.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
URL="${MAP2CHECK_URL:-https://github.com/hbgit/Map2Check}"
BRANCH=develop

submodules=0
dest=""
for arg in "$@"; do
  case "$arg" in
    --with-submodules) submodules=1 ;;
    -*) echo "uso: $0 [--with-submodules] [<dest>]" >&2; exit 2 ;;
    *) [ -z "$dest" ] || { echo "destino duplicado" >&2; exit 2; }; dest="$arg" ;;
  esac
done
dest="${dest:-$ROOT/vendor/map2check}"

DEST="$(realpath -m -- "$dest")"
case "$DEST" in
  "$ROOT"/*) ;;
  *) echo "destino fora do repositório: $DEST" >&2; exit 1 ;;
esac
[ "$DEST" != "$ROOT/.git" ] && case "$DEST" in "$ROOT/.git"/*) echo "destino dentro de .git" >&2; exit 1 ;; esac

PARENT="$(dirname "$DEST")"
VERSION_FILE="$PARENT/MAP2CHECK_VERSION"
mkdir -p "$PARENT"
TMP="$(mktemp -d "$PARENT/.fetch-map2check.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# file:// precisa liberar o protocolo para submódulos; https não é afetado.
gitopts=()
case "$URL" in file://*) gitopts=(-c protocol.file.allow=always) ;; esac
cloneopts=(--depth 1 --branch "$BRANCH")
[ "$submodules" -eq 1 ] && cloneopts+=(--recurse-submodules --shallow-submodules)

git "${gitopts[@]}" clone -q "${cloneopts[@]}" -- "$URL" "$TMP/src"

commit="$(git -C "$TMP/src" rev-parse HEAD)"
commit_subject="$(git -C "$TMP/src" log -1 --format=%s)"
fetched="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
commit_date="$(TZ=UTC git -C "$TMP/src" log -1 --format=%cd --date=format-local:%Y-%m-%dT%H:%M:%SZ)"

# .git pode ser diretório (repositório) ou arquivo (submódulo)
find "$TMP/src" -name .git -prune -exec rm -rf {} +

rm -rf "$DEST"
mv "$TMP/src" "$DEST"

{
  echo "url=$URL"
  echo "branch=$BRANCH"
  echo "commit=$commit"
  echo "commit_date=$commit_date"
  echo "commit_subject=$commit_subject"
  echo "fetched=$fetched"
} > "$TMP/version"
mv "$TMP/version" "$VERSION_FILE"
echo "Map2Check $BRANCH @ $commit em $DEST"
