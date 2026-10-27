#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Teste de scripts/package-release.sh (issue #5, Task 3.2). Requer cargo, clang e nm.
# Os 21 módulos .bc vêm de, em ordem:
#   BC_DIR=<dir>        saída pronta de scripts/build-runtime-bc.sh (modo real);
#   FIXTURE_BC=1        21 arquivos de mentira, sem Docker (checagem estrutural, CI);
#   nenhum dos dois     roda build-runtime-bc.sh; sem docker/imagem, sai com 77.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/scripts/package-release.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0
# The 21 module names: one list for the package, its test and the overlay.
MODULES="$(tr '
' ' ' < "$ROOT/scripts/runtime-modules.txt")"
ok() { echo "ok - $1"; }
bad() { echo "FAIL - $1"; fail=1; }

VERSION="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/Cargo.toml" | head -n1)"
NAME="map2check-library-$VERSION-$(rustc -vV | sed -n 's/^host: //p')"

# Origem dos .bc
real_bc=0
if [ -n "${BC_DIR:-}" ]; then
  real_bc=1
elif [ "${FIXTURE_BC:-0}" = 1 ]; then
  BC_DIR="$TMP/bc"; mkdir -p "$BC_DIR"
  for m in $MODULES; do printf 'placeholder %s\n' "$m" > "$BC_DIR/$m.bc"; done
else
  commit="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION")"
  IMAGE="${IMAGE:-map2check-dev:develop-${commit:0:12}}"
  if ! { command -v docker >/dev/null 2>&1 && docker image inspect "$IMAGE" >/dev/null 2>&1; }; then
    echo "SKIP: build real dos .bc precisa de docker e da imagem $IMAGE (use BC_DIR ou FIXTURE_BC=1)" >&2
    exit 77
  fi
  BC_DIR="$TMP/bc"; "$ROOT/scripts/build-runtime-bc.sh" "$BC_DIR" >/dev/null; real_bc=1
fi
export BC_DIR

# CHANGELOG sem a versão atual: falha antes de compilar, citando a versão
printf '# Changelog\n\n## [0.0.0] - 2000-01-01\n' > "$TMP/CHANGELOG.md"
rc=0; out="$(CHANGELOG_FILE="$TMP/CHANGELOG.md" "$PKG" "$TMP/bad" 2>&1)" || rc=$?
if [ "$rc" -ne 0 ] && grep -qF "## [$VERSION]" <<<"$out"; then ok "recusa CHANGELOG sem a versão"; else bad "CHANGELOG sem a versão (rc=$rc out=$out)"; fi
if [ -z "$(ls -A "$TMP/bad" 2>/dev/null)" ]; then ok "nada gravado quando recusa"; else bad "gravou arquivos ao recusar"; fi

# BC_DIR incompleto ou com arquivo a mais: recusa, nada gravado
cp -r "$BC_DIR" "$TMP/bc20" && rm "$TMP/bc20/TrackBBLog.bc"
rc=0; out="$(BC_DIR="$TMP/bc20" "$PKG" "$TMP/bad20" 2>&1)" || rc=$?
if [ "$rc" -ne 0 ] && grep -qF "TrackBBLog.bc" <<<"$out"; then ok "recusa BC_DIR com 20 módulos"; else bad "BC_DIR com 20 (rc=$rc)"; fi
cp -r "$BC_DIR" "$TMP/bc22" && : > "$TMP/bc22/Extra.bc"
rc=0; out="$(BC_DIR="$TMP/bc22" "$PKG" "$TMP/bad22" 2>&1)" || rc=$?
if [ "$rc" -ne 0 ] && grep -qF "Extra.bc" <<<"$out"; then ok "recusa BC_DIR com módulo extra"; else bad "BC_DIR com extra (rc=$rc)"; fi

# Pacote real
"$PKG" "$TMP/dist" >/dev/null
if [ -f "$TMP/dist/$NAME.tar.gz" ]; then ok "nome do arquivo"; else bad "arquivo $NAME.tar.gz ausente: $(ls "$TMP/dist")"; fi
if (cd "$TMP/dist" && sha256sum -c --quiet SHA256SUMS); then ok "SHA256SUMS confere"; else bad "SHA256SUMS"; fi

expected="$(printf '%s\n' \
  "$NAME/" "$NAME/CHANGELOG.md" "$NAME/LICENSE" "$NAME/MAP2CHECK_VERSION" "$NAME/SHA256SUMS" \
  "$NAME/docs/" "$NAME/docs/api-deltas.md" "$NAME/docs/integration-guide.md" "$NAME/docs/semantic-deltas.md" \
  "$NAME/include/" "$NAME/include/map2check.h" \
  "$NAME/lib/" "$NAME/lib/libmap2check.a" "$NAME/lib/libmap2check_runtime.a" \
  $(for m in $MODULES; do echo "$NAME/lib/$m.bc"; done) | LC_ALL=C sort)"
