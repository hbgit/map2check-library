#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Matriz de link do runtime: monta as 120 combinações de módulos que
# Caller::linkLLVM (vendor/map2check/modules/frontend/caller.cpp) passa ao
# llvm-link e confere cada uma sobre um programa de fumaça instrumentado.
#
# Uso: scripts/it/check-link-matrix.sh <lib-dir>
#   <lib-dir>  diretório com os 21 .bc do runtime (p.ex.
#              target/map2check-it/c/lib, ou a saída do build Rust)
#
# Combinações (2 x 5 x 3 x 2 x 2 = 120), na ordem do linkLLVM:
#   <prog>-output.bc Map2CheckFunctions TrackBBLog NonDetLog PropertyGenerator
#   container  array -> ContainerRealloc | btree -> ContainerBTree BTree
#   mode       memtrack   -> AnalysisModeMemtrack   AllocationLog ListLog HeapLog
#              memcleanup -> AnalysisModeMemcleanup AllocationLog ListLog HeapLog
#              overflow   -> AnalysisModeOverflow
#              assert     -> AnalysisModeAssert
#              none       -> AnalysisModeNone (alcance e cover-branches)
#   gen        none -> NonDetGeneratorNone | symex -> NonDetGeneratorKlee
#              afl  -> NonDetGeneratorAFL
#   wasm       1 -> WasmRuntimeStubs
#   witness    1 -> WitnessGeneration (o <hash>-witness-result.bc)
#              0 -> WitnessGenerationNone (o <hash>-result.bc)
#
# Critérios de cada combinação (todos dentro da imagem do Map2Check):
#   1. llvm-link-16 termina sem erro (p.ex. símbolo definido em dois módulos);
#   2. llvm-nm-16 --undefined-only do resultado contido na lista permitida:
#      símbolos definidos por libc.so.6/libm.so.6 da imagem e __dso_handle
#      (definido pelo crtbegin.o de todo executável; o std do Rust o
#      referencia como weak para os destrutores de thread_local), mais klee_*
#      para symex, __afl_* para afl e wasm_rt_* com wasm. Referências weak
#      contam como as fortes;
#   3. gen none: link nativo com clang-16; gen afl: link nativo com
#      afl-clang-fast -g -O2 ... -lm, como Caller::applyNonDetGenerator.
#
# Saída: uma linha por combinação,
#   PASS container=<c> mode=<m> gen=<g> wasm=<0|1> witness=<0|1>
#   FAIL container=... witness=<0|1> <critério>: <detalhe>
# e por último "matrix: PASS" (exit 0) ou "matrix: FAIL" (exit 1). Uso
# inválido ou ambiente ausente: exit 2.
#
# Programa de fumaça (Ruling R2 da Task 1.1): scripts/it/smoke/link-smoke.c,
# instrumentado pelo próprio Map2Check instalado (M2C_INSTALL) uma vez por
# modo, guardando o <hash>-output.bc em SMOKE_DIR/<modo>-output.bc. É gerado
# na primeira execução e refeito quando o fonte, a instalação ou o commit do
# develop mudam (SMOKE_DIR/stamp).
#
# Variáveis de ambiente:
#   IMAGE        padrão map2check-dev:develop-<commit12>
#   M2C_INSTALL  padrão target/map2check-it/c
#   SMOKE_DIR    padrão target/map2check-it/smoke
#   JOBS         combinações em paralelo (padrão: nproc)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
[ $# -eq 1 ] || { echo "uso: $0 <lib-dir>" >&2; exit 2; }
[ -d "$1" ] || { echo "$1: diretório inexistente" >&2; exit 2; }
LIB="$(cd "$1" && pwd)"

commit="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION")"
IMAGE="${IMAGE:-map2check-dev:develop-${commit:0:12}}"
M2C_INSTALL="${M2C_INSTALL:-$ROOT/target/map2check-it/c}"
SMOKE_DIR="${SMOKE_DIR:-$ROOT/target/map2check-it/smoke}"
SMOKE_SRC="$ROOT/scripts/it/smoke/link-smoke.c"
JOBS="${JOBS:-$(nproc)}"
MODES="memtrack memcleanup overflow assert none"

