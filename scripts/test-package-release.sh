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
  "$NAME/lib/" "$NAME/lib/libmap2check.a" "$NAME/lib/libmap2check_libfuzzer.a" | LC_ALL=C sort)"
actual="$(tar -tzf "$TMP/dist/$NAME.tar.gz" | LC_ALL=C sort)"
if [ "$actual" = "$expected" ]; then ok "conteúdo exato"; else bad "conteúdo: $(diff <(echo "$expected") <(echo "$actual") || true)"; fi

mkdir -p "$TMP/x" && tar -xzf "$TMP/dist/$NAME.tar.gz" -C "$TMP/x"
P="$TMP/x/$NAME"
if grep -qxF "#define MAP2CHECK_VERSION \"$VERSION\"" "$P/include/map2check.h"; then ok "versão no header"; else bad "versão no header"; fi

# Biblioteca sem features: sem LLVMFuzzerTestOneInput; a de libfuzzer o define.
# A saída do nm vai para variáveis: `nm | grep -q` com pipefail falha por SIGPIPE.
core_syms="$(nm -g --defined-only "$P/lib/libmap2check.a" 2>/dev/null)"
fuzz_syms="$(nm -g --defined-only "$P/lib/libmap2check_libfuzzer.a" 2>/dev/null)"
if grep -q ' T map2check_init$' <<<"$core_syms" && ! grep -q ' T LLVMFuzzerTestOneInput$' <<<"$core_syms"; then ok "core sem LLVMFuzzerTestOneInput"; else bad "core: símbolos inesperados"; fi
if grep -q ' T LLVMFuzzerTestOneInput$' <<<"$fuzz_syms"; then ok "libfuzzer define LLVMFuzzerTestOneInput"; else bad "libfuzzer sem LLVMFuzzerTestOneInput"; fi

# Um programa C comum linka e roda só com o conteúdo do pacote
mkdir -p "$TMP/c/include" && cp "$P/include/map2check.h" "$TMP/c/include/"
sed 's|"../include/map2check.h"|"map2check.h"|' "$ROOT/test/codeAPI_by_caller_test.c" > "$TMP/c/main.c"
if clang -I "$TMP/c/include" "$TMP/c/main.c" "$P/lib/libmap2check.a" -ldl -lpthread -lm -o "$TMP/c/app" \
   && "$TMP/c/app" >/dev/null; then ok "programa C linka e roda com o pacote"; else bad "programa C com o pacote"; fi

exit "$fail"
