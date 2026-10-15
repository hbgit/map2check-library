# Issue #26: proteção de branches com CI obrigatório (plano de implementação)

> **Para agentes:** SUB-SKILL OBRIGATÓRIA: use superpowers:subagent-driven-development (recomendado) ou superpowers:executing-plans para executar este plano tarefa a tarefa. Os passos usam checkbox (`- [ ]`).

**Objetivo:** proteger `feature/rust` e `master` no GitHub e tornar o check `build_and_test` do workflow "CI Map2Check Rust" obrigatório nas duas. A configuração fica versionada num script idempotente e verificável.

**Arquitetura:**
- `scripts/branch-protection.sh` define a proteção desejada de cada branch como payload JSON. Ele tem três subcomandos:
  - `payload` é puro e testável offline.
  - `check` faz GET na API e compara com o desejado (exit 0 ou 1). É o RED/GREEN da tarefa.
  - `apply` faz o PUT da proteção e o POST de `required_signatures`.
- Um teste offline (`scripts/test-branch-protection.sh`) valida os payloads e confere se o nome do check bate com o job em `CI.yml`.
- O PR que entrega o script em `feature/rust` é o teste ponta a ponta: o check precisa aparecer como *required*.

**Stack:** bash, `gh` (autenticado como `hbgit`, com permissão admin), `jq` 1.x e a REST API de branch protection do GitHub.

**Spec:** issue #26 (https://github.com/hbgit/map2check-library/issues/26) e o rascunho em `audit/issues/M1-DoD2.md`. A origem é o item M1 DoD de `docs/plano_map2check_library_rust.md`: "CI verde obrigatório em PR; branch protegida". A issue também cobre M1-DoD1.

## Critérios de aceitação (copiados da issue)

- [ ] `feature/rust` protegida com o required status check `build_and_test` (workflow "CI Map2Check Rust").
- [ ] O mesmo check exigido em `master`.
- [ ] Assinatura de commits exigida em `feature/rust`, como já ocorre em `master`.

## Estado verificado em 2026-10-14 (ponto de partida)

- `GET .../branches/feature%2Frust/protection` → HTTP 404 "Branch not protected".
- `master` está protegida com:
  - `required_pull_request_reviews.required_approving_review_count = 1`;
  - `required_signatures.enabled = true`;
  - `enforce_admins = false`;
  - `allow_force_pushes = false` e `allow_deletions = false`;
  - **`required_status_checks` ausente**.
- O repositório não tem rulesets: `GET .../rulesets` → `[]`.
- O check-run do CI se chama `build_and_test`, com `app.id = 15368` (`github-actions`), conforme o commit `b0e04ad`.
- O CI em `master` falha nos 3 últimos pushes (`a72f63e`, `bcc4ed0`, `337c2dd`). Ver Review Focus 4.

## Restrições globais

- "Commits must have verified signatures." Commits assinados via SSH (`commit.gpgsign=true`).
- "Never add AI attributions (e.g. "Co-authored-by", "Generated with ...") to commits or PR descriptions."
- **Alterar a proteção de branches no GitHub é uma ação externa num repositório compartilhado.** Antes de cada `apply` (Tarefas 2 e 3), o executor para e pede aprovação explícita do usuário, mostrando o payload que vai enviar.
- Não usar `enforce_admins=true`: o mantenedor é o único admin e precisa de bypass de emergência.
- Não exigir review em `feature/rust`: o único mantenedor não consegue aprovar o próprio PR, e a issue não pede isso.
- `strict=false` (não exigir branch atualizada com a base), para evitar rebases forçados num projeto de um mantenedor. A issue não pede isso.
- Não criar ruleset. A proteção clássica é o que a auditoria mediu (`evidence/protection.txt`).
- `develop` fica fora do escopo.

## Review Focus

