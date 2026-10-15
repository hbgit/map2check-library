# Limpeza de Branches Remotas (origin) e Migração para o Fluxo `master`/`develop` — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduzir as 13 branches de `origin` (hbgit/map2check-library) a **`master` + `develop`**, aposentando `feature/rust` como branch de integração. Antes de qualquer remoção, o relatório passa por revisão humana, e a reversão fica garantida.

**Architecture:** O fluxo passa a ser: branch de trabalho `<tipo>/issue-<N>-<slug>` → PR → `develop` (integração), depois `develop` → PR → `master` (release, 1 review). Quando necessário, usa-se `release/*` para estabilizar uma versão. A execução tem quatro fases: (0) uma mudança versionada que troca `feature/rust` por `develop` em CI, script de proteção e docs; (1) levantamento e relatório **somente-leitura**; (2) **portão de aprovação humana**; (3) etapas **destrutivas**: transferir a proteção para `develop`, tornar `develop` a branch padrão do GitHub, tirar a proteção de `feature/rust` e remover tudo num único push atômico com `--force-with-lease` amarrado aos hashes do relatório.

**Tech Stack:** Git padrão (`for-each-ref`, `rev-list`, `cherry`, `merge-base`, `push --atomic --force-with-lease`), bash, `jq`. Não há como evitar o `gh` CLI nas tasks de proteção de branch e de troca da branch padrão, porque são configurações do GitHub (o script do repositório já depende dele). Nas demais, o `gh` é opcional.

**Spec:** Pedidos do usuário nesta sessão (2026-10-15). (1) Plano de limpeza com levantamento, critérios, lista de manutenção, relatório para revisão, execução em lote com confirmação, reversão e prevenção. (2) "Remover também a branch feature/rust, focando no fluxo de main, develop e outras branches necessárias." (3) "Troque a branch padrão para develop." O plano não executa nenhuma remoção.

## Global Constraints

- A branch de release continua se chamando **`master`** e continua protegida (check `build_and_test`, 1 review, commits assinados). Renomear para `main` está **fora do escopo**, porque mexeria em proteção, links e clones. Se for desejado, vira um plano separado.
- A **branch padrão do GitHub passa a ser `develop`** (hoje é `master`). Assim, PRs novos apontam para `develop` sem ajuste manual, e `git clone` faz checkout de `develop`. A troca só acontece **depois** que `develop` estiver protegida (Task 5, Step 3). Nada no repositório depende da branch padrão: não há workflow `schedule:` nem Dependabot, e os badges do README citam `master` explicitamente.
- Branch de integração: passa a ser **`develop`**. Hoje `feature/rust` (`3813ddef6b01b3f913a2021d64901f055f6cbb59`) é **ancestral** de `develop` (`346e340`), então remover `feature/rust` não perde nenhum commit.
- NUNCA remover: `master`, `develop`, `release/*` (hoje não existe nenhuma), `HEAD`.
- `develop` precisa ter **a mesma proteção que `feature/rust` tem hoje** **antes** de `feature/rust` ser removida: check `build_and_test` (app 15368), `strict: false`, sem review obrigatório, `enforce_admins: false`, sem force push, sem deleção, commits assinados.
- `feature/rust` só pode perder a proteção **imediatamente antes** do push de remoção. Se a remoção for abortada, a proteção volta (Task 9, Step 4).
- Limite de inatividade padrão: **6 meses** (corte `2026-04-15` nesta execução).
- Nenhuma etapa destrutiva roda sem `decisao` = `APROVADO` no relatório, preenchida por humano.
- Relatório e evidências ficam **fora do repositório**: `~/map2check-branch-cleanup-2026-10-15.tsv`, `~/map2check-branch-cleanup-2026-10-15.log`, `~/map2check-feature-rust-protection-2026-10-15.json`.
- Documentos históricos que citam `feature/rust` (`audit/`, `TODO.md`, entradas já publicadas do `CHANGELOG.md`, `docs/plano_map2check_library_rust.md`, `docs/api-deltas.md`) **não são editados**: descrevem o passado. Só mudam os arquivos que orientam o fluxo atual.

## Review Focus

