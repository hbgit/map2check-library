# Issue #27 — Remover artefatos mortos da era C — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar a issue #27 (Audit-ID M1-I5) removendo de `feature/rust` os artefatos de documentação da era C que ainda são rastreados e impedindo, via CI, que artefatos de build/IDE/doc da era C voltem ao repositório.

**Architecture:** Um script bash `scripts/check-no-c-era-artifacts.sh` lê a lista de arquivos rastreados (`git ls-files`, ou stdin para teste) e falha se algum caminho casar com padrões da era C. Um teste offline (`scripts/test-check-no-c-era-artifacts.sh`, no mesmo estilo de `scripts/test-branch-protection.sh`) fixa o comportamento. Depois os arquivos são removidos com `git rm` e o guard entra no job `build_and_test` do CI.

**Tech Stack:** bash, git, GitHub Actions (`.github/workflows/CI.yml`), `gh` CLI.

**Spec:** Issue GitHub `hbgit/map2check-library#27` — "chore: remove C-era dead artifacts (.clangd, compile_commands.json, .travis.yml, .vscode, stale docs)". Fonte da issue: `docs/plano_map2check_library_rust.md` (M1 — Issue 5) e `audit/relatorio_auditoria.md`.

## Verificação (estado em 2026-10-14, `origin/feature/rust` @ `f30f67d`)

| Item da issue | Estado |
|---|---|
| `.clangd`, `compile_commands.json`, `.travis.yml`, `.vscode` | ✅ já não rastreados |
| `run_klee_test.sh` | ✅ já removido em `origin/feature/rust` (ainda existe no checkout local, que está atrasado) |
| `docs/Doxyfile` (Doxygen 1.8.13 da lib C) | ❌ rastreado |
| `docs/C map2checklibrary.xmi`, `docs/map2checklibrary.xmi` (UML da lib C) | ❌ rastreados |
| `docs/imgs/class-diagram.png` (diagrama de classes C: `TAILQ`, `sys/queue.h`, `container_*`) | ❌ rastreado, **não referenciado** em nenhum arquivo — não citado na issue, mas é o export do mesmo UML C |
| `docs/imgs/map2check-flowchart.png` | ✅ manter — referenciado em `README.md:189` (fluxo da ferramenta Map2Check, não da implementação C) |
| `docs/api-deltas.md`, `docs/superpowers/plans/*` | ✅ manter — documentação da era Rust |

Nada no repositório referencia `Doxyfile`, `*.xmi` ou `class-diagram.png` (verificado com `git grep`); nenhum job do CI gera Doxygen.

**Decisão:** remover (não mover para `docs/legacy-c/`). A issue aceita as duas opções; o histórico git preserva os arquivos (último commit com eles: `f30f67d`), e manter UML de uma implementação que não existe mais na branch só gera confusão. A nota sobre onde encontrá-los vai na mensagem de commit e no corpo do PR.

## Global Constraints

