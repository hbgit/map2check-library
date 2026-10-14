# Auditoria do plano Rust e abertura de issues — Plano de Execução

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Determinar, com evidência concreta, o status de cada item verificável de `docs/plano_map2check_library_rust.md` (issues, entregáveis, critérios de aceitação, DoD de M1–M8 e os 7 critérios da §3.4) e, após aprovação humana, abrir no GitHub issues não duplicadas para o que estiver `PENDENTE` ou `PARCIAL`.

**Architecture:** Pipeline em 4 fases com artefatos em `audit/`: (1) extração do checklist com IDs estáveis; (2) coleta de evidência bruta em `audit/evidence/` (logs de comandos, JSON do `gh`) e classificação item a item; (3) deduplicação contra issues/milestones/labels existentes e rascunho em `audit/issues_propostas.md` + `audit/create_issues.sh` (idempotente, dry-run por padrão); (4) **gate de aprovação humana**, depois criação via `gh` e registro dos números no checklist.

**Tech Stack:** `git`, `gh` (autenticado como `hbgit`), `cargo` (toolchain fixado por `rust-toolchain.toml`), `nm` (binutils, substituto local de `llvm-nm`), `docker`, `grep`/`awk`, `bash`.

**Spec:** `docs/plano_map2check_library_rust.md` (Fase 3, §3.1, §3.3, §3.4; tabelas §1.2(a) e §1.2(b) como fonte das listas de símbolos).

## Global Constraints

- **Repositório-alvo de todas as issues:** `hbgit/map2check-library` (inclusive M7/M8; a solicitação lista só este repositório). `hbgit/Map2Check` é apenas **lido** (clone raso no scratchpad / `gh api`) para obter evidência de M5/M7/M8; nada é criado nele.
- **Ref auditada:** `develop` em `a72f63e` (idêntico a `origin/master`). O SHA exato é registrado no cabeçalho do relatório. Trabalho que só existe em outras branches (`feature/rust` em `0d60baf`, `feat/M3_paridade`, `feat/update_rust`) ou em PRs abertos **não** conta como implementado: no máximo `PARCIAL`, citando branch/PR na evidência.
- **Somente leitura no código:** nenhum arquivo fora de `audit/` e deste plano é modificado. `cargo build`/`test` só escrevem em `target/` (ignorado). Verificar ao final de cada fase com `git status --porcelain -- . ':!audit' ':!docs/superpowers' ':!.claude'` → saída vazia.
- **Status permitidos:** `IMPLEMENTADO`, `PARCIAL`, `PENDENTE`, `NÃO VERIFICÁVEL` — cada um com justificativa de **uma linha**.
- **Regras de classificação:**
  1. Nunca `IMPLEMENTADO` só por nome de arquivo, presença de símbolo declarado ou comentário; exige conteúdo funcional **e** comando que o exercite (teste, build, `nm`, execução de CI).
  2. Na dúvida entre `PARCIAL` e `IMPLEMENTADO` → `PARCIAL`, explicando por quê.
  3. `NÃO VERIFICÁVEL` só quando o artefato **existe** mas checá-lo exige ambiente indisponível (KLEE, benchmark, regressão do Map2Check). Se o artefato não existe → `PENDENTE`.
  4. Verdade vacuosa não conta: item de remoção/ausência cujo pré-requisito nunca existiu (ex.: "remover `ffi_compat.rs`" sem M5 feito; "`grep static mut` vazio" porque o módulo sumiu) → `PENDENTE`.
  5. Critérios "verde no CI" exigem execução do GitHub Actions bem-sucedida no SHA auditado (ou no último push de `master`). Verde só localmente → `PARCIAL`.
  6. Divergência só de nome/caminho com função equivalente (ex.: `CI.yml` vs `ci.yml`, `test/` vs `tests/`) → `IMPLEMENTADO` com nota; divergência de conteúdo → `PARCIAL`.
- **Nenhum `gh issue create`, `gh issue comment`, `gh label create` ou criação de milestone antes da aprovação explícita do usuário (Task 11).**
- **Commits:** só se o usuário pedir; assinados (`git commit -S`) e **sem** atribuição de IA (CLAUDE.md do projeto).
- **Títulos de milestone:** exatamente os da §3.3 (ex.: `M1 — Restaurar build, CI e higiene`).
- **Labels do plano:** `area:ffi`, `area:build`, `area:ci`, `area:klee`, `area:fuzzing`, `area:memtrack`, `area:integration`, `kind:bug`, `kind:feature`, `kind:test`, `kind:docs`, `prio:critical`.
- **Chave de idempotência das issues:** primeira linha do corpo `Audit-ID: <ID>` (ex.: `Audit-ID: M2-I1`).

## Review Focus

1. **Falso `IMPLEMENTADO` por existência** (ex.: feature `klee` declarada no `Cargo.toml` sem nenhum `cfg(feature = "klee")`; `ffi.rs` com função de corpo vazio) → Tasks 4–7 exigem grep de conteúdo + comando; checagem na Task 8, Step 3.
2. **CI verde local mas vermelho no GitHub** (as 3 últimas execuções em `master` em 2026-10-14 falharam; CI usa `dtolnay/rust-toolchain@stable`) → Task 3 coleta o status por step; Task 4 aplica a regra 5.
3. **Issues duplicadas em reexecução do script** → `create_issues.sh` checa `Audit-ID` antes de criar; teste de idempotência na Task 12, Step 3.
4. **Verdade vacuosa** em itens de remoção (M1-I5, M2-AC3, M8-I5, M8-I6, M8-AC2) → regra 4; checagem na Task 8, Step 3.
5. **Truncamento de listagem `gh`** (default 30 itens) escondendo duplicata → Task 3 usa `--limit 1000` e compara com o total da API.

---

## Estrutura de arquivos

| Arquivo | Responsabilidade |
|---|---|
| `audit/checklist.md` | Fonte única dos itens: `ID | milestone | tipo | item | repo | status | coberto_por | issue` |
| `audit/evidence/*.log`, `*.json`, `*.txt` | Saída bruta dos comandos (referenciada pelo relatório) |
| `audit/relatorio_auditoria.md` | Tabelas por milestone (`ID | item | status | evidência | issue`), resumo §3.4, cobertura da matriz §3.1, metodologia |
| `audit/issues_propostas.md` | Rascunho legível de cada issue/comentário proposto |
| `audit/create_issues.sh` | Script idempotente (dry-run por padrão; `--apply` executa) |
| `audit/issues_criadas.md` | Lista final de links |

---

### Task 1: Preparação e fixação da ref

**Files:**
- Create: `audit/evidence/env.txt`