command -v docker >/dev/null 2>&1 || { echo "docker ausente" >&2; exit 2; }
docker image inspect "$IMAGE" >/dev/null 2>&1 \
  || { echo "imagem $IMAGE ausente (rode scripts/it/build-map2check.sh --image-only)" >&2; exit 2; }

mode_flags() {
  case "$1" in
    memtrack) echo "--memtrack" ;;
    memcleanup) echo "--memcleanup-property" ;;
    overflow) echo "--check-overflow" ;;
    assert) echo "--check-asserts" ;;
    none) echo "--target-function --target-function-name reach_error" ;;
  esac
}

# --- programa de fumaça, um <hash>-output.bc por modo -----------------------
stamp="$(cat "$SMOKE_SRC" "$M2C_INSTALL/bin/map2check" | sha256sum | cut -d' ' -f1) $commit"
need_smoke=0
[ "$(cat "$SMOKE_DIR/stamp" 2>/dev/null || true)" = "$stamp" ] || need_smoke=1
for m in $MODES; do [ -s "$SMOKE_DIR/$m-output.bc" ] || need_smoke=1; done
if [ "$need_smoke" -eq 1 ]; then
  [ -x "$M2C_INSTALL/bin/map2check" ] \
    || { echo "$M2C_INSTALL/bin/map2check ausente (rode scripts/it/build-map2check.sh)" >&2; exit 2; }
  echo "check-link-matrix: instrumentando $SMOKE_SRC com $M2C_INSTALL" >&2
  rm -rf "$SMOKE_DIR"
  mkdir -p "$SMOKE_DIR/work"
  cp "$SMOKE_SRC" "$SMOKE_DIR/work/link-smoke.c"
  for m in $MODES; do
    # O gerador não muda o -output.bc (Caller::callPass não depende dele);
    # symex só porque é o que termina sozinho.
    docker run --rm --network none --user "$(id -u):$(id -g)" -e HOME=/work \
      -v "$M2C_INSTALL:/opt/m2c:ro" -v "$SMOKE_DIR/work:/work" -w /work "$IMAGE" bash -c '
        rm -rf ./*.map2check
        /opt/m2c/bin/map2check --debug --nondet-generator symex --timeout 10 $1 link-smoke.c > /work/m2c.log 2>&1 || true
        cp ./*.map2check/*.map2check-output.bc /work/out.bc
      ' run "$(mode_flags "$m")" \
      || { echo "falha ao instrumentar o programa de fumaça no modo $m (veja $SMOKE_DIR/work/m2c.log)" >&2; exit 2; }
    mv "$SMOKE_DIR/work/out.bc" "$SMOKE_DIR/$m-output.bc"
  done
  rm -rf "$SMOKE_DIR/work"
  echo "$stamp" > "$SMOKE_DIR/stamp"
fi

# --- a matriz ---------------------------------------------------------------
# Uma linha por combinação, na ordem do produto.
combos=""
for ct in array btree; do
  for m in $MODES; do
    for g in none symex afl; do
      for wa in 0 1; do
        for wi in 0 1; do
          combos+="$ct $m $g $wa $wi"$'\n'
        done
      done
    done
  done
done

INNER='
set -uo pipefail
cd /tmp
{ nm -D --defined-only /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libm.so.6 \
    | awk "{print \$NF}" | sed "s/@.*//"; echo __dso_handle; } | sort -u > /tmp/allowed-libc.txt