actual="$(tar -tzf "$TMP/dist/$NAME.tar.gz" | LC_ALL=C sort)"
if [ "$actual" = "$expected" ]; then ok "conteúdo exato"; else bad "conteúdo: $(diff <(echo "$expected") <(echo "$actual") || true)"; fi

mkdir -p "$TMP/x" && tar -xzf "$TMP/dist/$NAME.tar.gz" -C "$TMP/x"
P="$TMP/x/$NAME"
if grep -qxF "#define MAP2CHECK_VERSION \"$VERSION\"" "$P/include/map2check.h"; then ok "versão no header"; else bad "versão no header"; fi

# MAP2CHECK_VERSION = o do vendor; SHA256SUMS interno cobre todos os outros arquivos
if cmp -s "$P/MAP2CHECK_VERSION" "$ROOT/vendor/MAP2CHECK_VERSION" \
   && grep -Eq '^commit=[0-9a-f]{40}$' "$P/MAP2CHECK_VERSION"; then ok "MAP2CHECK_VERSION com o commit validado"; else bad "MAP2CHECK_VERSION"; fi
if (cd "$P" && sha256sum -c --quiet SHA256SUMS); then ok "SHA256SUMS interno confere"; else bad "SHA256SUMS interno"; fi
listed="$(awk '{print $2}' "$P/SHA256SUMS" | LC_ALL=C sort)"
files="$(cd "$P" && find . -type f ! -name SHA256SUMS | sed 's|^\./||' | LC_ALL=C sort)"
if [ "$listed" = "$files" ]; then ok "SHA256SUMS cobre todos os outros arquivos"; else bad "cobertura do SHA256SUMS: $(diff <(echo "$files") <(echo "$listed") || true)"; fi
if [ "$(find "$P/lib" -name '*.bc' | wc -l)" = 21 ]; then ok "21 .bc em lib/"; else bad "contagem de .bc"; fi
for m in $MODULES; do cmp -s "$P/lib/$m.bc" "$BC_DIR/$m.bc" || bad "$m.bc difere da entrada"; done
if [ "$real_bc" = 1 ] && command -v llvm-dis-16 >/dev/null 2>&1; then
  rdok=1; for m in $MODULES; do llvm-dis-16 "$P/lib/$m.bc" -o /dev/null 2>/dev/null || { rdok=0; bad "llvm-dis-16 não lê $m.bc"; }; done
  [ "$rdok" = 1 ] && ok "llvm-dis-16 lê os 21 .bc"
fi

# O commit validado em docs/release.md é o de vendor/MAP2CHECK_VERSION
vc="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION")"
if grep -q "Map2Check .develop. commit .$vc." "$ROOT/docs/release.md" \
   && [ "$(grep -oE '[0-9a-f]{40}' "$ROOT/docs/release.md" | sort -u)" = "$vc" ]; then ok "docs/release.md cita o commit de vendor/MAP2CHECK_VERSION"; else bad "docs/release.md: commit validado difere de vendor/MAP2CHECK_VERSION ($vc)"; fi

# Instalação documentada: o overlay recebe o lib/ extraído do pacote (21 .bc
# mais os .a): os .a são ignorados, os 21 nomes continuam exigidos
mkdir -p "$TMP/ci/lib" "$TMP/ci/bin"
for m in $MODULES; do echo "C $m" > "$TMP/ci/lib/$m.bc"; done
if "$ROOT/scripts/it/overlay-install.sh" "$TMP/ci" "$P/lib" "$TMP/ov" >/dev/null 2>&1 \
   && (cd "$P" && for m in $MODULES; do cmp -s "lib/$m.bc" "$TMP/ov/lib/$m.bc"; done) \
   && [ "$(ls "$TMP/ov/lib" | wc -l)" = 21 ]; then ok "overlay aceita o lib/ do pacote e instala os 21 .bc"; else bad "overlay com o lib/ do pacote"; fi
mkdir "$TMP/lib19" && cp "$P"/lib/*.bc "$P"/lib/*.a "$TMP/lib19/" && rm "$TMP/lib19/HeapLog.bc"
if "$ROOT/scripts/it/overlay-install.sh" "$TMP/ci" "$TMP/lib19" "$TMP/ov19" >/dev/null 2>&1; then bad "overlay aceitou lib/ sem um módulo"; else ok "overlay continua recusando lib/ sem um dos 21"; fi

# Reprodutível: segunda execução sobre as mesmas entradas, mesmo tarball byte a byte
"$PKG" "$TMP/dist2" >/dev/null
h1="$(sha256sum < "$TMP/dist/$NAME.tar.gz")"; h2="$(sha256sum < "$TMP/dist2/$NAME.tar.gz")"
if [ "$h1" = "$h2" ]; then ok "reprodutível: $h1"; else bad "não reprodutível: $h1 != $h2"; fi

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