**Interfaces:**
- Produces: `AUDIT_SHA` (SHA completo de `develop`), diretório `audit/evidence/`.

- [ ] **Step 1: Confirmar ref e árvore limpa (exceto `.claude/`)**

```bash
cd /home/rock/Documents/Dev/map2check-library
git fetch --all --prune
git rev-parse develop origin/master feature/rust
git status --porcelain -- . ':!.claude'
```
Esperado: `develop` == `origin/master`; status vazio. Se `develop` ≠ `origin/master`, parar e perguntar ao usuário qual ref auditar.

- [ ] **Step 2: Registrar ambiente**

```bash
mkdir -p audit/evidence
{
  echo "date: $(date -Iseconds)"
  echo "AUDIT_SHA: $(git rev-parse develop)"
  echo "feature/rust: $(git rev-parse feature/rust)"
  git log -1 --format='commit: %H %s' develop
  rustc --version; cargo --version
  for t in cargo-deny cargo-audit cargo-tarpaulin llvm-nm nm docker klee hyperfine clang; do
    printf '%s: ' "$t"; command -v "$t" || echo MISSING
  done
  gh --version | head -1
} > audit/evidence/env.txt
cat audit/evidence/env.txt
```

- [ ] **Step 3: Diferença entre branches (contexto para regra de "outras branches")**

```bash
git log --oneline develop..feature/rust > audit/evidence/branch_feature_rust_ahead.txt
for b in origin/feat/M3_paridade origin/feat/update_rust; do
  echo "== $b"; git log --oneline develop..$b
done > audit/evidence/branches_other_ahead.txt
```

---

### Task 2: Extração do checklist

**Files:**
- Create: `audit/checklist.md`, `audit/evidence/symbols_core.txt`, `audit/evidence/symbols_compat.txt`

**Interfaces:**
- Produces: tabela `ID | milestone | tipo | item | repo | status | coberto_por | issue`; tipos `issue`, `entregável`, `critério`, `dod`, `global`. Esquema de IDs: `Mn-In`, `Mn-En`, `Mn-ACn`, `Mn-DoDn`, `G-n`.

- [ ] **Step 1: Escrever `audit/checklist.md`** com cabeçalho e exatamente estas linhas (status/coberto_por/issue vazios; `repo` = `hbgit/map2check-library` em todas; para M7/M8 adicionar na coluna item o sufixo `(evidência em hbgit/Map2Check)`):

| ID | item (resumo fiel ao plano) |
|---|---|
| M1-E1 | `.github/workflows/ci.yml` com build+test+clippy+fmt+deny+tarpaulin |
| M1-E2 | `Dockerfile` corrigido |
| M1-E3 | `rust-toolchain.toml` |
| M1-E4 | `build.rs` gerando `include/map2check.h` |
| M1-E5 | header commitado como artefato de release |
| M1-E6 | remoção de `.clangd/`, `compile_commands.json`, `.travis.yml`, `.vscode/` |
| M1-E7 | `README.md` atualizado |
| M1-I1..I6 | as 6 issues de M1, título literal do plano |
| M1-AC1 | `cargo build --release` verde no CI |
| M1-AC2 | `cargo test --all-features` verde no CI |
| M1-AC3 | `cargo clippy --all-targets --all-features -- -D warnings` verde no CI |
| M1-AC4 | `cargo fmt --check` verde no CI |
| M1-AC5 | `cargo deny check` verde no CI |
| M1-AC6 | `docker build .` conclui |
| M1-AC7 | header contém todos os símbolos de `ffi.rs`, checado por `nm`-diff no CI |
| M1-AC8 | cobertura tarpaulin ≥ 70% fora de `ffi.rs` |
| M1-DoD1 | CI verde obrigatório em PR |
| M1-DoD2 | branch protegida |
| M2-E1 | `ffi.rs` revisado |
| M2-E2 | `state.rs` novo |
| M2-E3 | teste de estresse "panic não escapa" (harness C, entradas hostis) |
| M2-I1..I6 | as 6 issues de M2 |
| M2-AC1 | harness C com `-fsanitize=address,undefined` executa 100% dos exports hostis e retorna 0 |
| M2-AC2 | duas iterações de `LLVMFuzzerTestOneInput` com containers idênticos e independentes (teste automatizado) |
| M2-AC3 | `grep -R "static mut" rust/src` vazio |
| M2-AC4 | clippy com lints anti-panic verde |
| M2-DoD1 | todos os exports com comentário SAFETY atualizado |
| M2-DoD2 | CHANGELOG |
| M3-E1 | `ffi.rs` completo |
| M3-E2 | header regenerado |
| M3-E3 | testes unitários por símbolo |
| M3-E4 | `test/*.c` migrados e compilados no CI |
| M3-I1..I6 | as 6 issues de M3 |
| M3-AC1 | diff `nm` vs §1.2(a) sem "Ausente" injustificado; exceções em `docs/api-deltas.md` |
| M3-AC2 | os 3 programas de `test/` compilam, linkam e passam no CI |
| M3-AC3 | cobertura ≥ 75% |
| M3-DoD1 | header versionado `v1.0.0-rc1` |
| M3-DoD2 | nenhuma função stub silenciosa |
| M4-E1 | `nondet/klee.rs` |
| M4-E2 | `cfg(feature="klee")` em `state`/`output` |
| M4-E3 | `scripts/build_klee_bc.sh` |
| M4-E4 | `docs/klee-feasibility.md` com go/no-go |
| M4-I1..I5 | as 5 issues de M4 |
| M4-AC1 | KLEE 3.1 roda `codeklee_by_caller_test` até o fim, ≥ 1 `.ktest` + resultado; **ou** relatório com causa-raiz e contingência §2.3 |
| M4-AC2 | tempo KLEE ≤ 2× biblioteca C, medido e registrado |
| M4-DoD1 | decisão go/no-go registrada e refletida no roadmap |
| M5-E1 | `rust/src/ffi_compat.rs` + feature `m2c-compat` (default on) |
| M5-E2 | golden files dos arquivos-sentinela |
| M5-E3 | `docs/compat-matrix.md` |
| M5-I1..I5 | as 5 issues de M5 |
| M5-AC1 | `llvm-nm libmap2check.a` contém 100% da §1.2(b) (script no CI; lista em `compat-matrix.md`) |
| M5-AC2 | 5 programas de referência: sentinelas aceitos pelo parser de `tools.cpp`, idênticos ao legado |
| M5-DoD1 | matriz de compat sem lacunas |
| M5-DoD2 | header compat separado gerado |
| M6-E1 | `tests/differential/` + workflow noturno |
| M6-E2 | `docs/semantic-deltas.md` |
| M6-E3 | relatório de benchmark |
| M6-I1..I5 | as 5 issues de M6 |
| M6-AC1 | 0 divergências não adjudicadas (≥ 30 programas) |
| M6-AC2 | overhead mediano ≤ 110% do C (excedente com perfil) |
| M6-AC3 | job noturno ativo |
| M6-DoD1 | `semantic-deltas.md` aprovado pelo mantenedor |
| M7-E1 | PR no `hbgit/Map2Check` (branch `feature/rust-runtime`) |
| M7-E2 | workflow atualizado |
| M7-E3 | doc de build |
| M7-I1..I4 | as 4 issues de M7 |
| M7-AC1 | `cmake .. -DMAP2CHECK_RUST_RUNTIME=ON && ninja` verde em `Dockerfile.dev` |
| M7-AC2 | paridade de vereditos 100% em `make-regression-test.sh t` |
| M7-AC3 | tempo da suíte Rust ≤ 110% da C |
| M7-DoD1 | PR aberto e revisável |
| M7-DoD2 | flag documentada |
| M8-I1..I6 | as 6 issues de M8 |
| M8-AC1 | regressão completa + run Test-Comp-like com 0 regressões vs. baseline C |
| M8-AC2 | compat e biblioteca C removidas sem `U map2check_*` órfão |
| M8-DoD1 | `feature/rust` mesclada |
| M8-DoD2 | release taggeada nos dois repositórios |
| M8-DoD3 | CHANGELOG e docs |
| G-1..G-7 | os 7 critérios da §3.4, texto literal |

