#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Teste offline de scripts/fetch-map2check.sh (fixture local via file://).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FETCH="$ROOT/scripts/fetch-map2check.sh"
fail=0
ok() { echo "ok - $1"; }
bad() { echo "FAIL - $1"; fail=1; }

# O destino precisa ficar dentro do repositório (o script recusa o resto).
mkdir -p "$ROOT/target"
WORK="$(mktemp -d "$ROOT/target/test-fetch-map2check.XXXXXX")"
FIX="$(mktemp -d)"
trap 'rm -rf "$WORK" "$FIX"' EXIT

G() { git -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false -c protocol.file.allow=always "$@"; }

# Submódulo
G init -q -b main "$FIX/sub"
echo sub > "$FIX/sub/sub.txt"
G -C "$FIX/sub" add . && G -C "$FIX/sub" commit -q -m sub

# Superprojeto: develop (com submódulo) e other (HEAD do remoto)
G init -q -b develop "$FIX/super"
echo dev > "$FIX/super/file.txt"
G -C "$FIX/super" add . && G -C "$FIX/super" commit -q -m "develop commit"
G -C "$FIX/super" submodule add -q "file://$FIX/sub" modules/sub
G -C "$FIX/super" commit -q -m "add submodule"
DEV="$(G -C "$FIX/super" rev-parse HEAD)"
G -C "$FIX/super" checkout -q -b other
echo other > "$FIX/super/file.txt"
G -C "$FIX/super" commit -q -a -m "other commit"
export MAP2CHECK_URL="file://$FIX/super"

DEST="$WORK/vendor/map2check"
VER="$WORK/vendor/MAP2CHECK_VERSION"

# Sem submódulos
rc=0; "$FETCH" "$DEST" >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 0 ] && ok "download sai 0" || bad "download sai 0 (rc=$rc)"
[ "$(cat "$DEST/file.txt" 2>/dev/null)" = dev ] && ok "clona develop mesmo com other como HEAD" || bad "clona develop"
[ -z "$(find "$DEST" -name .git 2>/dev/null)" ] && ok "nenhum .git sobra" || bad "nenhum .git sobra"
missing=""
for k in url branch commit commit_date commit_subject fetched; do
  grep -q "^$k=." "$VER" 2>/dev/null || missing="$missing $k"
done
[ -z "$missing" ] && ok "MAP2CHECK_VERSION tem as 6 chaves" || bad "chaves ausentes:$missing"
[ "$(sed -n 's/^commit=//p' "$VER")" = "$DEV" ] && ok "commit igual ao develop" || bad "commit igual ao develop"
[ "$(sed -n 's/^branch=//p' "$VER")" = develop ] && ok "branch=develop" || bad "branch=develop"
[ -z "$(ls -A "$DEST/modules/sub" 2>/dev/null)" ] && ok "submódulo vazio sem --with-submodules" || bad "submódulo vazio"

# Segundo download substitui o destino
echo stale > "$DEST/stale.txt"
"$FETCH" "$DEST" >/dev/null 2>&1 || true
[ ! -e "$DEST/stale.txt" ] && [ "$(cat "$DEST/file.txt")" = dev ] && ok "segundo download substitui o destino" || bad "segundo download substitui"

# Com submódulos
"$FETCH" --with-submodules "$DEST" >/dev/null 2>&1 || true
[ "$(cat "$DEST/modules/sub/sub.txt" 2>/dev/null)" = sub ] && ok "--with-submodules traz o submódulo" || bad "--with-submodules"
[ -z "$(find "$DEST" -name .git 2>/dev/null)" ] && ok "nenhum .git com submódulos" || bad "nenhum .git com submódulos"

# Destino fora do repositório
OUT="$(mktemp -d)"
rc=0; "$FETCH" "$OUT/m2c" >/dev/null 2>&1 || rc=$?
if [ "$rc" -ne 0 ] && [ ! -e "$OUT/m2c" ]; then ok "destino fora do repositório recusado"; else bad "destino fora recusado (rc=$rc)"; fi
rm -rf "$OUT"
rc=0; "$FETCH" "$ROOT/../x" >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] && ok "destino com .. recusado" || bad "destino com .. recusado"
rc=0; "$FETCH" "$ROOT" >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] && [ -d "$ROOT/.git" ] && ok "raiz do repositório recusada" || bad "raiz recusada"

exit "$fail"
