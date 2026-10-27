#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Teste de scripts/package-release.sh (issue #5). Requer cargo, clang e nm.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/scripts/package-release.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0
ok() { echo "ok - $1"; }
bad() { echo "FAIL - $1"; fail=1; }

VERSION="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/Cargo.toml" | head -n1)"
NAME="map2check-library-$VERSION-$(rustc -vV | sed -n 's/^host: //p')"

# CHANGELOG sem a versão atual: falha antes de compilar, citando a versão
printf '# Changelog\n\n## [0.0.0] - 2000-01-01\n' > "$TMP/CHANGELOG.md"
rc=0; out="$(CHANGELOG_FILE="$TMP/CHANGELOG.md" "$PKG" "$TMP/bad" 2>&1)" || rc=$?
if [ "$rc" -ne 0 ] && grep -qF "## [$VERSION]" <<<"$out"; then ok "recusa CHANGELOG sem a versão"; else bad "CHANGELOG sem a versão (rc=$rc out=$out)"; fi
if [ -z "$(ls -A "$TMP/bad" 2>/dev/null)" ]; then ok "nada gravado quando recusa"; else bad "gravou arquivos ao recusar"; fi

# Pacote real
"$PKG" "$TMP/dist" >/dev/null
if [ -f "$TMP/dist/$NAME.tar.gz" ]; then ok "nome do arquivo"; else bad "arquivo $NAME.tar.gz ausente: $(ls "$TMP/dist")"; fi
if (cd "$TMP/dist" && sha256sum -c --quiet SHA256SUMS); then ok "SHA256SUMS confere"; else bad "SHA256SUMS"; fi

expected="$(printf '%s\n' \
  "$NAME/" "$NAME/CHANGELOG.md" "$NAME/LICENSE" \
  "$NAME/docs/" "$NAME/docs/api-deltas.md" "$NAME/docs/integration-guide.md" "$NAME/docs/semantic-deltas.md" \
  "$NAME/include/" "$NAME/include/map2check.h" \
  "$NAME/lib/" "$NAME/lib/libmap2check.a" "$NAME/lib/libmap2check_runtime.a" | LC_ALL=C sort)"
actual="$(tar -tzf "$TMP/dist/$NAME.tar.gz" | LC_ALL=C sort)"
if [ "$actual" = "$expected" ]; then ok "conteúdo exato"; else bad "conteúdo: $(diff <(echo "$expected") <(echo "$actual") || true)"; fi

mkdir -p "$TMP/x" && tar -xzf "$TMP/dist/$NAME.tar.gz" -C "$TMP/x"
P="$TMP/x/$NAME"
if grep -qxF "#define MAP2CHECK_VERSION \"$VERSION\"" "$P/include/map2check.h"; then ok "versão no header"; else bad "versão no header"; fi

# As duas bibliotecas exportam exatamente o ABI C do runtime (D6, 2.0.0).
# A saída do nm vai para variáveis: `nm | grep -q` com pipefail falha por SIGPIPE.
if "$ROOT/scripts/check-export-set.sh" --without-wasm --lib "$P/lib/libmap2check.a" >/dev/null; then ok "libmap2check.a exporta só o ABI C do runtime"; else bad "libmap2check.a: exports fora do ABI C"; fi
if "$ROOT/scripts/check-export-set.sh" --lib "$P/lib/libmap2check_runtime.a" >/dev/null; then ok "libmap2check_runtime.a exporta só o ABI C do runtime"; else bad "libmap2check_runtime.a: exports fora do ABI C"; fi
rt_syms="$(nm -g --defined-only "$P/lib/libmap2check_runtime.a" 2>/dev/null)"
if grep -q ' T __m2c_rt_wasm_allocate_memory$' <<<"$rt_syms"; then ok "runtime tem wasm"; else bad "runtime sem wasm"; fi

# Um programa C linka e roda só com o header e a biblioteca do pacote, mais
# o módulo IR que o Map2Check ligaria (gerado do repositório).
if "$ROOT/scripts/build-c-abi-program.sh" -o "$TMP/c/app" -m AnalysisModeMemtrack \
     --lib "$P/lib/libmap2check.a" -I "$P/include" "$ROOT/test/codeAPI_by_caller_test.c" \
   && "$TMP/c/app" >/dev/null; then ok "programa C linka e roda com o pacote"; else bad "programa C com o pacote"; fi

exit "$fail"