Cada `Mn-Ik` vira uma linha própria com o título **literal** da issue no plano (ex.: `M1-I1 | ci: add GitHub Actions workflow (build, test, clippy -D warnings, rustfmt, cargo-deny/audit)`).

- [ ] **Step 2: Preencher `coberto_por`** — para entregável/critério/DoD que é inteiramente resolvido por uma issue do mesmo milestone, anotar o ID dessa issue. Mapeamento fixo:

```
M1-E1→M1-I1  M1-E2→M1-I2  M1-E3→M1-I3  M1-E4→M1-I4  M1-E5→M1-I4  M1-E6→M1-I5  M1-E7→M1-I5
M1-AC1..AC5→M1-I1  M1-AC6→M1-I2  M1-AC7→M1-I4
M2-E1→M2-I1  M2-E2→M2-I2  M2-E3→M2-I6  M2-AC1→M2-I6  M2-AC2→M2-I4  M2-AC3→M2-I4  M2-AC4→M2-I5
M3-E1→M3-I1  M3-E4→M3-I6  M3-AC2→M3-I6
M4-E1→M4-I1  M4-E2→M4-I2  M4-E3→M4-I3  M4-E4→M4-I5  M4-AC1→M4-I4  M4-DoD1→M4-I5
M5-E1→M5-I1  M5-E2→M5-I5  M5-AC2→M5-I5
M6-E1→M6-I1  M6-E2→M6-I2  M6-E3→M6-I4  M6-AC1→M6-I1  M6-AC2→M6-I4  M6-AC3→M6-I5
M7-E1→M7-I1  M7-E2→M7-I3  M7-E3→M7-I4  M7-AC1→M7-I1  M7-DoD2→M7-I4
M8-AC2→M8-I6  M8-DoD3→M8-I5
```
Itens sem mapeamento (ex.: `M1-AC8`, `M1-DoD1`, `M3-AC1`, `G-*`) poderão gerar issue própria na Task 9.

- [ ] **Step 3: Extrair listas de símbolos da §1.2**

`audit/evidence/symbols_core.txt` (um por linha, de §1.2(a), só itens com consumidor — exclui `debug_*_set_only_test` e `map2check_save_memtrack_log`, que o plano aceita como ausentes):
```
map2check_init
map2check_success
set_false_result
get_current_property
get_current_step
get_next_step
next_current_step
print_all_containers_as_json
vcc_reset_meta_data
map2check_set_memcleanup
map2check_set_null_is_valid
map2check_save_nondet_log_int
map2check_save_nondet_log_uint
map2check_save_nondet_log_long
map2check_save_nondet_log_char
map2check_save_nondet_log_float
map2check_save_nondet_log_double
map2check_save_basic_block_log
map2check_is_in_trackbb_container
map2check_map_alloca
map2check_map_non_static_alloca
map2check_map_funct_address
map2check_map_malloc
map2check_map_calloc
map2check_map_free
map2check_map_store_pointer
map2check_is_valid_assert
map2check_check_load
map2check_check_deref
map2check_check_free
map2check_check_free_resolved_address
map2check_check_mem_endprog
map2check_fuzzer_assume
LLVMFuzzerTestOneInput
```
Mais a família `map2check_binop_*`: gerar a lista de `ffi.rs` e anotar à parte (não é lacuna conhecida).

`audit/evidence/symbols_compat.txt` (§1.2(b), excluindo `map2check_wasm_*` fora de escopo):
```
map2check_init
map2check_track_bb
map2check_alloca
map2check_non_static_alloca
map2check_malloc
map2check_calloc
map2check_free
map2check_free_resolved_address
map2check_load
map2check_check_deref
map2check_add_store_pointer
map2check_function
map2check_target_function
map2check_posix
map2check_assume
map2check_assume_loop
map2check_crab_assume
map2check_assert
__VERIFIER_nondet_int
__VERIFIER_nondet_uint
__VERIFIER_nondet_char
__VERIFIER_nondet_long
__VERIFIER_nondet_ushort
__VERIFIER_nondet_pointer
__VERIFIER_assume
__VERIFIER_assert
__VERIFIER_error
```
Famílias `map2check_non_det_*`, `map2check_nondet_cast_*`, `map2check_pointer_cast`: expandir na Task 7, Step 1 (a partir de `NonDetPass.cpp`).

- [ ] **Step 4: Validar contagem**

```bash
for m in M1 M2 M3 M4 M5 M6 M7 M8 G; do
  printf '%s: ' $m; grep -cE "^\| $m-" audit/checklist.md
done
```
Esperado (após expandir `I1..In`, `AC1..ACn`, `G-1..G-7` em linhas próprias): M1 23, M2 15, M3 15, M4 12, M5 12, M6 12, M7 12, M8 11, G 7 (total 119). Se divergir, comparar com a Fase 3 do plano e corrigir antes de seguir.

---

### Task 3: Coleta de evidência bruta (comandos e GitHub)

**Files:**
- Create: `audit/evidence/{fmt,clippy,build,test,test_default,test_libfuzzer,deny,audit,docker_build,docker_test,nm_core,nm_all,header_syms,ffi_exports,ci_runs,ci_jobs,issues,prs,milestones,labels,protection,releases}.*`

