#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Roda o frontend do Map2Check de uma instalação sobre o corpus de regressão
# SV-COMP e grava uma linha por execução num TSV de 11 colunas.
#
# Uso: scripts/it/run-corpus.sh <install-dir> <out.tsv>
#   <install-dir>  instalação do Map2Check (bin/map2check + lib/), p.ex.
#                  target/map2check-it/c ou a cópia com os .bc do Rust.
#   <out.tsv>      task prp gen rep verdict tag line function witness wall_s maxrss_kb
#
# Variáveis de ambiente:
#   REPS=5                      repetições de cada (task, prp, gen)
#   GENERATORS="afl symex hybrid"
#       afl    -> --nondet-generator afl
#       symex  -> --nondet-generator symex
#       hybrid -> sem --nondet-generator (o padrão 9.0 alterna AFL++/KLEE e
#                 exige --timeout, que é sempre passado)
#   TIMEOUT_S=45                valor de --timeout. 45 s é o timelimit de
#       tests/regression_test/xml_doc_benchexec/map2check_regression_test.xml,
#       o XML do BenchExec que o próprio projeto usa para ESTE corpus (o de
#       10 s é a variante reduzida do Travis; o de 120 s é para o
#       sv-benchmarks completo).
#   KILL_MARGIN_S=30            o processo é morto por `timeout -k 10` em
#       TIMEOUT_S + KILL_MARGIN_S segundos (75 s por padrão). --timeout só
#       limita as fases de análise; compilação, instrumentação, ligação e a
#       geração do witness ficam fora dele (uma execução híbrida de 45 s levou
#       ~40 s de parede no total). Execução morta pelo limite externo grava
#       verdict TIMEOUT (exit 124 do timeout, ou 137 após o SIGKILL).
#   TASKS=""                    lista de tarefas (caminho do .yml relativo ao
#       corpus, sem .yml); vazio = todas as 39.
#   CORPUS                      padrão: vendor/map2check/tests/regression_test/
#                               test_cases/sv-benchmarks (montado :ro)
#   IMAGE                       padrão: map2check-dev:develop-<commit12>-time
#   RUNS_DIR                    padrão: target/map2check-it/runs/<out>-<data>
#
# Mapeamento propriedade (.prp) -> opções do Map2Check. Segue
# utils/map2check-wrapper.py e utils/map2check-wrapper-reg-test.py do Map2Check
# (o wrapper do tool-info do BenchExec, utils/moduleBenchExec/map2check.py),
# que escolhem o modo pelo conteúdo do .prp:
#   valid-memsafety  (valid-free/deref/memtrack) -> --memtrack --generate-witness
#   valid-memcleanup                             -> --memcleanup-property --generate-witness
#   unreach-call     (G ! call(__VERIFIER_error())) -> --target-function --generate-witness
#   no-overflow                                  -> --check-overflow --generate-witness
#   termination, coverage-*, def-behavior        -> não suportadas ("Unsupported
#       Property" no wrapper): o par (task, prp) não é executado.
# Diferenças em relação aos wrappers, e por quê:
#   * --add-invariants (unreach-call) fica de fora: exige Clam, ausente deste
#     build; o Map2Check sai com 3. É o comando de reserva do próprio wrapper
#     (command_line_bkp), usado quando as invariantes falham.
#   * --smt-solver yices2 fica de fora: o KLEE 3.1 da imagem develop não tem
#     backend metaSMT ("Did you mean '--solver-backend=yices2'?") e todo run
#     symex terminaria UNKNOWN em 0,1 s. Vale o padrão do Map2Check (z3), como
#     no ramo memsafety do wrapper de regressão.
#   * --check-asserts não corresponde a nenhum .prp do SV-COMP.
#
# Cada (task, prp, gen, rep) roda num diretório novo sob RUNS_DIR, dentro da
# imagem -time (/usr/bin/time -f '%e %M' dá wall_s e maxrss_kb), como o usuário
# do host, com a instalação em /opt/m2c:ro e o corpus em /corpus:ro.
# Ordem: repetição mais externa, para espalhar ruído de máquina entre as chaves.
# Colunas do TSV:
#   verdict  SUCCEEDED | FAILED | UNKNOWN (última linha "VERIFICATION ..." da
#            saída; o híbrido imprime uma por fase) | TIMEOUT (limite externo)
#            | ERROR (nenhuma linha de veredito)
#   tag      só em FAILED: texto da linha da propriedade violada até o primeiro
#            ':' (FALSE-FREE, FALSE-DEREF, FALSE-MEMTRACK, FALSE-MEMCLEANUP,
#            FALSE para "FALSE: Target Reached", OVERFLOW, ...)
#   line, function  só em FAILED: de "file X line N function F" (vazios quando
#            o Map2Check não imprime essa linha, p.ex. FALSE-MEMTRACK)
#   witness  1 se witness.graphml foi gerado no diretório da execução, senão 0
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
[ $# -eq 2 ] || { echo "uso: $0 <install-dir> <out.tsv>" >&2; exit 2; }
INSTALL="$(cd "$1" && pwd)"
OUT="$2"
[ -x "$INSTALL/bin/map2check" ] || { echo "$INSTALL/bin/map2check ausente" >&2; exit 2; }

REPS="${REPS:-5}"
GENERATORS="${GENERATORS:-afl symex hybrid}"
TIMEOUT_S="${TIMEOUT_S:-45}"
KILL_MARGIN_S="${KILL_MARGIN_S:-30}"
TASKS="${TASKS:-}"
CORPUS="$(cd "${CORPUS:-$ROOT/vendor/map2check/tests/regression_test/test_cases/sv-benchmarks}" && pwd)"
commit="$(sed -n 's/^commit=//p' "$ROOT/vendor/MAP2CHECK_VERSION")"
IMAGE="${IMAGE:-map2check-dev:develop-${commit:0:12}-time}"
stamp="$(date +%Y%m%d-%H%M%S)"
RUNS_DIR="${RUNS_DIR:-$ROOT/target/map2check-it/runs/$(basename "$OUT" .tsv)-$stamp}"
OUTER_S=$((TIMEOUT_S + KILL_MARGIN_S))

docker image inspect "$IMAGE" >/dev/null 2>&1 \
  || { echo "imagem $IMAGE ausente (rode scripts/it/build-map2check.sh --image-only)" >&2; exit 2; }

prp_flags() {
  case "$1" in
    valid-memsafety) echo "--memtrack --generate-witness" ;;
    valid-memcleanup) echo "--memcleanup-property --generate-witness" ;;
    unreach-call) echo "--target-function --generate-witness" ;;
    no-overflow) echo "--check-overflow --generate-witness" ;;
    *) return 1 ;;
  esac
}