1. **O PUT sobrescreve a proteção inteira.** Aplicar em `master` sem repetir a regra de 1 review apagaria essa regra. Esperado: `check master` exige que o review continue lá e a Tarefa 3 compara o antes e o depois.
2. **Branch com barra.** `feature/rust` precisa virar `feature%2Frust` na URL; sem isso, a API devolve 404 e o `check` dá um falso RED. Esperado: o teste offline cobre a codificação.
3. **Job renomeado.** Se `build_and_test` mudar de nome no `CI.yml`, o check obrigatório nunca reporta e todos os PRs ficam bloqueados para sempre. Esperado: o teste offline falha se o job não existir no `CI.yml`.
4. **O CI de `master` está vermelho hoje.** Depois da Tarefa 3, um PR para `master` só mescla se o CI do head passar. Um PR vindo de `feature/rust` passa; um PR só de docs vindo de `develop` (a árvore de `master`, sem ajustes) pode ficar bloqueado. Esperado: documentar no README e no comentário de fechamento; o admin ainda pode fazer bypass.
5. **Ferramenta ausente ou sem permissão.** Sem `gh`, sem `jq` ou sem permissão admin, o script deve sair com mensagem clara e código ≠ 0, nunca "passar" em silêncio. Esperado: o teste offline cobre o subcomando inválido e a branch desconhecida; `check` trata 404 como falha.

---

## Estrutura de arquivos

| Arquivo | Responsabilidade |
|---|---|
| `scripts/branch-protection.sh` (novo) | Payload desejado por branch, verificação (`check`) e aplicação (`apply`) |
| `scripts/test-branch-protection.sh` (novo) | Teste offline dos payloads e da coerência com o `CI.yml` |
| `.github/workflows/CI.yml` (modificar) | Roda o teste offline no job `build_and_test` |
| `README.md` (modificar) | Nova subseção "Proteção de branches" em "Linting e auditoria" |

Trabalho numa worktree nova, `../map2check-library-issue26`, na branch `ci/issue-26-branch-protection` criada a partir de `origin/feature/rust`, que já inclui o PR #30.

---

### Tarefa 1: script de proteção e teste offline

**Arquivos:**
- Criar: `scripts/branch-protection.sh`
- Criar: `scripts/test-branch-protection.sh`
- Modificar: `.github/workflows/CI.yml`, depois do step `Run tests`
- Modificar: `README.md`, no fim da seção "Linting e auditoria" (antes de `## Arquitetura`)

**Interfaces:**
- Produz:
  - `scripts/branch-protection.sh payload <branch>`: imprime JSON no stdout; exit 2 se a branch for desconhecida.
  - `scripts/branch-protection.sh check <branch>`: exit 0 se a proteção remota contiver o desejado; 1 caso contrário, listando o que falta.
  - `scripts/branch-protection.sh apply <branch>`: faz o PUT e o POST de signatures e depois roda `check`.
  - `scripts/branch-protection.sh encode <branch>`: imprime o nome codificado para URL.
  - Variáveis de ambiente: `REPO` (padrão `hbgit/map2check-library`), `CI_CHECK` (padrão `build_and_test`), `CI_APP_ID` (padrão `15368`).

- [ ] **Passo 0: criar a worktree**

```bash
cd /home/rock/Documents/Dev/map2check-library
git fetch origin
git worktree add -b ci/issue-26-branch-protection ../map2check-library-issue26 origin/feature/rust
cd ../map2check-library-issue26
```

- [ ] **Passo 1: escrever o teste que falha**

`scripts/test-branch-protection.sh`:

```bash
#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Teste offline de scripts/branch-protection.sh (não chama a API do GitHub).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BP="$ROOT/scripts/branch-protection.sh"
fail=0
ok()  { echo "ok   - $1"; }
bad() { echo "FAIL - $1"; fail=1; }
t()   { local name="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi; }

# Codificação de nomes com barra (Review Focus 2)
t "encode feature/rust"  test "$("$BP" encode feature/rust)" = "feature%2Frust"
t "encode master"        test "$("$BP" encode master)" = "master"

# feature/rust: check obrigatório, sem review, sem force push/deleção
fr="$("$BP" payload feature/rust 2>/dev/null || true)"
t "fr: check build_and_test (app 15368)" jq -e '.required_status_checks.checks == [{"context":"build_and_test","app_id":15368}]' <<<"$fr"
t "fr: strict false"          jq -e '.required_status_checks.strict == false' <<<"$fr"
t "fr: sem review"            jq -e '.required_pull_request_reviews == null' <<<"$fr"
t "fr: enforce_admins false"  jq -e '.enforce_admins == false' <<<"$fr"
t "fr: sem force push"        jq -e '.allow_force_pushes == false and .allow_deletions == false' <<<"$fr"
t "fr: restrictions null"     jq -e 'has("restrictions") and .restrictions == null' <<<"$fr"

# master: mesmo check e preserva 1 review (Review Focus 1)
ms="$("$BP" payload master 2>/dev/null || true)"
t "master: check build_and_test" jq -e '.required_status_checks.checks == [{"context":"build_and_test","app_id":15368}]' <<<"$ms"
t "master: 1 review preservado"  jq -e '.required_pull_request_reviews.required_approving_review_count == 1' <<<"$ms"
t "master: enforce_admins false" jq -e '.enforce_admins == false' <<<"$ms"

# Branch desconhecida e subcomando inválido falham (Review Focus 5)
t "branch desconhecida -> exit 2" bash -c '"$0" payload develop; test $? -eq 2' "$BP"
t "subcomando inválido -> exit 2" bash -c '"$0" frobnicate master; test $? -eq 2' "$BP"

# O check obrigatório existe como job no CI (Review Focus 3)
t "CI.yml tem job build_and_test" grep -qE '^  build_and_test:' "$ROOT/.github/workflows/CI.yml"

exit "$fail"
```

```bash
chmod +x scripts/test-branch-protection.sh
```

- [ ] **Passo 2: rodar e ver falhar**

Rodar: `scripts/test-branch-protection.sh; echo rc=$?`
Esperado: as linhas `FAIL -` das verificações que dependem de `branch-protection.sh` (que ainda não existe) e `rc=1`. Só `CI.yml tem job build_and_test` aparece como `ok`.

- [ ] **Passo 3: implementar `scripts/branch-protection.sh`**

```bash
#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Proteção de branches do repositório (issue #26 / plano M1 DoD).
#   payload <branch>  imprime o JSON desejado (offline)
#   check   <branch>  compara a proteção remota com a desejada (exit 0/1)
#   apply   <branch>  aplica a proteção desejada e roda check
#   encode  <branch>  nome da branch codificado para URL
set -euo pipefail

REPO="${REPO:-hbgit/map2check-library}"
CI_CHECK="${CI_CHECK:-build_and_test}"
CI_APP_ID="${CI_APP_ID:-15368}"

usage() { echo "uso: $0 {payload|check|apply|encode} {feature/rust|master}" >&2; exit 2; }
need()  { command -v "$1" >/dev/null || { echo "erro: '$1' não encontrado" >&2; exit 2; }; }

encode() { jq -rn --arg b "$1" '$b|@uri'; }

payload() {
  local reviews
  case "$1" in
    feature/rust) reviews='null' ;;
    master)       reviews='{"dismiss_stale_reviews":false,"require_code_owner_reviews":false,"required_approving_review_count":1}' ;;
    *) echo "erro: branch sem proteção definida: $1" >&2; exit 2 ;;
  esac
  jq -n --arg ctx "$CI_CHECK" --argjson app "$CI_APP_ID" --argjson reviews "$reviews" '{
    required_status_checks: {strict: false, checks: [{context: $ctx, app_id: $app}]},
    enforce_admins: false,
    required_pull_request_reviews: $reviews,
    restrictions: null,
    allow_force_pushes: false,
    allow_deletions: false
  }'
}

check() {
  local b="$1" want got errs
  want="$(payload "$b")"
  if ! got="$(gh api "repos/$REPO/branches/$(encode "$b")/protection" 2>/dev/null)"; then
    echo "FAIL $b: branch não protegida (ou sem acesso)"; return 1
  fi
  errs="$(jq -r -n --argjson w "$want" --argjson g "$got" --arg b "$b" '
    ($w.required_status_checks.checks[0].context) as $ctx
    | ($w.required_pull_request_reviews.required_approving_review_count // 0) as $rev
    | [ (if ($g.required_status_checks.checks // []) | any(.context == $ctx) then empty
         else "check obrigatório \($ctx) ausente" end),
        (if $g.required_signatures.enabled == true then empty else "assinatura de commits não exigida" end),
        (if $g.allow_force_pushes.enabled == false then empty else "force push permitido" end),
        (if $g.allow_deletions.enabled == false then empty else "deleção permitida" end),
        (if ($g.required_pull_request_reviews.required_approving_review_count // 0) >= $rev then empty
         else "review obrigatório perdido" end) ]
    | .[] | "FAIL \($b): \(.)"')"
  if [ -n "$errs" ]; then echo "$errs"; return 1; fi
  echo "ok $b"
}

apply() {
  local b="$1" enc
  enc="$(encode "$b")"
  payload "$b" | gh api -X PUT "repos/$REPO/branches/$enc/protection" --input - >/dev/null
  gh api -X POST "repos/$REPO/branches/$enc/protection/required_signatures" >/dev/null
  check "$b"
}

need jq
[ $# -eq 2 ] || usage
case "$1" in
  payload) payload "$2" ;;
  encode)  encode "$2" ;;
  check)   need gh; check "$2" ;;
  apply)   need gh; apply "$2" ;;
  *) usage ;;
esac
```