1. **PRs para `develop` ficam bloqueados para sempre.** Se `develop` exigir `build_and_test` e o `CI.yml` não disparar em `pull_request` para `develop`, o check nunca chega. Esperado: o teste offline verifica que `develop` está nos gatilhos `push` e `pull_request` do CI. Coberto na Task 1, Step 1.
2. **`feature/rust` removida enquanto `develop` está desprotegida.** Esperado: a Task 6 só começa depois que `scripts/branch-protection.sh check develop` imprimir `ok develop`. Coberto na Task 5, Step 2.
3. **Branch avança entre o relatório e a remoção.** Esperado: o push `--atomic` com `--force-with-lease=<b>:<hash>` recusa tudo e nada é removido. Coberto na Task 4, Step 2 (dry-run) e na Task 6, Step 1.
4. **Push de remoção rejeitado porque `feature/rust` ainda está protegida** (`allow_deletions: false`). Esperado: o `--atomic` não remove nenhuma outra branch, e o executor volta à Task 5, Step 4. O dry-run da Task 4 não detecta isso, por isso a Task 5 roda antes do push real (Task 6, Step 1).
5. **Branch protegida aprovada por engano de edição do relatório.** Esperado: o script de execução se recusa a montar o push. Coberto na Task 4, Step 1.

---

## Estado levantado em 2026-10-15 (snapshot somente-leitura)

| Branch remota | Último commit | Hash | Relação com `develop` / `master` | PR | Categoria proposta |
|---|---|---|---|---|---|
| `master` | 2026-10-14 | `a72f63e` | — | — | **MANTER** (protegida, release; default atual) |
| `develop` | 2026-10-15 | `346e340` | contém `feature/rust` + 9 commits | — | **MANTER** (nova integração e nova default) |
| `feature/rust` | 2026-10-15 | `3813dde` | ancestral de `develop`, 0 únicos | base dos PRs #1–#35 | A — mergeada em `develop` (**exige Tasks 1 e 5 antes**) |
| `docs/issue-5-compat-release` | 2026-10-15 | `bb1c7b0` | ancestral de `develop` | #35 MERGED | A |
| `test/issue-29-ffi-unit-tests` | 2026-10-15 | `09d86ac` | ancestral de `develop` | #34 MERGED | A |
| `build/issue-28-version-rc1` | 2026-10-15 | `91178f3` | ancestral de `develop` | #33 MERGED | A |
| `chore/issue-27-remove-c-era-docs` | 2026-10-14 | `e9386b5` | ancestral de `develop` | #32 MERGED | A |
| `ci/issue-26-branch-protection` | 2026-10-14 | `eecc3c9` | ancestral de `develop` | #31 MERGED | A |
| `feat/issue-25-coverage-gate` | 2026-10-14 | `bc04579` | ancestral de `develop` | #30 MERGED | A |
| `feat/M3_paridade` | 2026-10-13 | `d86e5d5` | ancestral de `develop` | #3 MERGED | A |
| `feat/update_rust` | 2026-10-13 | `dfcce06` | ancestral de `develop` | #1, #2 MERGED | A |
| `refactory_memory_log` | 2020-09-18 | `68d174d` | ancestral de `master` | — | A (+ B: 6 anos parada) |
| `memory_check` | 2021-07-06 | `f287e99` | **3 commits únicos**, nenhum PR | — | B + C: arquivar em tag e remover (decisão humana) |

Observações:
- Resultado esperado: 13 → **2** branches (`master`, `develop`). Serão 11 remoções e 1 tag de arquivo.
- Não há PR aberto (nenhum tem base `feature/rust`). Se surgir algum até a execução, o GitHub o fecharia quando a base sumisse, e por isso a Task 2 checa isso de novo.
- O default do GitHub é `master` hoje e passa a ser `develop` na Task 5, Step 3.
- Commits únicos de `memory_check`: `5185e66` (2021-07-01), `2d83265` (2021-07-03), `f287e99` (2021-07-06 "Add unit testing on memtracklog"). São da era C, removida em #32.

## Critérios de remoção

| Categoria | Regra (todas as condições) | Ação |
|---|---|---|
| **A — mergeada** | não protegida pela regra do plano **e** (`merge-base --is-ancestor <b> origin/develop` ou `... origin/master`, **ou** `git cherry origin/develop <b>` = 0, **ou** PR `MERGED`) | Remover |
| **B — inativa** | não protegida **e** último commit antes de `hoje − 6 meses` **e** não A | Tag `archive/<b>`, depois remover |
| **C — órfã/experimental** | não protegida **e** sem PR **e** commits únicos > 0 | Igual a B. Se for recente (< 6 meses), **MANTER** e perguntar ao autor |
| **Manter** | `master`, `develop`, `release/*`, **ou** PR aberto, **ou** recente com trabalho não mergeado | Manter |