**Interfaces:**
- Produces: arquivos de log citados como `evidence/<nome>:<linha>` no relatório; `rc` (exit code) gravado na última linha de cada `.log`.

- [ ] **Step 1: Comandos cargo locais (com exit code)**

```bash
cd /home/rock/Documents/Dev/map2check-library
run() { local n=$1; shift; { "$@"; echo "rc=$?"; } > audit/evidence/$n.log 2>&1; tail -1 audit/evidence/$n.log; }
run fmt            cargo fmt --check
run clippy         cargo clippy --all-targets --all-features -- -D warnings
run build          cargo build --release
run test           cargo test --all-features
run test_default   cargo test
run test_libfuzzer cargo test --features libfuzzer
```

- [ ] **Step 2: deny/audit** — ferramentas ausentes localmente. Perguntar ao usuário se pode `cargo install --locked cargo-deny cargo-audit` (instala em `~/.cargo/bin`, não toca o repo). Se sim:
```bash
run deny  cargo deny check
run audit cargo audit
```
Se não: registrar `rc=NA (ferramenta ausente)` e usar só o resultado do step do CI (Step 5).

- [ ] **Step 3: Docker (build final e estágio de testes/tarpaulin)**

```bash
{ docker build . ; echo "rc=$?"; } > audit/evidence/docker_build.log 2>&1
{ docker build --target test --progress=plain . ; echo "rc=$?"; } > audit/evidence/docker_test.log 2>&1
grep -nE '[0-9.]+% coverage|Coverage' audit/evidence/docker_test.log
grep -n -A8 'cargo tarpaulin' Dockerfile   # confirmar exclusão de ffi.rs
```

- [ ] **Step 4: Símbolos (nm em vez de llvm-nm)**

```bash
nm -g --defined-only target/release/libmap2check.a 2>/dev/null \
  | awk '$2=="T"{print $3}' | sort -u > audit/evidence/nm_all.txt
grep -B3 -E 'extern "C" fn' rust/src/ffi.rs \
  | grep -oE 'fn [A-Za-z_0-9]+' | awk '{print $2}' | sort -u > audit/evidence/ffi_exports.txt
grep -rhoE 'extern "C" fn [A-Za-z_0-9]+' rust/src | awk '{print $4}' | sort -u > audit/evidence/all_exports_src.txt
grep -oE '\b[A-Za-z_][A-Za-z_0-9]*\s*\(' include/map2check.h | tr -d ' (' | sort -u > audit/evidence/header_syms.txt
comm -23 audit/evidence/all_exports_src.txt audit/evidence/header_syms.txt > audit/evidence/missing_in_header.txt
comm -23 <(sort -u audit/evidence/symbols_core.txt)   audit/evidence/nm_all.txt > audit/evidence/missing_core.txt
comm -23 <(sort -u audit/evidence/symbols_compat.txt) audit/evidence/nm_all.txt > audit/evidence/missing_compat.txt
wc -l audit/evidence/missing_*.txt
```
Nota: `LLVMFuzzerTestOneInput` só aparece com `--features libfuzzer`; repetir o `nm` após `cargo build --release --features libfuzzer` em `nm_libfuzzer.txt` antes de considerá-lo ausente.

- [ ] **Step 5: CI do GitHub**

```bash
R=hbgit/map2check-library
gh run list -R $R --limit 50 --json databaseId,headSha,headBranch,event,status,conclusion,workflowName,createdAt > audit/evidence/ci_runs.json
SHA=$(git rev-parse develop)
RUN=$(jq -r --arg s "$SHA" '[.[]|select(.headSha==$s)][0].databaseId' audit/evidence/ci_runs.json)
gh run view -R $R "$RUN" --json jobs > audit/evidence/ci_jobs.json
jq -r '.jobs[].steps[]|"\(.conclusion)\t\(.name)"' audit/evidence/ci_jobs.json
gh run view -R $R "$RUN" --log-failed > audit/evidence/ci_failed.log 2>&1
ls .github/workflows/; grep -nE 'schedule|matrix|upload-artifact|tarpaulin|nm|features' .github/workflows/*
```
Se `RUN` vazio (nenhuma execução no SHA), usar a execução mais recente de `master` e anotar o SHA usado.

- [ ] **Step 6: Metadados do repositório (dedup e DoD)**

```bash
gh issue list -R $R --state all --limit 1000 --json number,title,state,body,milestone,labels,url > audit/evidence/issues.json
gh pr list    -R $R --state all --limit 1000 --json number,title,state,headRefName,mergedAt,url > audit/evidence/prs.json
gh api "repos/$R/milestones?state=all&per_page=100" > audit/evidence/milestones.json
gh label list -R $R --limit 500 --json name,color > audit/evidence/labels.json
for b in master develop feature/rust; do
  echo "== $b"; gh api "repos/$R/branches/$b/protection" 2>&1
done > audit/evidence/protection.txt
gh release list -R $R --limit 50 > audit/evidence/releases.txt; git tag -l > audit/evidence/tags.txt
jq length audit/evidence/issues.json
gh api "repos/$R" --jq '.open_issues_count'
gh api "search/issues?q=repo:$R+is:issue&per_page=1" --jq '.total_count'
```
Esperado: `jq length` == `total_count` da busca (Review Focus 5). Se menor, paginar com `gh api --paginate "repos/$R/issues?state=all"`.

- [ ] **Step 7: Confirmar somente leitura**

```bash
git status --porcelain -- . ':!audit' ':!docs/superpowers' ':!.claude'
```
Esperado: vazio.

---

### Task 4: Classificação M1 e M2

**Files:**
- Modify: `audit/checklist.md` (colunas status)
- Create: `audit/evidence/m1_m2_checks.log`

**Interfaces:**
- Consumes: logs da Task 3.
- Produces: status + justificativa de uma linha + evidência (`arquivo:linha`, `evidence/x.log`, run ID, PR/issue) para cada linha `M1-*`, `M2-*`.

- [ ] **Step 1: Rodar checagens de conteúdo (todas com `tee -a audit/evidence/m1_m2_checks.log`)**