```bash
chmod +x scripts/branch-protection.sh
```

- [ ] **Passo 4: rodar o teste e ver passar**

Rodar: `scripts/test-branch-protection.sh; echo rc=$?`
Esperado: todas as linhas `ok -` e `rc=0`.

- [ ] **Passo 5: rodar o teste no CI**

Em `.github/workflows/CI.yml`, logo depois do step `Run tests` (`run: cargo test --all-features`), acrescentar:

```yaml
      - name: Test branch protection script
        run: scripts/test-branch-protection.sh
```

O runner `ubuntu-latest` já traz `jq`.

- [ ] **Passo 6: documentar no README**

Antes de `## Arquitetura`, inserir:

~~~markdown
### Proteção de branches

`feature/rust` e `master` exigem o check `build_and_test` (workflow "CI Map2Check Rust") e commits assinados; `master` exige também 1 review. A configuração está em `scripts/branch-protection.sh`:

```sh
scripts/branch-protection.sh check feature/rust   # compara com o GitHub (exit 0/1)
scripts/branch-protection.sh apply master         # requer permissão de admin
```

Se o job `build_and_test` for renomeado, atualize `CI_CHECK` no script na mesma mudança; caso contrário, todo PR fica bloqueado esperando um check que nunca chega.
~~~

- [ ] **Passo 7: commit (assinado, sem atribuição de IA)**

```bash
git add scripts/branch-protection.sh scripts/test-branch-protection.sh .github/workflows/CI.yml README.md
git commit -m "ci: version branch protection for feature/rust and master (#26)"
git log -1 --show-signature | head -3   # Esperado: "Good \"git\" signature"
```

---

### Tarefa 2: proteger `feature/rust`

**Arquivos:** nenhum. Ação na API. A evidência fica no scratchpad: `SCRATCH=/tmp/claude-1000/-home-rock-Documents-Dev-map2check-library/bebe49e7-bdb8-4d51-a37a-11f8904d7334/scratchpad` (ou outro diretório temporário; defina `SCRATCH` antes dos comandos).

**Interfaces:**
- Consome: `scripts/branch-protection.sh check|apply feature/rust` (Tarefa 1).

- [ ] **Passo 1: RED ao vivo**

Rodar: `scripts/branch-protection.sh check feature/rust; echo rc=$?`
Esperado: `FAIL feature/rust: branch não protegida (ou sem acesso)` e `rc=1`.

- [ ] **Passo 2: PARAR e pedir aprovação ao usuário**