## Arquivos

Versionados (Task 1, PR para `develop`):
- Modify: `scripts/test-branch-protection.sh` — testes offline passam a cobrir `develop`, rejeitar `feature/rust` e verificar os gatilhos do CI.
- Modify: `scripts/branch-protection.sh` — o caso `feature/rust` vira `develop`.
- Modify: `.github/workflows/CI.yml:4-7` — gatilhos passam a `master`, `develop` e `release/**`.
- Modify: `README.md` — seção "Proteção de branches" passa a descrever o novo fluxo.
- Modify: `docs/release.md` — passos 1 e 4 passam a usar `develop`.
- Modify: `CHANGELOG.md` — entrada `### Changed` em `[Unreleased]`.

Fora do repositório: o relatório `.tsv`, o `.log` do push e o `.json` com a proteção antiga de `feature/rust`.

---

## FASE 0 — MUDANÇA VERSIONADA (sem efeitos no remoto além de um PR)

### Task 1: `develop` substitui `feature/rust` em CI, proteção e docs

**Files:**
- Modify: `scripts/test-branch-protection.sh:13-24,32-37`
- Modify: `scripts/branch-protection.sh:14,22`
- Modify: `.github/workflows/CI.yml:4-7`
- Modify: `README.md` (seção `### Proteção de branches`)
- Modify: `docs/release.md` (passos 1 e 4)
- Modify: `CHANGELOG.md` (antes de `## [1.0.0-rc1] - Unreleased`)

**Interfaces:**
- Produces: `scripts/branch-protection.sh {payload|check|apply|encode} {develop|master}`. Para `develop`, `payload` imprime o mesmo JSON que imprimia para `feature/rust`. `feature/rust` passa a sair com exit 2. A Task 5 consome `apply develop` e `check develop`, e a Task 9 consome `payload develop`.

- [ ] **Step 1: Atualizar os testes (falham primeiro)**

```bash
cd /home/rock/Documents/Dev/map2check-library
git switch develop && git pull --ff-only
git switch -c ci/develop-as-integration-branch
```

Em `scripts/test-branch-protection.sh`, substituir as linhas 13–24 (de `# Codificação de nomes com barra` até o último `t "fr: ..."`) por:

```bash
# Codificação de nomes com barra (Review Focus 2)
t "encode release/1.0" test "$("$BP" encode release/1.0)" = "release%2F1.0"
t "encode develop"     test "$("$BP" encode develop)" = "develop"
t "encode master"      test "$("$BP" encode master)" = "master"

# develop (integração): check obrigatório, sem review, sem force push/deleção
dv="$("$BP" payload develop 2>/dev/null || true)"
t "develop: check build_and_test (app 15368)" jq -e '.required_status_checks.checks == [{"context":"build_and_test","app_id":15368}]' <<<"$dv"
t "develop: strict false"          jq -e '.required_status_checks.strict == false' <<<"$dv"
t "develop: sem review"            jq -e '.required_pull_request_reviews == null' <<<"$dv"
t "develop: enforce_admins false"  jq -e '.enforce_admins == false' <<<"$dv"
t "develop: sem force push"        jq -e '.allow_force_pushes == false and .allow_deletions == false' <<<"$dv"
t "develop: restrictions null"     jq -e 'has("restrictions") and .restrictions == null' <<<"$dv"
```

E substituir as linhas 32–37 (de `# Branch desconhecida e subcomando inválido falham` até o `t "CI.yml tem job build_and_test" ...`; a linha `exit "$fail"` fica) por:

```bash
# Branch desconhecida (inclui a antiga integração) e subcomando inválido falham (Review Focus 5)
t "feature/rust aposentada -> exit 2" bash -c '"$0" payload feature/rust; test $? -eq 2' "$BP"
t "branch desconhecida -> exit 2"     bash -c '"$0" payload feat/x; test $? -eq 2' "$BP"
t "subcomando inválido -> exit 2"     bash -c '"$0" frobnicate master; test $? -eq 2' "$BP"

# O check obrigatório existe como job no CI (Review Focus 3)
t "CI.yml tem job build_and_test" grep -qE '^  build_and_test:' "$ROOT/.github/workflows/CI.yml"

# CI dispara em push e PR para as branches protegidas; senão o check nunca chega
for ev in push pull_request; do
  t "CI.yml: $ev cobre develop e master" bash -c \
    'sed -n "/^  $1:/,/branches:/p" "$0" | grep "branches:" | grep -q "\"develop\"" &&
     sed -n "/^  $1:/,/branches:/p" "$0" | grep "branches:" | grep -q "\"master\""' \
    "$ROOT/.github/workflows/CI.yml" "$ev"
  t "CI.yml: $ev não cita feature/rust" bash -c \
    '! sed -n "/^  $1:/,/branches:/p" "$0" | grep -q "feature/rust"' \
    "$ROOT/.github/workflows/CI.yml" "$ev"
done
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `scripts/test-branch-protection.sh; echo "exit=$?"`
Expected: **11** linhas `FAIL` (6 `develop: ...`, `feature/rust aposentada -> exit 2` e 4 `CI.yml: ...`) e `exit=1`. Os testes de `encode`, `master` e `subcomando inválido` passam. (Validado em cópia do repositório em 2026-10-15.)

- [ ] **Step 3: Implementar**

Em `scripts/branch-protection.sh`, linha 14:

```bash
usage() { echo "uso: $0 {payload|check|apply|encode} {develop|master}" >&2; exit 2; }
```

Linha 22 (substitui `feature/rust) reviews='null' ;;`):

```bash
    develop) reviews='null' ;;
```

Em `.github/workflows/CI.yml`, linhas 4–7:

```yaml
  push:
    branches: [ "master", "develop", "release/**" ]
  pull_request:
    branches: [ "master", "develop", "release/**" ]
```

- [ ] **Step 4: Rodar e ver passar**

Run: `scripts/test-branch-protection.sh; echo "exit=$?"`
Expected: 20 linhas `ok - ...` e `exit=0`.

- [ ] **Step 5: Atualizar docs**

`README.md`, na seção `### Proteção de branches`: substituir o parágrafo que começa com `` `feature/rust` e `master` exigem `` e o bloco `sh` logo abaixo por:

````markdown
Fluxo: `develop` é a branch padrão do repositório. Branches de trabalho `<tipo>/issue-<N>-<slug>` (`tipo` ∈ feat, fix, docs, test, build, ci, chore) abrem PR para `develop`; releases sobem de `develop` para `master` por PR. `develop` e `master` exigem o check `build_and_test` (workflow "CI Map2Check Rust") e commits assinados; `master` exige também 1 review. A configuração está em `scripts/branch-protection.sh`:

```sh
scripts/branch-protection.sh check develop   # compara com o GitHub (exit 0/1)
scripts/branch-protection.sh apply master    # requer permissão de admin
```
````

`docs/release.md`, passo 1: trocar ``On a branch off `feature/rust`,`` por ``On a branch off `develop`,``. Passo 4: trocar

```
4. **Pull request.** Open a PR to `feature/rust` (or `master` after the
   promotion) and merge it once `build_and_test` is green.
```

por

```
4. **Pull request.** Open a PR to `develop` and merge it once
   `build_and_test` is green, then open a PR from `develop` to `master`
   (1 review required).
```

`CHANGELOG.md`: inserir imediatamente antes da linha `## [1.0.0-rc1] - Unreleased` (fica dentro de `[Unreleased]`, depois de `### Added`):