| ID | Verificação | `IMPLEMENTADO` se |
|---|---|---|
| M1-I1/E1, AC1–AC5 | steps em `ci_jobs.json`; `grep -n tarpaulin .github/workflows/*` | workflow tem build/test/clippy/fmt/deny/audit **e** cada step `success` no SHA (regra 5). E1 exige também tarpaulin no workflow |
| M1-I2/E2, AC6 | `grep -n COPY Dockerfile`; `docker_build.log` rc | COPY usa `rust/src` e `test`; rc=0 |
| M1-I3/E3 | `cat rust-toolchain.toml`; `grep -nE '1\.(78|82)' README.md Dockerfile Cargo.toml .github/workflows/*` | toolchain fixado e MSRV consistente em README/Dockerfile/Cargo; CI não sobrescreve o toolchain |
| M1-I4/E4/E5 | `cat build.rs`; `cat cbindgen.toml`; `grep -n upload-artifact .github/workflows/*`; `releases.txt` | build.rs chama cbindgen e gera o header (E4); header publicado como artefato no CI (I4) / em release (E5) |
| M1-I5/E6/E7 | `git ls-files \| grep -E '^(\.clangd\|compile_commands\.json\|\.travis\.yml\|\.vscode)'`; `git ls-files '*.profraw'`; README cita Rust/cargo | lista vazia e README descreve o build Rust |
| M1-I6 | `grep -n matrix .github/workflows/*`; `test_default.log`, `test_libfuzzer.log` rc | matriz de features no CI e ambos rc=0 |
| M1-AC7 | `missing_in_header.txt`; `grep -n nm .github/workflows/*` | arquivo vazio **e** passo de diff no CI (sem passo no CI → `PARCIAL`) |
| M1-AC8 | `docker_test.log` cobertura | ≥ 70% com `ffi.rs` excluído; tarpaulin fora do CI → no máximo `PARCIAL` |
| M1-DoD1/2 | `protection.txt` | proteção com required status checks em `feature/rust` (ou `master`, se for a branch de integração — anotar) |
| M2-I1/E1 | `grep -c 'extern "C" fn' rust/src/ffi.rs` vs `grep -c catch_unwind rust/src/ffi.rs`; `grep -n 'panic' Cargo.toml` | todo export embrulhado, e o caso `panic=abort` tratado por `cfg` e documentado |
| M2-I2/E2 | `grep -nE 'OnceLock\|Arc<' rust/src/state.rs`; `grep -n NotInitialized rust/src` | `static Mutex` sem `OnceLock/Arc`; init idempotente com teste; `NotInitialized` inalcançável |
| M2-I3 | `grep -n map2check_reset rust/src/ffi.rs`; `nm_all.txt` | export existe, aparece no `nm` e há teste |
| M2-I4, AC2, AC3 | `grep -rn 'static mut' rust/src`; `grep -n FUZZER_DATA rust/src`; teste de duas iterações em `test_libfuzzer.log` | sem `static mut`, módulo ainda existe (regra 4), reset por iteração com teste nomeado |
| M2-I5, AC4 | `cat clippy.toml`; `grep -rnE 'deny\(clippy::(unwrap_used\|expect_used\|panic)' rust/src`; doc de `with_state` | lints ativos e `clippy.log` rc=0 |
| M2-I6/E3, AC1 | `grep -rln 'fsanitize' test .github Dockerfile`; harness C em `test/` | harness existe, cobre todos os exports e roda no CI com ASan/UBSan |
| M2-DoD1 | `grep -c 'unsafe' rust/src/ffi.rs` vs `grep -c 'SAFETY:' rust/src/ffi.rs` + leitura amostral | contagens compatíveis e comentários atuais |
| M2-DoD2 | `ls CHANGELOG*`; `git log --oneline -- CHANGELOG*` | CHANGELOG existe com entrada de M2 |

- [ ] **Step 2: Para cada issue de M1/M2, procurar PR/issue fechada correspondente** em `issues.json`/`prs.json` (por título) e citar o número na evidência.

- [ ] **Step 3: Escrever status no checklist** no formato `STATUS — justificativa (evidência)`. Ex.: `PARCIAL — workflow existe mas run 38632679269 falhou em <step> (evidence/ci_jobs.json)`.

---

### Task 5: Classificação M3

**Files:**
- Modify: `audit/checklist.md`
- Create: `audit/evidence/m3_checks.log`

- [ ] **Step 1: Checagens**

| ID | Verificação | `IMPLEMENTADO` se |
|---|---|---|
| M3-I1 | `grep -E 'map2check_map_(non_static_alloca\|funct_address)' audit/evidence/nm_all.txt` + teste nomeado | ambos no `nm` e com teste |
| M3-I2 | idem `map2check_check_free_resolved_address` | no `nm`, semântica conforme `AnalysisModeMemtrack.c` registrada, teste |
| M3-I3 | `grep -n -A6 'fn map2check_set_(memcleanup\|null_is_valid)' rust/src/ffi.rs`; `grep -rn 'is_null_valid' rust/src` | corpo altera estado **e** `LoadChecker` lê a flag (não mais `false` fixo); teste |
| M3-I4 | `nm` para `map2check_fuzzer_assume`, `__VERIFIER_assume/assert/error`, `__VERIFIER_nondet_{pointer,bool,uchar}` (build com `--features libfuzzer`) | todos presentes e testados |
| M3-I5 | `grep -nE 'save_nondet_log_char\|nondet_char' rust/src -r` | usa `c_char`/`i8`, não `u8` |
| M3-I6/E4, AC2 | `grep -nE 'map2check_gen_data_fuzzer' test/*.c`; passos no CI que compilam `test/*.c` | os 3 `.c` usam a API vigente e CI compila+linka+executa |
| M3-E1 | `missing_core.txt` | vazio exceto exceções em `docs/api-deltas.md` |
| M3-E2 | `missing_in_header.txt` | vazio |
| M3-E3 | para cada símbolo de `symbols_core.txt`: `grep -rn "<símbolo>" rust/src --include=*.rs \| grep -c test` | cada símbolo com ≥ 1 teste (listar os sem teste) |
| M3-AC1 | `missing_core.txt` vs `ls docs/api-deltas.md` | toda ausência justificada no doc |
| M3-AC3 | cobertura de `docker_test.log` | ≥ 75% |
| M3-DoD1 | `grep -rn 'v1.0.0-rc1\|1.0.0-rc1' include/map2check.h cbindgen.toml Cargo.toml`; `tags.txt` | versão no header/tag |
| M3-DoD2 | para cada fn em `ffi_exports.txt`, ler o corpo (`grep -n -A4 "fn <nome>" rust/src/ffi.rs`) | nenhum corpo vazio/no-op sem documentação |

- [ ] **Step 2: Escrever status no checklist** (mesmo formato da Task 4).

---

### Task 6: Classificação M4 e M6

**Files:**
- Modify: `audit/checklist.md`
- Create: `audit/evidence/m4_m6_checks.log`

- [ ] **Step 1: M4**