gen_flags() {
  case "$1" in
    afl) echo "--nondet-generator afl" ;;
    symex) echo "--nondet-generator symex" ;;
    hybrid) echo "" ;;
    *) echo "gerador desconhecido: $1" >&2; exit 2 ;;
  esac
}

# Lista "task<TAB>input<TAB>prp" de todos os pares suportados.
pairs() {
  local yml task dir input prp
  while IFS= read -r yml; do
    task="${yml#"$CORPUS"/}"; task="${task%.yml}"
    if [ -n "$TASKS" ] && ! printf ' %s ' $TASKS | grep -qF " $task "; then continue; fi
    dir="$(dirname "$task")"
    input="$(sed -n "s/^input_files:[[:space:]]*['\"]\{0,1\}\([^'\"]*\)['\"]\{0,1\}[[:space:]]*$/\1/p" "$yml")"
    [ -n "$input" ] || { echo "$yml: input_files ausente" >&2; exit 1; }
    sed -n 's/^[[:space:]]*-[[:space:]]*property_file:[[:space:]]*\(.*\)$/\1/p' "$yml" |
      while IFS= read -r p; do
        prp="$(basename "$p" .prp)"
        prp_flags "$prp" >/dev/null || continue
        printf '%s\t%s\t%s\n' "$task" "$dir/$input" "$prp"
      done
  done < <(find "$CORPUS" -name '*.yml' | LC_ALL=C sort)
}

