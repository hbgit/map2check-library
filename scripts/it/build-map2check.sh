#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Constrói o Map2Check develop a partir da cópia somente leitura em vendor/map2check.
#
# Uso: scripts/it/build-map2check.sh [--image-only]
#   Imagens: map2check-dev:develop-<commit12> (vendor/map2check/Dockerfile.dev) e
#            map2check-dev:develop-<commit12>-time (+ /usr/bin/time, scripts/it/Dockerfile.time).
#   Build:   target/map2check-it/build   Instalação: target/map2check-it/c
# A cópia é montada com :ro; nada é escrito em vendor/map2check.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VENDOR="$ROOT/vendor/map2check"
OUT="$ROOT/target/map2check-it"

image_only=0
case "${1:-}" in
  "") ;;
  --image-only) image_only=1 ;;
  *) echo "uso: $0 [--image-only]" >&2; exit 2 ;;
esac

commit="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION")"
[ ${#commit} -ge 12 ] || { echo "commit ausente em vendor/MAP2CHECK_VERSION" >&2; exit 1; }
commit12="${commit:0:12}"
BASE="map2check-dev:develop-${commit12}"
TIME_IMG="${BASE}-time"

if ! docker image inspect "$BASE" >/dev/null 2>&1; then
  docker build -t "$BASE" -f "$VENDOR/Dockerfile.dev" "$VENDOR"
fi
if ! docker image inspect "$TIME_IMG" >/dev/null 2>&1; then
  docker build -t "$TIME_IMG" --build-arg "BASE=$BASE" -f "$ROOT/scripts/it/Dockerfile.time" "$ROOT/scripts/it"
fi
[ "$image_only" -eq 0 ] || exit 0

mkdir -p "$OUT/home"
rm -rf "$OUT/build" "$OUT/c"
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/out/home \
  -v "$VENDOR:/src:ro" -v "$OUT:/out" "$BASE" bash -euc '
    cmake -S /src -B /out/build -G Ninja \
      -DLLVM_DIR=/usr/lib/llvm-16/lib/cmake/llvm \
      -DCMAKE_INSTALL_PREFIX=/out/c
    ninja -C /out/build
    cmake --install /out/build --prefix /out/c
    # O Map2Check instala o binário na raiz do prefixo (release/map2check);
    # bin/map2check é o caminho acordado com os testes de integração.
    ln -sf ../map2check /out/c/bin/map2check
  '