- Branch base: `feature/rust` (protegida; exige PR com `build_and_test` verde — issue #26).
- Scripts novos começam com `#!/usr/bin/env bash`, `# SPDX-License-Identifier: GPL-3.0-only` e `set -euo pipefail`, como `scripts/test-branch-protection.sh`.
- Mensagens/comentários em português, como o restante de `scripts/` e do `CI.yml`.
- Commits terminam com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; corpo do PR termina com `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
- Não tocar em `docs/imgs/map2check-flowchart.png` nem em `README.md`.

## Review Focus

1. Nome de arquivo com espaço (`docs/C map2checklibrary.xmi`) — o guard deve detectá-lo como um único caminho, não quebrar em dois. → teste em Task 1.
2. Falsos positivos em arquivos Rust legítimos com nomes parecidos (`build.rs` vs `build.sh`, `.cargo/config.toml`, `docs/imgs/map2check-flowchart.png`, `scripts/coverage.sh`) — devem passar. → teste em Task 1.
3. Artefatos aninhados (`rust/.vscode/settings.json`, `sub/CMakeLists.txt`) — devem ser pegos, não só na raiz. → teste em Task 1.
4. Repositório limpo deve sair com código 0 e sem saída em stderr; sujo deve sair com 1 e listar **cada** caminho ofensor (para o log do CI ser acionável). → teste em Task 1.
5. Após a remoção, a imagem referenciada pelo README continua existindo (remoção não pode quebrar o README). → verificação em Task 2.

---

### Task 0: Sincronizar o checkout local

O checkout local (`0d60baf`) está atrás de `origin/feature/rust` (`f30f67d`) — sem isso, `scripts/`, `docs/superpowers/plans/` e o `CI.yml` atual não existem localmente.

- [ ] **Step 1: Atualizar e criar a branch de trabalho**

```bash
git fetch origin
git switch feature/rust
git pull --ff-only origin feature/rust
git switch -c chore/issue-27-remove-c-era-docs
```

Expected: `git log --oneline -1` mostra `f30f67d` (ou mais novo); `ls scripts/` lista `branch-protection.sh coverage.sh test-branch-protection.sh`.

- [ ] **Step 2: Reconfirmar o estado da verificação**

```bash
git ls-files docs/
git grep -n -I -E 'Doxyfile|\.xmi|class-diagram' -- . ':!docs/Doxyfile' ':!docs/*.xmi'
```

Expected: `docs/` lista os 4 arquivos C-era + `api-deltas.md`, `imgs/map2check-flowchart.png` e os planos; o `git grep` não imprime nada. Se algo mudou (ex.: alguém já removeu os arquivos), ajuste a Task 2 em vez de seguir cegamente.

---

### Task 1: Guard `check-no-c-era-artifacts.sh` + teste offline

**Files:**
- Create: `scripts/check-no-c-era-artifacts.sh`
- Create: `scripts/test-check-no-c-era-artifacts.sh`

**Interfaces:**
- Produces: `scripts/check-no-c-era-artifacts.sh [--stdin]`
  - sem argumento: avalia `git ls-files` a partir da raiz do repo;
  - `--stdin`: avalia a lista de caminhos (um por linha) lida de stdin;
  - saída 0 e nada em stdout quando limpo; saída 1 e uma linha `C-era artifact: <caminho>` por ofensor em stderr quando sujo; saída 2 para argumento inválido.

- [ ] **Step 1: Escrever o teste (falha porque o script não existe)**

`scripts/test-check-no-c-era-artifacts.sh`:

```bash
#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Teste offline de scripts/check-no-c-era-artifacts.sh (issue #27).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHK="$ROOT/scripts/check-no-c-era-artifacts.sh"
fail=0
ok() { echo "ok - $1"; }
bad() { echo "FAIL - $1"; fail=1; }
# rejects NOME CAMINHO: o guard deve sair 1 e citar o caminho
rejects() {
  local out rc=0
  out="$(printf '%s\n' "$2" | "$CHK" --stdin 2>&1)" || rc=$?
  if [ "$rc" -eq 1 ] && grep -qxF "C-era artifact: $2" <<<"$out"; then ok "$1"; else bad "$1 (rc=$rc out=$out)"; fi
}
# accepts NOME CAMINHO: o guard deve sair 0 sem saída
accepts() {
  local out rc=0
  out="$(printf '%s\n' "$2" | "$CHK" --stdin 2>&1)" || rc=$?
  if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok "$1"; else bad "$1 (rc=$rc out=$out)"; fi
}

# Artefatos citados na issue
rejects ".clangd" ".clangd"
rejects "compile_commands.json" "compile_commands.json"
rejects ".travis.yml" ".travis.yml"
rejects ".vscode" ".vscode/settings.json"
rejects "Doxyfile" "docs/Doxyfile"
rejects "xmi com espaço (Review Focus 1)" "docs/C map2checklibrary.xmi"
rejects "xmi" "docs/map2checklibrary.xmi"
rejects "diagrama de classes C" "docs/imgs/class-diagram.png"
# Build C/CMake
rejects "CMakeLists" "CMakeLists.txt"
rejects "módulo cmake" "cmake/FindGTest.cmake"
rejects "build.sh" "build.sh"
rejects "run_klee_test.sh" "run_klee_test.sh"
# Aninhados (Review Focus 3)
rejects ".vscode aninhado" "rust/.vscode/launch.json"
rejects "CMakeLists aninhado" "test/CMakeLists.txt"

# Arquivos legítimos da era Rust (Review Focus 2)
accepts "build.rs" "build.rs"
accepts ".cargo/config.toml" ".cargo/config.toml"
accepts "flowchart do README" "docs/imgs/map2check-flowchart.png"
accepts "coverage.sh" "scripts/coverage.sh"
accepts "run_libfuzzer_test.sh" "run_libfuzzer_test.sh"
accepts "api-deltas" "docs/api-deltas.md"

# Lista mista: lista todos os ofensores, um por linha (Review Focus 4)
rc=0
out="$(printf '%s\n' build.rs docs/Doxyfile README.md "docs/C map2checklibrary.xmi" | "$CHK" --stdin 2>&1)" || rc=$?
if [ "$rc" -eq 1 ] && [ "$(grep -c '^C-era artifact: ' <<<"$out")" -eq 2 ]; then ok "lista mista: 2 ofensores"; else bad "lista mista (rc=$rc out=$out)"; fi

# Lista vazia é limpa
rc=0; out="$("$CHK" --stdin </dev/null 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok "lista vazia"; else bad "lista vazia (rc=$rc)"; fi

# Argumento inválido → 2
rc=0; "$CHK" --bogus >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 2 ]; then ok "argumento inválido sai 2"; else bad "argumento inválido (rc=$rc)"; fi