Mostrar a saída de `scripts/branch-protection.sh payload feature/rust` e o POST de `required_signatures`. Só seguir depois de um "sim" explícito.

- [ ] **Passo 3: aplicar**

Rodar: `scripts/branch-protection.sh apply feature/rust; echo rc=$?`
Esperado: `ok feature/rust` e `rc=0`.

- [ ] **Passo 4: conferir o JSON bruto e guardar evidência**

```bash
gh api repos/hbgit/map2check-library/branches/feature%2Frust/protection \
  | tee "$SCRATCH/protection-feature-rust-after.json" \
  | jq '{checks:.required_status_checks.checks, strict:.required_status_checks.strict, sig:.required_signatures.enabled, reviews:.required_pull_request_reviews}'
```

Esperado: `checks` = `[{"context":"build_and_test","app_id":15368}]`, `strict=false`, `sig=true`, `reviews=null`.

- [ ] **Passo 5: confirmar que `check` detecta uma regressão (teste do próprio verificador)**

```bash
CI_CHECK=nao_existe scripts/branch-protection.sh check feature/rust; echo rc=$?
```

Esperado: `FAIL feature/rust: check obrigatório nao_existe ausente` e `rc=1`.

**Rollback (se necessário):** `gh api -X DELETE repos/hbgit/map2check-library/branches/feature%2Frust/protection`.

---

### Tarefa 3: exigir o check em `master` sem perder o que já existe

**Arquivos:** nenhum. Ação na API. Usa o mesmo `SCRATCH` da Tarefa 2.

**Interfaces:**
- Consome: `scripts/branch-protection.sh check|apply master` (Tarefa 1).

- [ ] **Passo 1: backup e RED ao vivo**

```bash
gh api repos/hbgit/map2check-library/branches/master/protection > "$SCRATCH/protection-master-before.json"
scripts/branch-protection.sh check master; echo rc=$?
```

Esperado: `FAIL master: check obrigatório build_and_test ausente` e `rc=1`, sem outros `FAIL`, porque review, assinatura, force push e deleção já estão corretos.

- [ ] **Passo 2: PARAR e pedir aprovação ao usuário**

Mostrar `scripts/branch-protection.sh payload master` e avisar do Review Focus 4: o CI de `master` está vermelho hoje, então PRs para `master` cujo head não passe no CI ficam bloqueados, salvo bypass do admin. Só seguir depois de um "sim" explícito.

- [ ] **Passo 3: aplicar**

Rodar: `scripts/branch-protection.sh apply master; echo rc=$?`
Esperado: `ok master` e `rc=0`.

- [ ] **Passo 4: comparar o antes e o depois (Review Focus 1)**

```bash
gh api repos/hbgit/map2check-library/branches/master/protection > "$SCRATCH/protection-master-after.json"
for f in before after; do
  jq -c '{rev:.required_pull_request_reviews.required_approving_review_count, sig:.required_signatures.enabled,
          admins:.enforce_admins.enabled, fp:.allow_force_pushes.enabled, del:.allow_deletions.enabled,
          checks:[.required_status_checks.checks[]?.context]}' "$SCRATCH/protection-master-$f.json"
done
```

Esperado: as duas linhas são iguais, exceto em `checks`, que vai de `[]` para `["build_and_test"]`.

**Rollback (se necessário):** recriar a partir do backup, com reviews=1 e sem status checks:

```bash
jq -n '{required_status_checks:null, enforce_admins:false, required_pull_request_reviews:{required_approving_review_count:1}, restrictions:null, allow_force_pushes:false, allow_deletions:false}' \
  | gh api -X PUT repos/hbgit/map2check-library/branches/master/protection --input -
gh api -X POST repos/hbgit/map2check-library/branches/master/protection/required_signatures
```

---

### Tarefa 4: verificação ponta a ponta via PR e fechamento

**Arquivos:** nenhum novo. Esta tarefa entrega a branch da Tarefa 1.

- [ ] **Passo 1: push e PR para `feature/rust`**

Push de uma branch nova não é push numa branch compartilhada, mas o executor ainda confirma com o usuário antes de abrir o PR.

