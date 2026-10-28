#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Monta o arquivo de release (issue #5): header C, as duas bibliotecas
# estáticas (core, runtime), guia de integração, docs de compatibilidade, CHANGELOG e LICENSE.
# Desde a 2.0.0 (D6) as bibliotecas exportam só o ABI C do runtime do
# Map2Check; os 21 módulos IR que o completam (lib/*.bc) vêm de
# scripts/build-runtime-bc.sh. O pacote leva ainda MAP2CHECK_VERSION (commit do
# develop validado) e um SHA256SUMS interno que cobre todos os outros arquivos.
# Reprodutível: mesma entrada, mesmo tarball (ordem, mtime, dono e gzip -n fixos).
# Uso: scripts/package-release.sh [DIR_SAIDA]   (padrão: dist/)
# CHANGELOG_FILE sobrescreve o CHANGELOG verificado (usado pelo teste).
# BC_DIR é um diretório já gerado por build-runtime-bc.sh (exatamente os 21 .bc);
# sem BC_DIR o script roda build-runtime-bc.sh (precisa da imagem Docker do
# Map2Check ou das ferramentas LLVM 16). MAP2CHECK_VERSION_FILE sobrescreve
# vendor/MAP2CHECK_VERSION (usado pelo teste).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$(mkdir -p "${1:-$ROOT/dist}" && cd "${1:-$ROOT/dist}" && pwd)"
CHANGELOG_FILE="${CHANGELOG_FILE:-$ROOT/CHANGELOG.md}"

VERSION="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/Cargo.toml" | head -n1)"
TARGET="$(rustc -vV | sed -n 's/^host: //p')"
NAME="map2check-library-$VERSION-$TARGET"

# The 21 module names: one list for the package, its test and the overlay.
MODULES="$(tr '
' ' ' < "$ROOT/scripts/runtime-modules.txt")"
M2C_VERSION_FILE="${MAP2CHECK_VERSION_FILE:-$ROOT/vendor/MAP2CHECK_VERSION}"

die() { echo "package-release: $*" >&2; exit 1; }

[ -n "$VERSION" ] || die "versão não encontrada em Cargo.toml"
grep -q "^## \[$VERSION\]" "$CHANGELOG_FILE" \
  || die "CHANGELOG sem seção '## [$VERSION]': $CHANGELOG_FILE"

[ -f "$M2C_VERSION_FILE" ] || die "arquivo de versão do Map2Check ausente: $M2C_VERSION_FILE"
grep -Eq '^commit=[0-9a-f]{40}$' "$M2C_VERSION_FILE" \
  || die "$M2C_VERSION_FILE sem linha commit=<sha de 40 hex>"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

if [ -z "${BC_DIR:-}" ]; then
  BC_DIR="$STAGE/bc"
  "$ROOT/scripts/build-runtime-bc.sh" "$BC_DIR" >&2 || die "build-runtime-bc.sh falhou"
fi
# Exatamente os 21 módulos, nada a mais, nada a menos.
want="$(for m in $MODULES; do echo "$m.bc"; done | LC_ALL=C sort)"
have="$(ls -A "$BC_DIR" 2>/dev/null | LC_ALL=C sort)"
[ "$want" = "$have" ] || die "BC_DIR=$BC_DIR não tem exatamente os 21 .bc: $(diff <(echo "$want") <(echo "$have") | tr '\n' ' ')"
for m in $MODULES; do [ -f "$BC_DIR/$m.bc" ] || die "$BC_DIR/$m.bc não é arquivo regular"; done

mkdir -p "$STAGE/$NAME/include" "$STAGE/$NAME/lib" "$STAGE/$NAME/docs"

cd "$ROOT"
# The staticlibs embed source paths (panic locations, debug info): remap the
# repository and the cargo registry to fixed prefixes, so the tarball does
# not depend on (or leak) the builder's home directory and checkout path.
# Own target directory: the RUSTFLAGS would otherwise rebuild target/release.
CARGO_HOME_DIR="${CARGO_HOME:-$HOME/.cargo}"
export RUSTFLAGS="--remap-path-prefix=$ROOT=/src --remap-path-prefix=$CARGO_HOME_DIR/registry/src=/cargo/registry/src --remap-path-prefix=$CARGO_HOME_DIR/git/checkouts=/cargo/git/checkouts"
export CARGO_TARGET_DIR="$ROOT/target/package-release"
cargo build --locked --release
cp "$CARGO_TARGET_DIR/release/libmap2check.a" "$STAGE/$NAME/lib/libmap2check.a"
# Runtime profile (panic = unwind) with the wasm2c entry points.
cargo build --locked --profile runtime --features wasm
cp "$CARGO_TARGET_DIR/runtime/libmap2check.a" "$STAGE/$NAME/lib/libmap2check_runtime.a"
cp include/map2check.h "$STAGE/$NAME/include/"
for m in $MODULES; do cp "$BC_DIR/$m.bc" "$STAGE/$NAME/lib/$m.bc"; done
cp "$M2C_VERSION_FILE" "$STAGE/$NAME/MAP2CHECK_VERSION"

grep -qxF "#define MAP2CHECK_VERSION \"$VERSION\"" "$STAGE/$NAME/include/map2check.h" \
  || die "include/map2check.h não define MAP2CHECK_VERSION \"$VERSION\""

cp docs/integration-guide.md docs/api-deltas.md docs/semantic-deltas.md "$STAGE/$NAME/docs/"
cp "$CHANGELOG_FILE" "$STAGE/$NAME/CHANGELOG.md"
cp LICENSE "$STAGE/$NAME/"

# SHA256SUMS interno: todos os outros arquivos, em ordem fixa, caminhos relativos.
find "$STAGE/$NAME" -type d -exec chmod 755 {} +
find "$STAGE/$NAME" -type f -exec chmod 644 {} +
(cd "$STAGE/$NAME" && find . -type f | LC_ALL=C sort | sed 's|^\./||' \
  | xargs sha256sum > "$STAGE/SHA256SUMS.tmp")
mv "$STAGE/SHA256SUMS.tmp" "$STAGE/$NAME/SHA256SUMS"
chmod 644 "$STAGE/$NAME/SHA256SUMS"

ARCHIVE="$NAME.tar.gz"
tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
  -C "$STAGE" -cf - "$NAME" | gzip -n > "$OUT/$ARCHIVE"
(cd "$OUT" && sha256sum "$ARCHIVE" > SHA256SUMS)
echo "$OUT/$ARCHIVE"