# Guard ligado no CI
if grep -qF 'scripts/check-no-c-era-artifacts.sh' "$ROOT/.github/workflows/CI.yml"; then ok "CI roda o guard"; else bad "CI roda o guard"; fi

exit "$fail"
```

```bash
chmod +x scripts/test-check-no-c-era-artifacts.sh
```

- [ ] **Step 2: Rodar o teste e confirmar a falha**

Run: `scripts/test-check-no-c-era-artifacts.sh`
Expected: várias linhas `FAIL - ...` (o script `check-no-c-era-artifacts.sh` não existe) e código de saída 1.

- [ ] **Step 3: Implementar o guard**

`scripts/check-no-c-era-artifacts.sh`:

```bash
#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Falha se algum arquivo rastreado for artefato de build/IDE/doc da era C
# (issue #27). Uso: check-no-c-era-artifacts.sh [--stdin]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Um padrão ERE por linha, aplicado ao caminho relativo à raiz.
PATTERNS='(^|/)\.clangd$
(^|/)compile_commands\.json$
(^|/)\.travis\.yml$
(^|/)\.vscode/
(^|/)Doxyfile$
\.xmi$
^docs/imgs/class-diagram\.png$
(^|/)CMakeLists\.txt$
\.cmake$
(^|/)build\.sh$
(^|/)run_klee_test\.sh$'

case "${1:-}" in
  "") list="$(git -C "$ROOT" -c core.quotePath=false ls-files)" ;;
  --stdin) list="$(cat)" ;;
  *) echo "uso: $0 [--stdin]" >&2; exit 2 ;;
esac

hits="$(grep -E -f <(printf '%s\n' "$PATTERNS") <<<"$list" || true)"
if [ -n "$hits" ]; then
  while IFS= read -r p; do echo "C-era artifact: $p" >&2; done <<<"$hits"
  exit 1
fi
```

```bash
chmod +x scripts/check-no-c-era-artifacts.sh
```

- [ ] **Step 4: Rodar o teste**

Run: `scripts/test-check-no-c-era-artifacts.sh`
Expected: todas as linhas `ok - ...` **exceto** `FAIL - CI roda o guard` (ligado na Task 2); código de saída 1.

- [ ] **Step 5: Rodar o guard contra o repositório real (deve acusar os 4 arquivos)**

Run: `scripts/check-no-c-era-artifacts.sh; echo "rc=$?"`
Expected:
```
C-era artifact: docs/C map2checklibrary.xmi
C-era artifact: docs/Doxyfile
C-era artifact: docs/imgs/class-diagram.png
C-era artifact: docs/map2checklibrary.xmi
rc=1
```

- [ ] **Step 6: Commit**

```bash
git add scripts/check-no-c-era-artifacts.sh scripts/test-check-no-c-era-artifacts.sh
git commit -m "test: add guard against C-era artifacts in tracked files (#27)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Remover os artefatos, ligar o guard no CI e abrir o PR