one() {
  local idx="$1" ct="$2" m="$3" g="$4" wa="$5" wi="$6" L=/lib-dir d mods out err und pat
  d="/tmp/c$idx"; mkdir -p "$d"
  out="$d/out.txt"
  local name="container=$ct mode=$m gen=$g wasm=$wa witness=$wi"
  mods="/smoke/$m-output.bc $L/Map2CheckFunctions.bc $L/TrackBBLog.bc $L/NonDetLog.bc $L/PropertyGenerator.bc"
  case "$ct" in
    array) mods+=" $L/ContainerRealloc.bc" ;;
    btree) mods+=" $L/ContainerBTree.bc $L/BTree.bc" ;;
  esac
  case "$m" in
    memtrack) mods+=" $L/AnalysisModeMemtrack.bc $L/AllocationLog.bc $L/ListLog.bc $L/HeapLog.bc" ;;
    memcleanup) mods+=" $L/AnalysisModeMemcleanup.bc $L/AllocationLog.bc $L/ListLog.bc $L/HeapLog.bc" ;;
    overflow) mods+=" $L/AnalysisModeOverflow.bc" ;;
    assert) mods+=" $L/AnalysisModeAssert.bc" ;;
    none) mods+=" $L/AnalysisModeNone.bc" ;;
  esac
  case "$g" in
    none) mods+=" $L/NonDetGeneratorNone.bc" ;;
    symex) mods+=" $L/NonDetGeneratorKlee.bc" ;;
    afl) mods+=" $L/NonDetGeneratorAFL.bc" ;;
  esac
  [ "$wa" = 1 ] && mods+=" $L/WasmRuntimeStubs.bc"
  if [ "$wi" = 1 ]; then mods+=" $L/WitnessGeneration.bc"; else mods+=" $L/WitnessGenerationNone.bc"; fi
  # shellcheck disable=SC2086
  if ! llvm-link-16 $mods -o "$d/r.bc" 2> "$d/link.err"; then
    err="$(grep -m1 "error" "$d/link.err" || head -n1 "$d/link.err")"
    echo "FAIL $name llvm-link: $err" > "$out"; return
  fi
  pat="^$"
  case "$g" in symex) pat="$pat|^klee_" ;; afl) pat="$pat|^__afl_" ;; esac
  [ "$wa" = 1 ] && pat="$pat|^wasm_rt_"
  und="$(llvm-nm-16 --undefined-only "$d/r.bc" | awk "{print \$NF}" | sort -u \
    | comm -23 - /tmp/allowed-libc.txt | grep -Ev "$pat" | tr "\n" " " | sed "s/ $//")"
  if [ -n "$und" ]; then
    echo "FAIL $name undefined: $und" > "$out"; return
  fi
  case "$g" in
    none)
      if ! clang-16 -g "$d/r.bc" -lm -o "$d/a.out" > "$d/native.err" 2>&1; then
        err="$(grep -m1 -E "error|undefined reference" "$d/native.err" || head -n1 "$d/native.err")"
        echo "FAIL $name native-link(clang-16): $err" > "$out"; return
      fi ;;
    afl)
      if ! AFL_QUIET=1 afl-clang-fast -g -O2 "$d/r.bc" -o "$d/a.out" -lm > "$d/native.err" 2>&1; then
        err="$(grep -m1 -E "error|undefined reference" "$d/native.err" || head -n1 "$d/native.err")"
        echo "FAIL $name native-link(afl-clang-fast): $err" > "$out"; return
      fi ;;
  esac
  echo "PASS $name" > "$out"
  rm -f "$d/r.bc" "$d/a.out"
}
export -f one
nl -ba -w1 -s" " /combos.txt | xargs -P "$JOBS" -L1 bash -c "one \"\$@\"" one
i=1
while [ -f "/tmp/c$i/out.txt" ]; do cat "/tmp/c$i/out.txt"; i=$((i + 1)); done
'

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
printf '%s' "$combos" > "$tmp/combos.txt"
docker run --rm --network none --user "$(id -u):$(id -g)" -e HOME=/tmp -e JOBS="$JOBS" \
  -v "$LIB:/lib-dir:ro" -v "$SMOKE_DIR:/smoke:ro" -v "$tmp/combos.txt:/combos.txt:ro" \
  "$IMAGE" bash -c "$INNER" > "$tmp/result.txt"

cat "$tmp/result.txt"
total="$(grep -cE '^(PASS|FAIL) ' "$tmp/result.txt" || true)"
passed="$(grep -c '^PASS ' "$tmp/result.txt" || true)"
if [ "$total" -eq 120 ] && [ "$passed" -eq 120 ]; then
  echo "matrix: PASS"
  exit 0
fi
[ "$total" -eq 120 ] || echo "check-link-matrix: $total resultados, esperados 120" >&2
echo "matrix: FAIL"
exit 1
