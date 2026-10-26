#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Teste de scripts/it/build-map2check.sh: constrói o Map2Check develop a partir
# da cópia somente leitura em vendor/map2check e confere o resultado real.
#
# Pesado (build de imagem Docker com KLEE/Clam; dezenas de minutos na primeira
# vez, depois usa cache). NÃO está ligado ao CI do GitHub.
# Sem docker, termina com código 77 (skip).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VENDOR="$ROOT/vendor/map2check"
INSTALL="$ROOT/target/map2check-it/c"
fail=0
ok() { echo "ok - $1"; }
bad() { echo "FAIL - $1"; fail=1; }

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "SKIP: docker indisponível" >&2
  exit 77
fi

[ -d "$VENDOR" ] || { echo "FAIL - vendor/map2check ausente (rode scripts/fetch-map2check.sh)"; exit 1; }

manifest() { (cd "$VENDOR" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum); }
before="$(manifest | sha256sum)"

"$ROOT/scripts/it/build-map2check.sh" || bad "build-map2check.sh terminou com erro"

after="$(manifest | sha256sum)"
[ "$before" = "$after" ] && ok "manifesto sha256 de vendor/map2check inalterado" \
  || bad "vendor/map2check foi modificado pelo build"

[ -x "$INSTALL/bin/map2check" ] && ok "bin/map2check instalado" || bad "bin/map2check ausente"

commit12="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION" | cut -c1-12)"
IMG="map2check-dev:develop-${commit12}-time"
modules="Map2CheckFunctions TrackBBLog NonDetLog PropertyGenerator ContainerRealloc ContainerBTree BTree AnalysisModeMemtrack AnalysisModeMemcleanup AnalysisModeOverflow AnalysisModeAssert AnalysisModeNone AllocationLog ListLog HeapLog NonDetGeneratorNone NonDetGeneratorKlee NonDetGeneratorAFL WasmRuntimeStubs WitnessGeneration WitnessGenerationNone"
n=0
for m in $modules; do
  n=$((n + 1))
  [ -f "$INSTALL/lib/$m.bc" ] || bad "lib/$m.bc ausente"
done
[ "$n" -eq 21 ] && ok "21 módulos esperados verificados" || bad "contagem de módulos $n != 21"

out="$(docker run --rm --user "$(id -u):$(id -g)" -v "$INSTALL/lib:/lib-it:ro" "$IMG" \
  bash -c 'for m in '"$modules"'; do llvm-dis-16 "/lib-it/$m.bc" -o /dev/null || echo "BAD $m"; done' 2>&1)" || true
if [ -z "$out" ]; then ok "llvm-dis-16 lê os 21 .bc"; else bad "llvm-dis-16: $out"; fi

exit $fail