**Files:**
- Delete: `docs/Doxyfile`, `docs/C map2checklibrary.xmi`, `docs/map2checklibrary.xmi`, `docs/imgs/class-diagram.png`
- Modify: `.github/workflows/CI.yml` (job `build_and_test`, logo após o step "Testar script de proteção de branches")

**Interfaces:**
- Consumes: `scripts/check-no-c-era-artifacts.sh` e `scripts/test-check-no-c-era-artifacts.sh` da Task 1.

- [ ] **Step 1: Remover os arquivos**

```bash
git rm docs/Doxyfile "docs/C map2checklibrary.xmi" docs/map2checklibrary.xmi docs/imgs/class-diagram.png
```

- [ ] **Step 2: Ligar o guard e seu teste no CI**

Em `.github/workflows/CI.yml`, logo depois de:

```yaml
      - name: Testar script de proteção de branches
        run: scripts/test-branch-protection.sh
```

inserir:

```yaml

      - name: Testar guard de artefatos da era C
        run: scripts/test-check-no-c-era-artifacts.sh

      - name: Verificar ausência de artefatos da era C
        run: scripts/check-no-c-era-artifacts.sh
```

- [ ] **Step 3: Verificar critérios de aceitação localmente**

```bash
scripts/test-check-no-c-era-artifacts.sh; echo "test rc=$?"
scripts/check-no-c-era-artifacts.sh; echo "guard rc=$?"
git ls-files docs/
test -f docs/imgs/map2check-flowchart.png && echo "README image ok"   # Review Focus 5
```

Expected: teste todo `ok`, `test rc=0`; guard sem saída, `guard rc=0`; `docs/` lista só `api-deltas.md`, `imgs/map2check-flowchart.png` e `superpowers/plans/*`; imprime `README image ok`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/CI.yml
git commit -m "chore: remove C-era docs (Doxyfile, UML .xmi, class diagram) (#27)

These described the removed C implementation and nothing references them.
They remain available in git history (last present at f30f67d).
CI now fails if C-era build/IDE/doc artifacts are tracked again.

Closes #27

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 5: Push e PR para `feature/rust`** (ação externa — confirmar com o usuário antes)

```bash
git push -u origin chore/issue-27-remove-c-era-docs
gh pr create --repo hbgit/map2check-library --base feature/rust \
  --title "chore: remove C-era dead artifacts (#27)" \
  --body "$(cat <<'EOF'
Closes #27 (Audit-ID M1-I5).

- Remove `docs/Doxyfile`, `docs/C map2checklibrary.xmi`, `docs/map2checklibrary.xmi` and the unreferenced C class diagram `docs/imgs/class-diagram.png`. They document the removed C implementation; they remain in git history (last present at `f30f67d`).
- `.clangd`, `compile_commands.json`, `.travis.yml`, `.vscode` and `run_klee_test.sh` were already gone.
- Add `scripts/check-no-c-era-artifacts.sh` (+ offline test) and run it in `build_and_test` so `git ls-files` can't regress.
- Kept: `docs/imgs/map2check-flowchart.png` (used by README).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 6: Confirmar CI verde**

Run: `gh pr checks --repo hbgit/map2check-library --watch`
Expected: `build_and_test` passa, incluindo os steps "Testar guard de artefatos da era C" e "Verificar ausência de artefatos da era C". Após o merge, a issue #27 fecha automaticamente via `Closes #27`.

---

## Fora de escopo (anotado, não fazer aqui)

- `.gitignore` ainda tem regras da era CMake (`build/*`, `release-library/*`, `*.bc`). São regras de ignore, não arquivos rastreados, então não violam o critério da issue; `*.bc` pode voltar a ser relevante com o gate KLEE (#20). Limpar junto com #16/#20 se for o caso.
- `CLAUDE.md` local está desatualizado, mas a versão em `origin/feature/rust` já descreve a lib Rust — resolvido pelo `git pull` da Task 0.