```bash
grep -rn 'cfg(feature *= *"klee")' rust/src
ls rust/src/nondet/klee.rs scripts/build_klee_bc.sh docs/klee-feasibility.md 2>&1
grep -rn klee_make_symbolic rust/src
cat run_klee_test.sh
grep -n -A8 'AS klee-bc' Dockerfile
```
Regras: E1/E2/E3/I1/I2/I3 → `PENDENTE` se arquivo/`cfg` não existe; `PARCIAL` se existe sem conteúdo funcional (ex.: estágio `klee-bc` com `|| true`). I4: script reescrito para o layout pós-CMake **e** job de CI com KLEE dockerizado. AC1: se `docs/klee-feasibility.md` não existe e não há execução de KLEE registrada → `PENDENTE` (a cláusula "ou relatório" também falha); se existe bitcode mas não há KLEE local → `NÃO VERIFICÁVEL`. AC2: medição registrada no relatório ou `PENDENTE`. DoD1: decisão citada no roadmap/§3.2 ou TODO.md.

- [ ] **Step 2: M6**

```bash
ls -d tests/differential docs/semantic-deltas.md 2>&1
grep -ln 'schedule' .github/workflows/*
grep -rniE 'hyperfine|benchmark' docs README.md .github 2>/dev/null
grep -n -A25 'fn is_invalid_address\|fn is_deref_error\|fn has_memcleanup_error' -r rust/src/memtrack
```
Regras: I2/I3 `IMPLEMENTADO` só com decisão registrada em `semantic-deltas.md` + fixture de teste; código alterado sem adjudicação documentada → `PARCIAL`. AC1/AC2 sem harness/benchmark → `PENDENTE`; com harness mas exigindo o corpus do Map2Check indisponível → `NÃO VERIFICÁVEL`. AC3: workflow com `schedule` e run recente em `ci_runs.json`. DoD1: aprovação registrada (PR review ou comentário do mantenedor).

- [ ] **Step 3: Escrever status no checklist.**

---

### Task 7: Classificação M5, M7 e M8 (leitura de `hbgit/Map2Check`)

**Files:**
- Modify: `audit/checklist.md`, `audit/evidence/symbols_compat.txt`
- Create: `audit/evidence/m5_m7_m8_checks.log`, `audit/evidence/map2check_*.txt`

- [ ] **Step 1: Clone raso, somente leitura, no scratchpad**

```bash
S=/tmp/claude-1000/-home-rock-Documents-Dev-map2check-library/bebe49e7-bdb8-4d51-a37a-11f8904d7334/scratchpad
git clone --depth 1 --branch develop https://github.com/hbgit/Map2Check.git "$S/Map2Check" 2>&1 | tail -2
grep -rhoE '"(map2check_non_det_[A-Za-z_0-9]+|map2check_nondet_cast_[A-Za-z_0-9]+|map2check_pointer_cast)"' "$S/Map2Check" \
  | tr -d '"' | sort -u | tee audit/evidence/map2check_nondet_family.txt
```
Anexar o conteúdo de `map2check_nondet_family.txt` a `symbols_compat.txt` e refazer `missing_compat.txt` (Task 3, Step 4). Se o clone falhar (repo privado/inacessível): famílias verificadas só por prefixo no `nm` → no máximo `PARCIAL`; itens de M7/M8 → `NÃO VERIFICÁVEL`, justificativa "Map2Check inacessível".

- [ ] **Step 2: M5**

```bash
ls rust/src/ffi_compat.rs docs/compat-matrix.md 2>&1
grep -n 'm2c-compat' Cargo.toml
grep -rn 'map2check_property_' rust/src
grep -rn 'map2check_check_deref_v2' rust/src
wc -l audit/evidence/missing_compat.txt
```
Regras: AC1 `IMPLEMENTADO` só com `missing_compat.txt` vazio **e** script no CI. AC2/I5: golden tests no repo e passando em `test.log`. DoD2: segundo header gerado pelo `build.rs`.

- [ ] **Step 3: M7/M8 (evidência no Map2Check)**

```bash
M=hbgit/Map2Check
gh api "repos/$M/branches?per_page=100" --jq '.[].name' > audit/evidence/map2check_branches.txt
gh pr list -R $M --state all --limit 200 --search 'rust' --json number,title,state,headRefName,url > audit/evidence/map2check_prs.json
grep -rn 'MAP2CHECK_RUST_RUNTIME\|corrosion' -i "$S/Map2Check/CMakeLists.txt" "$S/Map2Check/.github" "$S/Map2Check/docs" 2>/dev/null
grep -rn 'linkLLVM' "$S/Map2Check" --include=*.cpp | head
gh release list -R $M --limit 20 > audit/evidence/map2check_releases.txt
```
Regras: M7-E1/DoD1 exigem PR com head `feature/rust-runtime`. Regressão/tempo (M7-AC2/AC3, M8-AC1) → `PENDENTE` se a flag não existe; `NÃO VERIFICÁVEL` se a flag existe mas a suíte não pode ser rodada aqui. M8-I5/I6/AC2 → `PENDENTE` se o artefato a remover nunca existiu (regra 4). M8-DoD1: `git merge-base --is-ancestor feature/rust origin/master` sozinho não basta (`feature/rust` está atrás de `master`); exige também M1–M7 concluídos. M8-DoD2: release taggeada em ambos (`releases.txt`, `map2check_releases.txt`).

- [ ] **Step 4: Escrever status no checklist.**

---

### Task 8: Critério global, matriz §3.1 e relatório

**Files:**
- Create: `audit/relatorio_auditoria.md`

**Interfaces:**
- Consumes: checklist classificado (Tasks 4–7).
- Produces: relatório final; `G-1..G-7` classificados.

- [ ] **Step 1: Classificar G-1..G-7 derivando dos itens**

| G | Atendido se |
|---|---|
| G-1 | M1-AC1..AC5 `IMPLEMENTADO` + cobertura ≥ **80%** fora de `ffi*.rs` + toolchain fixado (M1-I3) |
| G-2 | `missing_compat.txt` vazio **e** `missing_core.txt` vazio (exceto exceções documentadas) **e** header versionado (M3-DoD1) |
| G-3 | M6-AC1 + `semantic-deltas.md` com fixtures |
| G-4 | M7-AC1/AC2 + M8-AC1, e decisão M4 registrada (contingência KLEE → "pronto qualificado" com issue aberta) |
| G-5 | M6-AC2 |
| G-6 | M2-AC1 |
| G-7 | header publicado (M1-E5), guia de build/integração (M7-I4), `semantic-deltas.md`, `klee-feasibility.md`, CHANGELOG, release taggeada |