```bash
git push -u origin ci/issue-26-branch-protection
gh pr create --base feature/rust --head ci/issue-26-branch-protection \
  --title "ci: protect feature/rust and master with required CI (#26)" \
  --body "Closes #26. Versiona a proteção de branches em scripts/branch-protection.sh, aplicada em feature/rust e master: check obrigatório build_and_test, assinatura obrigatória e master com 1 review. Inclui teste offline rodado no CI."
```

O corpo do PR não leva nenhuma atribuição de IA.

- [ ] **Passo 2: o check aparece como obrigatório e bloqueia enquanto roda**

```bash
gh pr view --json mergeStateStatus,statusCheckRollup \
  -q '{state:.mergeStateStatus, checks:[.statusCheckRollup[]|{name,status,conclusion}]}'
gh api graphql -f query='query{repository(owner:"hbgit",name:"map2check-library"){pullRequest(number:'"$(gh pr view --json number -q .number)"'){commits(last:1){nodes{commit{checkSuites(first:5){nodes{checkRuns(first:5){nodes{name isRequired(pullRequestNumber:'"$(gh pr view --json number -q .number)"')}}}}}}}}}}' \
  -q '..|objects|select(has("isRequired"))'
```

Esperado:
- Com o CI ainda rodando, `mergeStateStatus` é `BLOCKED`.
- `{"name":"build_and_test","isRequired":true}`.

- [ ] **Passo 3: esperar o CI terminar verde**

Rodar: `gh pr checks --watch`
Esperado: `build_and_test` com `pass`, incluindo o novo step "Test branch protection script". Depois disso, `mergeStateStatus` passa a `CLEAN`.

- [ ] **Passo 4: o merge é do usuário**

Mesclar no branch compartilhado cabe ao usuário, como no PR #30. Depois do merge:

```bash
scripts/branch-protection.sh check feature/rust && scripts/branch-protection.sh check master
```

Esperado: `ok feature/rust`, `ok master` e exit 0. Como o PR tem "Closes #26" e a base não é a branch padrão, a issue não fecha sozinha. Fechar com:

```bash
gh issue close 26 --comment "Resolvida pelo PR #<N> (merge <sha>). feature/rust e master exigem o check build_and_test e commits assinados; master mantém 1 review. Configuração versionada em scripts/branch-protection.sh (check/apply). Observação: o CI de master está vermelho na árvore atual, então PRs para master só mesclam se o CI do head passar (o admin pode fazer bypass)."
```

- [ ] **Passo 5: limpeza**

```bash
cd /home/rock/Documents/Dev/map2check-library
git worktree remove ../map2check-library-issue26
git branch -d ci/issue-26-branch-protection
```

---

## Autorrevisão

- **Cobertura da spec:**
  - Critério 1 (`feature/rust` com check): Tarefa 2.
  - Critério 2 (check em `master`): Tarefa 3.
  - Critério 3 (assinatura em `feature/rust`): `apply` faz o POST de `required_signatures`, e `check` verifica em Tarefa 2/Passo 3.
  - "CI verde obrigatório em PR": Tarefa 4/Passo 2 (`isRequired: true`).
- **Placeholders:** só `<N>` e `<sha>` no comentário de fechamento, que vêm do PR criado na mesma tarefa.
- **Consistência:**
  - Nomes: `payload`, `check`, `apply` e `encode`, além de `CI_CHECK=build_and_test` e `CI_APP_ID=15368`, são os mesmos nas Tarefas 1 a 4.
  - Mensagens de `FAIL` esperadas nas Tarefas 2 e 3 batem com as de `check`.
- **Review Focus:**
  - 1: teste offline mais a Tarefa 3/Passo 4.
  - 2: teste `encode`.
  - 3: teste do `CI.yml` mais a nota no README.
  - 4: aviso na Tarefa 3/Passo 2, no README e no comentário de fechamento.
  - 5: testes de branch desconhecida e subcomando inválido, mais `check` tratando 404 como FAIL.