```markdown
### Changed

- `develop` replaces `feature/rust` as the integration branch: CI runs on
  pushes and pull requests to `master`, `develop` and `release/**`, and
  `scripts/branch-protection.sh` protects `develop` instead of
  `feature/rust`.

```

- [ ] **Step 6: Verificação completa e commit**

```bash
scripts/test-branch-protection.sh
cargo test --all-features
git grep -n 'feature/rust' -- README.md docs/release.md scripts/ .github/
```

Expected: o teste do script com exit 0; `cargo test` verde (inclui `tests/header_version.rs`, que lê o CHANGELOG, e `compat_docs`); o `git grep` só encontra as linhas de `scripts/test-branch-protection.sh` que testam a aposentadoria de `feature/rust`.

```bash
git add scripts/branch-protection.sh scripts/test-branch-protection.sh .github/workflows/CI.yml README.md docs/release.md CHANGELOG.md
git commit -m "ci: make develop the integration branch instead of feature/rust"
git push -u origin ci/develop-as-integration-branch
gh pr create --base develop --title "ci: make develop the integration branch instead of feature/rust" \
  --body "Troca feature/rust por develop no CI, no script de proteção e nas docs de fluxo/release. Pré-requisito do plano docs/superpowers/plans/2026-10-15-remote-branch-cleanup.md."
```

Expected: o CI do PR roda (o gatilho `pull_request` para `develop` vem do próprio commit do PR) e `build_and_test` fica verde. **Mergear antes da Fase 1.** Essa branch nova também será removida depois, pelo auto-delete (Task 8) ou na própria Task 6, se o relatório a listar.

---

## FASE 1 — SOMENTE-LEITURA

### Task 2: Levantamento e relatório para revisão

**Files:**
- Create: `~/map2check-branch-cleanup-2026-10-15.tsv`
- Create: `~/map2check-feature-rust-protection-2026-10-15.json`

**Interfaces:**
- Produces: TSV com cabeçalho exato
  `branch	ultimo_commit	autor	hash_completo	atras_dev	frente_dev	cherry_unico_dev	merged_dev	merged_master	pr	categoria	motivo	decisao`
  As Tasks 4 e 9 consomem as colunas 1, 4, 11 e 13.

- [ ] **Step 1: Atualizar refs e conferir pré-condições**

```bash
cd /home/rock/Documents/Dev/map2check-library
git fetch origin                     # sem --prune
git for-each-ref --sort=-committerdate refs/remotes/origin \
  --format='%(refname:short)|%(committerdate:short)|%(authorname)|%(objectname:short)'
git merge-base --is-ancestor origin/feature/rust origin/develop && echo "feature/rust contida em develop"
git show origin/develop:.github/workflows/CI.yml | sed -n '3,7p'
gh pr list --state open --json number,headRefName,baseRefName --jq '.[]|"#\(.number) \(.headRefName)->\(.baseRefName)"'
```

Expected: as 13 branches do snapshot, mais `ci/develop-as-integration-branch` se ela ainda não tiver sido apagada após o merge. Também devem aparecer `feature/rust contida em develop`, o CI com `"develop"` nos dois gatilhos, e **nenhum** PR aberto com base `feature/rust`. Se qualquer item divergir, **pare**: um PR aberto com base `feature/rust` precisa primeiro ser re-apontado (`gh pr edit <n> --base develop`).

- [ ] **Step 2: Guardar a proteção atual de `feature/rust` (evidência para a reversão)**

```bash
gh api repos/hbgit/map2check-library/branches/feature%2Frust/protection > ~/map2check-feature-rust-protection-2026-10-15.json
jq -c '{checks:[.required_status_checks.checks[].context], sig:.required_signatures.enabled, del:.allow_deletions.enabled}' ~/map2check-feature-rust-protection-2026-10-15.json
```

Expected: `{"checks":["build_and_test"],"sig":true,"del":false}`.

- [ ] **Step 3: Gerar o relatório**

```bash
cd /home/rock/Documents/Dev/map2check-library
REPORT=~/map2check-branch-cleanup-2026-10-15.tsv
CUTOFF=$(date -d '6 months ago' +%s)   # BSD/macOS: date -v-6m +%s
PROTECTED='^(master|develop|release/.*|HEAD)$'

# Mapa branch -> PRs (opcional; sem gh a coluna fica "?")
PRS=$(mktemp)
if command -v gh >/dev/null; then
  gh pr list --state all --limit 500 \
    --json number,headRefName,state \
    --jq '.[] | "\(.headRefName)\t#\(.number):\(.state)"' > "$PRS"
fi

printf 'branch\tultimo_commit\tautor\thash_completo\tatras_dev\tfrente_dev\tcherry_unico_dev\tmerged_dev\tmerged_master\tpr\tcategoria\tmotivo\tdecisao\n' > "$REPORT"

git for-each-ref --format='%(refname:lstrip=3)' refs/remotes/origin | grep -vx HEAD |
while read -r b; do
  ref="origin/$b"
  date=$(git log -1 --format=%cs "$ref")
  ts=$(git log -1 --format=%ct "$ref")
  author=$(git log -1 --format=%an "$ref")
  sha=$(git rev-parse "$ref")
  read -r behind ahead < <(git rev-list --left-right --count origin/develop..."$ref")
  cherry=$(git cherry origin/develop "$ref" | grep -c '^+')
  git merge-base --is-ancestor "$ref" origin/develop && mdv=sim || mdv=nao
  git merge-base --is-ancestor "$ref" origin/master  && mma=sim || mma=nao
  if command -v gh >/dev/null; then
    pr=$(awk -F'\t' -v b="$b" '$1==b{printf "%s ",$2}' "$PRS"); pr=${pr:-nenhum}
  else pr='?'; fi

  if   [[ $b =~ $PROTECTED ]];                                  then cat=MANTER; why="fluxo master/develop/release"
  elif [[ $mdv == sim || $mma == sim || $cherry == 0 || $pr == *MERGED* ]]; then cat=A; why="mergeada (develop=$mdv master=$mma cherry=$cherry pr=$pr)"
  elif [[ $pr == *OPEN* ]];                                     then cat=MANTER; why="PR aberto"
  elif (( ts < CUTOFF ));                                       then cat=B; why="sem commits desde $date; $cherry commits unicos; pr=$pr"
  elif [[ $pr == nenhum ]];                                     then cat=MANTER; why="recente e sem PR: perguntar ao autor"
  else                                                               cat=MANTER; why="recente"
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tPENDENTE\n' \
    "$b" "$date" "$author" "$sha" "$behind" "$ahead" "$cherry" "$mdv" "$mma" "${pr% }" "$cat" "$why" >> "$REPORT"
done
rm -f "$PRS"
column -t -s $'\t' "$REPORT"
```

Expected: 2 `MANTER` (`develop`, `master`), 10 `A` (as 8 branches de issue/feat, `feature/rust` e `refactory_memory_log`, mais `ci/develop-as-integration-branch` se ainda existir) e 1 `B` (`memory_check`). Se algo divergir, **não edite o relatório para bater**: investigue com `git log --oneline origin/develop..origin/<b>`.

---

## PORTÃO DE REVISÃO HUMANA

### Task 3: Aprovação do relatório

**Files:**
- Modify: `~/map2check-branch-cleanup-2026-10-15.tsv` (só a coluna `decisao`)

- [ ] **Step 1: Revisar e marcar decisões**

Para cada linha `A`/`B`, trocar `PENDENTE` por `APROVADO` ou `REJEITADO`. Pontos de atenção:
- `feature/rust`: aprovar só depois que a Task 1 estiver mergeada e os Expected da Task 2, Step 1 tiverem se confirmado.
- `docs/issue-5-compat-release` é a branch local atual do mantenedor (PR #35 já mergeado).
- `memory_check`: aprovar significa guardar os 3 commits de 2021 na tag `archive/memory_check` e então remover a branch.

- [ ] **Step 2: Validar o relatório aprovado**

```bash
awk -F'\t' 'NR>1{print $13}' ~/map2check-branch-cleanup-2026-10-15.tsv | sort | uniq -c
awk -F'\t' 'NR>1 && $13=="APROVADO" && $1 ~ /^(master|develop|release\/.*|HEAD)$/' ~/map2check-branch-cleanup-2026-10-15.tsv
```

Expected: nenhum `PENDENTE`; o segundo comando não imprime nada.

---

## FASE 2 — DESTRUTIVA (só após a Task 3)

### Task 4: Montar e testar o lote (dry-run)

**Files:**
- Read: `~/map2check-branch-cleanup-2026-10-15.tsv`

**Interfaces:**
- Produces: arrays `LEASES`, `DELS` e `TAGS` na sessão de shell atual, consumidos pela Task 6. Rode as Tasks 4, 5 e 6 **na mesma sessão** (bash ou zsh).

- [ ] **Step 1: Montar os argumentos e checar as travas**

```bash
cd /home/rock/Documents/Dev/map2check-library
REPORT=~/map2check-branch-cleanup-2026-10-15.tsv
PROTECTED='^(master|develop|release/.*|HEAD)$'
LEASES=(); DELS=(); TAGS=(); ABORT=0
while IFS=$'\t' read -r b _ _ sha _ _ _ _ _ _ cat _ dec; do
  [[ $dec == APROVADO ]] || continue
  if [[ $b =~ $PROTECTED ]]; then echo "ABORTAR: $b é protegida"; ABORT=1; fi
  LEASES+=("--force-with-lease=refs/heads/$b:$sha")
  DELS+=(":refs/heads/$b")
  [[ $cat == B ]] && TAGS+=("$sha:refs/tags/archive/$b")
done < <(tail -n +2 "$REPORT")
printf 'Remover (%d):\n' "${#DELS[@]}"; printf '  %s\n' "${DELS[@]#:refs/heads/}"
printf 'Arquivar como tag (%d):\n' "${#TAGS[@]}"; printf '  %s\n' "${TAGS[@]}"
[[ $ABORT == 0 ]] || { echo 'Corrija o relatório (Task 3) e repita este step.'; LEASES=(); DELS=(); TAGS=(); }
```

Expected (tudo aprovado): `Remover (11)`, incluindo `feature/rust`, e `Arquivar como tag (1)`: `f287e99…:refs/tags/archive/memory_check`.

- [ ] **Step 2: Dry-run**

```bash
[[ ${#TAGS[@]} -gt 0 ]] && git push --dry-run origin "${TAGS[@]}"
git push --dry-run --atomic origin "${LEASES[@]}" "${DELS[@]}"
```

Expected: `- [deleted]` por branch e `* [new tag] … archive/memory_check`, sem `stale info`. Um `stale info` significa que a branch mudou depois do relatório: **pare** e volte à Task 2. **Atenção:** o dry-run é local e não detecta a proteção do GitHub. Por isso a Task 5 vem antes do push real.

### Task 5: Transferir a proteção de `feature/rust` para `develop` e tornar `develop` a branch padrão

**Files:** nenhum (altera configurações do GitHub; exige admin).

- [ ] **Step 1: Proteger `develop`**

```bash
git switch develop && git pull --ff-only     # script já na versão da Task 1
scripts/branch-protection.sh apply develop
```

Expected: `ok develop`.

- [ ] **Step 2: Conferir as duas branches que ficam**

```bash
scripts/branch-protection.sh check develop
scripts/branch-protection.sh check master
```

Expected: `ok develop` e `ok master`. **Se qualquer um falhar, pare aqui**: `feature/rust` continua protegida, a default continua `master` e nada foi removido.

- [ ] **Step 3: Trocar a branch padrão para `develop`**

```bash
gh repo edit hbgit/map2check-library --default-branch develop
gh repo view hbgit/map2check-library --json defaultBranchRef --jq .defaultBranchRef.name
```

Expected: `develop`. Sem `gh`: Settings → General → Default branch → `develop`. Esse passo vale mesmo que a remoção das branches seja cancelada depois, porque faz parte do novo fluxo e não depende da limpeza.

- [ ] **Step 4: Remover a proteção de `feature/rust`** (logo antes da Task 6)

```bash
gh api -X DELETE repos/hbgit/map2check-library/branches/feature%2Frust/protection
gh api repos/hbgit/map2check-library/branches/feature%2Frust --jq .protected
```

Expected: `false`.

### Task 6: Arquivar e remover em lote, com confirmação

**Files:**
- Create: `~/map2check-branch-cleanup-2026-10-15.log`

**Interfaces:**
- Consumes: `LEASES`, `DELS` e `TAGS` da Task 4, Step 1.

- [ ] **Step 1: Executar**

```bash
read -r -p "Digite REMOVER para apagar ${#DELS[@]} branches de origin: " ok
if [[ $ok == REMOVER ]]; then
  { [[ ${#TAGS[@]} -eq 0 ]] || git push origin "${TAGS[@]}"; } &&
  git push --atomic origin "${LEASES[@]}" "${DELS[@]}" 2>&1 | tee ~/map2check-branch-cleanup-2026-10-15.log
else
  echo "Cancelado; nada foi removido. Reaplique a proteção de feature/rust (Task 9, Step 4)."
fi
```

Expected: a tag sobe primeiro e depois as 11 linhas `- [deleted]`. Com `--atomic`, qualquer rejeição (lease divergente, branch ainda protegida) cancela o lote inteiro. Nesse caso, investigue e, se for desistir, reaplique a proteção de `feature/rust` (Task 9, Step 4, sem o `git push` da branch, que ainda existe).

### Task 7: Prune e verificação

**Files:** nenhum.

- [ ] **Step 1: Podar e conferir o remoto**

```bash
git fetch --prune origin
git remote set-head origin --auto     # o clone local ainda aponta origin/HEAD para master
git branch -r
git ls-remote --tags origin 'archive/*'
gh api repos/hbgit/map2check-library/branches --jq '.[]|"\(.name) protected=\(.protected)"'
gh repo view hbgit/map2check-library --json defaultBranchRef --jq .defaultBranchRef.name
```

Expected: `origin/HEAD set to develop`; depois `origin/HEAD -> origin/develop`, `origin/develop` e `origin/master`; a tag `archive/memory_check` → `f287e99…`; `develop protected=true` e `master protected=true`; default `develop`. Outros clones existentes precisam rodar o mesmo `git remote set-head origin --auto` uma vez.

- [ ] **Step 2 (opcional, local): limpar branches com upstream sumido**

```bash
git switch develop && git pull --ff-only
git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | awk '$2=="[gone]"{print $1}'
git branch -d <branch>     # para cada uma revisada; -d recusa trabalho não mergeado; nunca -D
```

Expected: `feature/rust` e as 7 branches locais de issue/feat aparecem como `[gone]`; `master` e `develop` não aparecem.

---

## FASE 3 — PREVENÇÃO E REVERSÃO

### Task 8 (opcional, `gh`): Prevenir acúmulo

- [ ] **Step 1: Auto-delete após merge** (hoje `deleteBranchOnMerge=false`)

```bash
gh repo edit hbgit/map2check-library --delete-branch-on-merge
gh repo view hbgit/map2check-library --json deleteBranchOnMerge
```

Expected: `{"deleteBranchOnMerge":true}`. Branches protegidas (`master`, `develop`) nunca são apagadas por esse recurso. Sem `gh`: Settings → General → Pull Requests → "Automatically delete head branches".

- [ ] **Step 2: Convenção de nomes:** `<tipo>/issue-<N>-<slug>` para trabalho, `release/<versão>` para estabilização (CI já dispara em `release/**`) e nada além de `master`/`develop` como branch de longa duração.

- [ ] **Step 3: Revisão periódica:** repetir a Task 2, Step 3 a cada trimestre (próxima: 2027-01-15), com o mesmo portão da Task 3.

### Task 9: Reversão (só em caso de remoção por engano)

- [ ] **Step 1: Pelo hash do relatório**

```bash
B=feat/M3_paridade   # exemplo
SHA=$(awk -F'\t' -v b="$B" '$1==b{print $4}' ~/map2check-branch-cleanup-2026-10-15.tsv)
git fetch origin "$SHA" 2>/dev/null || true
git push origin "$SHA:refs/heads/$B"
```

Os commits de todas as branches A continuam alcançáveis por `develop`/`master`, então o hash nunca some.

- [ ] **Step 2: Pela tag de arquivo (categoria B)**

```bash
git push origin refs/tags/archive/memory_check:refs/heads/memory_check
```

- [ ] **Step 3: Pelo reflog local** (se o relatório se perdeu)

```bash
git reflog show --date=iso refs/remotes/origin/<branch>
git push origin <hash>:refs/heads/<branch>
```

Ou, no GitHub: na página do PR mergeado, botão "Restore branch".

- [ ] **Step 4: Restaurar `feature/rust` com a proteção antiga**

```bash
git push origin 3813ddef6b01b3f913a2021d64901f055f6cbb59:refs/heads/feature/rust
scripts/branch-protection.sh payload develop |
  gh api -X PUT repos/hbgit/map2check-library/branches/feature%2Frust/protection --input - >/dev/null
gh api -X POST repos/hbgit/map2check-library/branches/feature%2Frust/protection/required_signatures >/dev/null
gh api repos/hbgit/map2check-library/branches/feature%2Frust/protection \
  --jq '{checks:[.required_status_checks.checks[].context], sig:.required_signatures.enabled, del:.allow_deletions.enabled}'
```

Expected: o mesmo `{"checks":["build_and_test"],"sig":true,"del":false}` guardado em `~/map2check-feature-rust-protection-2026-10-15.json` (o payload de `develop` é idêntico ao antigo de `feature/rust`). Para o CI voltar a rodar em `feature/rust`, reverta também o commit da Task 1.

- [ ] **Step 5: Voltar a branch padrão para `master`** (só se o novo fluxo for abandonado)

```bash
gh repo edit hbgit/map2check-library --default-branch master
git remote set-head origin --auto
```

Expected: `gh repo view hbgit/map2check-library --json defaultBranchRef --jq .defaultBranchRef.name` imprime `master`.

Em qualquer caso, `git ls-remote --heads origin <branch>` volta a mostrar o hash original.