Status de G-n = o pior status entre seus componentes (`PENDENTE` < `NÃO VERIFICÁVEL` < `PARCIAL` < `IMPLEMENTADO` para efeito de "atendido": só `IMPLEMENTADO` em todos = atendido).

- [ ] **Step 2: Escrever `audit/relatorio_auditoria.md`** com:
  1. Cabeçalho: data, `AUDIT_SHA`, branches de referência, ferramentas ausentes e como foram substituídas (`env.txt`).
  2. Resumo: contagem por status por milestone (tabela `Milestone | IMPL | PARC | PEND | N/V`).
  3. Uma seção por milestone com tabela `ID | item | status | evidência | issue` (issue vazia até a Task 12).
  4. "Critério global §3.4": tabela `G | critério | atendido? | componentes | evidência` e a frase "X de 7 critérios atendidos".
  5. "Matriz §3.1": para cada linha (R1…R10, stubs, feature klee, símbolos ausentes, canal de resultado), status agregado dos itens mapeados.
  6. Lista dos `NÃO VERIFICÁVEL` com o ambiente necessário.

- [ ] **Step 3: Autoverificação do relatório**

```bash
# todo item tem status e evidência
grep -E '^\| (M[1-8]|G)-' audit/checklist.md | awk -F'|' '$7 ~ /^ *$/ {print "SEM STATUS:", $2}'
# nenhum IMPLEMENTADO sem comando/arquivo:linha/run ID/PR na evidência
grep -E 'IMPLEMENTADO' audit/relatorio_auditoria.md | grep -vE 'evidence/|\.rs:[0-9]|run [0-9]+|#[0-9]+|\.(toml|yml|md|sh|c):[0-9]'
# itens de remoção/ausência (regra 4)
grep -E '^\| (M1-I5|M1-E6|M2-AC3|M8-I5|M8-I6|M8-AC2) ' audit/relatorio_auditoria.md
```
Esperado: as duas primeiras sem saída; revisar manualmente as linhas da terceira contra a regra 4. Conferir também (Review Focus 1) que M4-E2 não está `IMPLEMENTADO` se o grep de `cfg(feature = "klee")` foi vazio.

- [ ] **Step 4: Confirmar somente leitura** (mesmo comando da Task 3, Step 7).

---

### Task 9: Deduplicação e rascunho das issues

**Files:**
- Create: `audit/issues_propostas.md`, `audit/evidence/dedup.tsv`

**Interfaces:**
- Consumes: `issues.json`, `prs.json`, `milestones.json`, `labels.json`, checklist.
- Produces: por item candidato, uma ação: `CRIAR`, `COMENTAR #n`, `JÁ EXISTE #n (fechada)`, `COBERTO POR <ID>`.

- [ ] **Step 1: Candidatos** = itens `PENDENTE`/`PARCIAL`. Item com `coberto_por` cujo item-pai também é candidato → `COBERTO POR <pai>` (entra no corpo do pai em "Também cobre"). Item com `coberto_por` cujo pai está `IMPLEMENTADO` → candidato próprio (o pai não resolve tudo).

- [ ] **Step 2: Cruzamento com issues existentes**