# Lê out.txt/rc.txt/time.txt/witness.graphml de um diretório de execução e
# imprime "verdict\ttag\tline\tfunction\twitness\twall_s\tmaxrss_kb".
parse_run() {
  local d="$1" rc verdict tag="" line="" func="" witness=0 wall=0 rss=0 clean prop
  rc="$(cat "$d/rc.txt" 2>/dev/null || echo 255)"
  clean="$(sed 's/\x1b\[[0-9;]*m//g' "$d/out.txt" 2>/dev/null || true)"
  verdict="$(printf '%s\n' "$clean" | sed -n 's/^VERIFICATION \(SUCCEEDED\|FAILED\|UNKNOWN\)[[:space:]]*$/\1/p' | tail -n1)"
  if [ "$rc" = 124 ] || [ "$rc" = 137 ]; then
    verdict=TIMEOUT
  elif [ -z "$verdict" ]; then
    verdict=ERROR
  fi
  if [ "$verdict" = FAILED ]; then
    # Bloco da última "Violated property:"; linhas seguintes com TAB inicial.
    prop="$(printf '%s\n' "$clean" | awk '/^Violated property:/{b=""; on=1; next} on && /^\t/{b=b $0 "\n"; next} on{on=0} END{printf "%s", b}')"
    if printf '%s\n' "$prop" | grep -q '^	file .* line [0-9-]* function '; then
      line="$(printf '%s\n' "$prop" | sed -n 's/^	file .* line \([0-9-]*\) function \(.*\)$/\1/p' | head -n1)"
      func="$(printf '%s\n' "$prop" | sed -n 's/^	file .* line \([0-9-]*\) function \(.*\)$/\2/p' | head -n1 | sed 's/[[:space:]]*$//')"
    fi
    tag="$(printf '%s\n' "$prop" | grep -v '^	file .* line ' | head -n1 | sed 's/^\t//; s/:.*$//; s/[[:space:]]*$//')"
  fi
  [ -f "$d/witness.graphml" ] && witness=1
  if [ -s "$d/time.txt" ]; then
    read -r wall rss < <(tail -n1 "$d/time.txt")
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$verdict" "$tag" "$line" "$func" "$witness" "$wall" "$rss"
}

mapfile -t PAIRS < <(pairs)
[ ${#PAIRS[@]} -gt 0 ] || { echo "nenhum par (task, prp) selecionado" >&2; exit 1; }
total=$(( ${#PAIRS[@]} * $(wc -w <<<"$GENERATORS") * REPS ))
echo "run-corpus: ${#PAIRS[@]} pares x [$GENERATORS] x $REPS reps = $total execuções; TIMEOUT_S=$TIMEOUT_S, limite externo ${OUTER_S}s; imagem $IMAGE; runs em $RUNS_DIR" >&2

mkdir -p "$RUNS_DIR" "$(dirname "$OUT")"
printf 'task\tprp\tgen\trep\tverdict\ttag\tline\tfunction\twitness\twall_s\tmaxrss_kb\n' > "$OUT"

n=0
for rep in $(seq 1 "$REPS"); do
  for pair in "${PAIRS[@]}"; do
    IFS=$'\t' read -r task input prp <<<"$pair"
    for gen in $GENERATORS; do
      n=$((n + 1))
      d="$RUNS_DIR/${task//\//__}__${prp}__${gen}__r${rep}"
      rm -rf "$d"; mkdir -p "$d"
      flags="$(gen_flags "$gen") --timeout $TIMEOUT_S $(prp_flags "$prp")"
      name="m2c-it-$$-$n"
      # Rede de segurança no host: se o container não terminar após o limite
      # externo + 60 s, é morto (docker run --rm o remove).
      timeout -k 5 $((OUTER_S + 60)) docker run --rm --name "$name" --network none \
        --user "$(id -u):$(id -g)" -e HOME=/work \
        -v "$INSTALL:/opt/m2c:ro" -v "$CORPUS:/corpus:ro" -v "$d:/work" -w /work \
        "$IMAGE" bash -c '
          /usr/bin/time -f "%e %M" -o /work/time.txt \
            timeout -k 10 "$1" /opt/m2c/bin/map2check $2 "/corpus/$3" > out.txt 2> err.txt
          echo $? > rc.txt
        ' run "$OUTER_S" "$flags" "$input" >/dev/null 2>&1 \
        || docker kill "$name" >/dev/null 2>&1 || true
      res="$(parse_run "$d")"
      printf '%s\t%s\t%s\t%s\t%s\n' "$task" "$prp" "$gen" "$rep" "$res" >> "$OUT"
      # Só os artefatos usados pelo parser ficam; o resto (KLEE, AFL++) é grande.
      find "$d" -mindepth 1 -maxdepth 1 ! -name out.txt ! -name err.txt ! -name rc.txt \
        ! -name time.txt ! -name witness.graphml -exec rm -rf {} + 2>/dev/null || true
      echo "[$n/$total] $task $prp $gen r$rep: $(cut -f1,6 <<<"$res" | tr '\t' ' ')s" >&2
    done
  done
done
