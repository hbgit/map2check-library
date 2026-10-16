#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Monta o arquivo de release (issue #5): header C, as três bibliotecas
# estáticas (core, libfuzzer, runtime), guia de integração, docs de compatibilidade, CHANGELOG e LICENSE.
# Uso: scripts/package-release.sh [DIR_SAIDA]   (padrão: dist/)
# CHANGELOG_FILE sobrescreve o CHANGELOG verificado (usado pelo teste).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$(mkdir -p "${1:-$ROOT/dist}" && cd "${1:-$ROOT/dist}" && pwd)"
CHANGELOG_FILE="${CHANGELOG_FILE:-$ROOT/CHANGELOG.md}"

VERSION="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/Cargo.toml" | head -n1)"
TARGET="$(rustc -vV | sed -n 's/^host: //p')"
NAME="map2check-library-$VERSION-$TARGET"

die() { echo "package-release: $*" >&2; exit 1; }

[ -n "$VERSION" ] || die "versão não encontrada em Cargo.toml"
grep -q "^## \[$VERSION\]" "$CHANGELOG_FILE" \
  || die "CHANGELOG sem seção '## [$VERSION]': $CHANGELOG_FILE"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/$NAME/include" "$STAGE/$NAME/lib" "$STAGE/$NAME/docs"

cd "$ROOT"
cargo build --release --features libfuzzer
cp target/release/libmap2check.a "$STAGE/$NAME/lib/libmap2check_libfuzzer.a"
cargo build --release
cp target/release/libmap2check.a "$STAGE/$NAME/lib/libmap2check.a"
# The build Map2Check links: runtime profile (panic = unwind), libfuzzer + wasm.
# The KLEE bitcode needs rustc 1.72.1 and LLVM 16 (scripts/build-klee-runtime.sh)
# and is built separately; it is not part of this archive.
cargo build --profile runtime --features libfuzzer,wasm
cp target/runtime/libmap2check.a "$STAGE/$NAME/lib/libmap2check_runtime.a"
cp include/map2check.h "$STAGE/$NAME/include/"

grep -qxF "#define MAP2CHECK_VERSION \"$VERSION\"" "$STAGE/$NAME/include/map2check.h" \
  || die "include/map2check.h não define MAP2CHECK_VERSION \"$VERSION\""

cp docs/integration-guide.md docs/api-deltas.md docs/semantic-deltas.md "$STAGE/$NAME/docs/"
cp CHANGELOG.md LICENSE "$STAGE/$NAME/"

ARCHIVE="$NAME.tar.gz"
tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
  -C "$STAGE" -cf - "$NAME" | gzip -n > "$OUT/$ARCHIVE"
(cd "$OUT" && sha256sum "$ARCHIVE" > SHA256SUMS)
echo "$OUT/$ARCHIVE"