```bash
jq -r '.[] | [.number, .state, .title, ((.body // "") | capture("Audit-ID: (?<id>[A-Z0-9-]+)").id // "")] | @tsv' \
  audit/evidence/issues.json > audit/evidence/existing_issues.tsv
```
Para cada candidato, casar por: (a) `Audit-ID` igual; (b) título normalizado (minúsculas, sem pontuação) igual ao título do plano; (c) os 40 primeiros caracteres após o prefixo `area:` coincidentes → revisão manual. Registrar em `dedup.tsv`: `ID | ação | issue | critério de casamento`.
- Casou com issue **aberta** e status `PARCIAL` → `COMENTAR #n`.
- Casou com issue **aberta** e status `PENDENTE` → nenhuma ação nova (citar #n no checklist).
- Casou com issue **fechada** mas o item não está implementado → `CRIAR` com "Reabre o escopo de #n" no corpo (não reabrir sem aprovação).

- [ ] **Step 3: Milestones e labels faltantes**

```bash
jq -r '.[].title' audit/evidence/milestones.json | sort > audit/evidence/milestones_existing.txt
jq -r '.[].name'  audit/evidence/labels.json     | sort > audit/evidence/labels_existing.txt
```
Comparar com os 8 títulos da §3.3 e as 12 labels do plano; listar os faltantes em `issues_propostas.md`.

- [ ] **Step 4: Rascunhar cada `CRIAR`** em `issues_propostas.md`:

- **Título:** issue do plano → título literal. Demais itens → `<área>: <descrição imperativa>`, ex.: `M1-DoD2` → `ci: protect feature/rust and require CI checks on PRs`; `M1-AC8` → `ci: run tarpaulin in CI and enforce ≥70% coverage outside ffi.rs`.
- **Milestone:** título §3.3 do milestone do item; `G-n` → milestone do componente pendente de maior número.
- **Labels:** as do plano para a issue; se o plano não lista nenhuma, derivar do prefixo: `ci→area:ci`, `build→area:build`, `ffi|state→area:ffi`, `fuzzing→area:fuzzing`, `klee→area:klee`, `compat|cmake|frontend|passes|map2check|library→area:integration`, `memtrack→area:memtrack`, `test→kind:test`, `docs→kind:docs`, `perf|lint|chore→kind:feature`; `kind:bug` só quando o plano marca. `prio:critical` só quando o plano marca.
- **Corpo:**

```markdown
Audit-ID: M2-I1
Status na auditoria: PARCIAL (ref <AUDIT_SHA>, <data>)

## Trecho do plano
> <citação literal da linha da issue + critério de aceitação do milestone relacionado>

## O que falta (evidência)
- <fato observado com arquivo:linha / evidence/x.log / run ID>

## Critério de aceitação
- <critério verificável, copiado/derivado do plano>

## Dependências
- <milestones/issues do plano, ex.: M1 (#n)>

## Também cobre
- <IDs com coberto_por = este item>
```

- [ ] **Step 5: Rascunhar cada `COMENTAR #n`** com: `Audit-ID`, status, o que já existe (evidência) e o que falta.

---

### Task 10: Script idempotente `audit/create_issues.sh`

**Files:**
- Create: `audit/create_issues.sh`, `audit/issues/<ID>.md` (um corpo por issue), `audit/issues/<ID>.meta` (title/milestone/labels/action)

**Interfaces:**
- Consumes: rascunhos da Task 9.
- Produces: `audit/evidence/created_issues.tsv` (`ID\tnúmero\turl\tação`).

- [ ] **Step 1: Gerar `audit/issues/*.md` e `*.meta`** a partir de `issues_propostas.md`. Formato do `.meta` (`ACTION` é `create` ou `comment`; `NUMBER` só para `comment`):

```
ACTION=create
NUMBER=
TITLE=ffi: wrap every extern "C" export in catch_unwind with error logging
MILESTONE=M2 — Endurecer a fronteira FFI
LABELS=area:ffi,prio:critical
```

- [ ] **Step 2: Escrever o script**

```bash
#!/usr/bin/env bash
# Cria milestones, labels e issues da auditoria. Dry-run por padrão; use --apply para executar.
set -euo pipefail
REPO=hbgit/map2check-library
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$DIR/evidence/created_issues.tsv"
APPLY=0; [[ "${1:-}" == "--apply" ]] && APPLY=1
run() { if ((APPLY)); then "$@"; else printf 'DRY-RUN:'; printf ' %q' "$@"; echo; fi; }

MILESTONES=(
  "M1 — Restaurar build, CI e higiene"
  "M2 — Endurecer a fronteira FFI"
  "M3 — Completar paridade da API núcleo"
  "M4 — Spike KLEE (gate go/no-go)"
  "M5 — Camada de compatibilidade com passes do Map2Check"
  "M6 — Testes diferenciais e desempenho"
  "M7 — Integração no CMake do Map2Check sob flag"
  "M8 — Promoção a default e aposentadoria do compat"
)
existing_ms=$(gh api "repos/$REPO/milestones?state=all&per_page=100" --jq '.[].title')
for m in "${MILESTONES[@]}"; do
  grep -qxF "$m" <<<"$existing_ms" || run gh api "repos/$REPO/milestones" -f title="$m"
done

LABELS=(area:ffi area:build area:ci area:klee area:fuzzing area:memtrack area:integration
        kind:bug kind:feature kind:test kind:docs prio:critical)
existing_lb=$(gh label list -R "$REPO" --limit 500 --json name --jq '.[].name')
for l in "${LABELS[@]}"; do
  grep -qxF "$l" <<<"$existing_lb" || run gh label create "$l" -R "$REPO"
done

touch "$OUT"
for meta in "$DIR"/issues/*.meta; do
  id=$(basename "$meta" .meta); body="$DIR/issues/$id.md"
  get() { sed -n "s/^$1=//p" "$meta"; }
  ACTION=$(get ACTION); NUMBER=$(get NUMBER); TITLE=$(get TITLE); MILESTONE=$(get MILESTONE); LABELS=$(get LABELS)
  if [[ "$ACTION" == comment ]]; then
    if gh issue view "$NUMBER" -R "$REPO" --json comments --jq '.comments[].body' | grep -qF "Audit-ID: $id"; then
      echo "SKIP $id (comentário já existe em #$NUMBER)"; continue
    fi
    run gh issue comment "$NUMBER" -R "$REPO" -F "$body"
    ((APPLY)) && printf '%s\t%s\t%s\tcomment\n' "$id" "$NUMBER" "https://github.com/$REPO/issues/$NUMBER" >> "$OUT"
    continue
  fi
  found=$(gh issue list -R "$REPO" --state all --limit 1000 --search "\"Audit-ID: $id\" in:body" --json number --jq '.[0].number // empty')
  # a busca do GitHub indexa issues novas com atraso; o registro local cobre a janela
  [[ -z "$found" ]] && found=$(awk -F'\t' -v i="$id" '$1==i && $4=="create"{print $2}' "$OUT")
  if [[ -n "$found" ]]; then echo "SKIP $id (já existe #$found)"; continue; fi
  if ((APPLY)); then
    url=$(gh issue create -R "$REPO" -t "$TITLE" -m "$MILESTONE" -l "$LABELS" -F "$body")
    printf '%s\t%s\t%s\tcreate\n' "$id" "${url##*/}" "$url" | tee -a "$OUT"
  else
    run gh issue create -R "$REPO" -t "$TITLE" -m "$MILESTONE" -l "$LABELS" -F "$body"
  fi
done
```

- [ ] **Step 3: Testar em dry-run**

```bash
bash -n audit/create_issues.sh && shellcheck audit/create_issues.sh || true
bash audit/create_issues.sh | tee audit/evidence/dry_run.log
grep -c '^DRY-RUN: gh issue create' audit/evidence/dry_run.log
grep -c '^DRY-RUN: gh issue comment' audit/evidence/dry_run.log
```
Esperado: contagens == número de `CRIAR` e `COMENTAR` em `dedup.tsv`; nenhuma chamada sem `DRY-RUN:`. Idempotência (Review Focus 3) é verificada na Task 12, Step 3.

---

### Task 11: Gate de revisão humana

- [ ] **Step 1: Apresentar ao usuário** (no chat, resumido): link para `audit/relatorio_auditoria.md`, a tabela de contagem por status, "X de 7 critérios globais atendidos", a lista de issues propostas (`ID | título | milestone | labels`), comentários propostos, milestones/labels a criar, e os itens `NÃO VERIFICÁVEL`.
- [ ] **Step 2: Aguardar aprovação explícita.** Aplicar ajustes pedidos em `audit/issues/*` e rerodar o dry-run. **Não prosseguir sem "aprovado" (ou equivalente) do usuário.**

---

### Task 12: Criação e registro

**Files:**
- Modify: `audit/checklist.md` (coluna issue), `audit/relatorio_auditoria.md` (coluna issue)
- Create: `audit/issues_criadas.md`

- [ ] **Step 1: Executar**

```bash
bash audit/create_issues.sh --apply | tee audit/evidence/apply.log
```

- [ ] **Step 2: Registrar números** — para cada linha de `created_issues.tsv`, preencher a coluna `issue` do item e de todos os itens com `coberto_por` = esse ID, no checklist e no relatório. Itens `JÁ EXISTE`/`COMENTAR` recebem o número existente.

- [ ] **Step 3: Verificar idempotência**

```bash
bash audit/create_issues.sh | grep -c '^DRY-RUN: gh issue create'
```
Esperado: `0` (todas viram `SKIP`).

- [ ] **Step 4: Escrever `audit/issues_criadas.md`** — tabela `ID | issue | link | ação` a partir de `created_issues.tsv`, e conferir que cada uma existe:
```bash
cut -f2 audit/evidence/created_issues.tsv | xargs -I{} gh issue view {} -R hbgit/map2check-library --json number,title,milestone,labels --jq '"\(.number)\t\(.milestone.title)\t\(.title)"'
```

- [ ] **Step 5: Confirmar somente leitura e oferecer commit** — rodar o comando da Task 3, Step 7. Commitar `audit/` e este plano **apenas se o usuário pedir**, com `git commit -S` e sem atribuição de IA.
