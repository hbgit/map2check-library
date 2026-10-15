# Issue #28 — Versionar header C e crate como v1.0.0-rc1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar a issue #28 (Audit-ID M3-DoD1): crate em `1.0.0-rc1`, a mesma versão exposta no header gerado como `#define MAP2CHECK_VERSION "1.0.0-rc1"`, e tag `v1.0.0-rc1` no commit que fecha o M3.

**Architecture:** O `build.rs` lê `CARGO_PKG_VERSION` e injeta o `#define` via `cbindgen::Config::after_includes` (fica dentro do include guard, logo após os `#include`). Assim a única fonte da versão é o `Cargo.toml`. Um teste de integração Rust (`tests/header_version.rs`) garante que o header e o `LABEL` do `Dockerfile` batem com `CARGO_PKG_VERSION`; o harness C falha a compilação se a macro sumir. A tag é um passo separado, bloqueado até o M3 estar completo (#13 ainda aberta).

**Tech Stack:** Rust 1.82 (`rust-toolchain.toml`), cbindgen 0.26, clang (harness ASan/UBSan), GitHub Actions, `gh` CLI.

**Spec:** Issue GitHub `hbgit/map2check-library#28` — "build: version the C header and crate as v1.0.0-rc1". Fonte: `docs/plano_map2check_library_rust.md` (M3 — DoD: "header versionado `v1.0.0-rc1`; nenhuma função stub silenciosa restante") e `audit/relatorio_auditoria.md`.

## Verificação (estado em 2026-10-15, `origin/feature/rust` @ `f30f67d`)

| Critério da issue | Estado |
|---|---|
| Versão do crate `1.0.0-rc1` | ❌ `Cargo.toml:4` → `version = "1.0.0"` (e `Cargo.lock:183`) |
| Mesma versão exposta no header gerado | ❌ `include/map2check.h` não tem nenhuma macro de versão; `build.rs` não injeta nada |
| `Dockerfile` coerente | ❌ `Dockerfile:53` → `LABEL org.opencontainers.image.version="1.0.0"` (não citado na issue, mas é a mesma versão duplicada) |
| Tag `v1.0.0-rc1` no commit que fecha o M3 | ❌ nenhuma tag local nem em `origin`; **bloqueado**: #13 (M3-AC1, `next_current_step`) está OPEN |

Observações:
- `include/map2check.h` está no `.gitignore` (é sempre regerado pelo `build.rs`), então não há header versionado em git para editar à mão — a mudança é no gerador.
- `build.rs` só declara `rerun-if-changed` para `rust/src/` e `cbindgen.toml`. Ao trocar só a versão no `Cargo.toml`, o header precisa ser regerado → adicionar `rerun-if-changed=Cargo.toml`.
- O `Dockerfile` não copia `tests/` nem o próprio `Dockerfile` para a imagem, então o novo teste de integração não roda (nem quebra) no `docker build`; ele roda no `cargo test --all-features` do CI.

**Decisão sobre o escopo do PR:** o PR desta issue entrega os dois primeiros critérios e usa `Refs #28` (não `Closes`). A issue só é fechada na Task 4, quando a tag for criada no commit que fecha o M3.

## Global Constraints

- Branch base: `feature/rust` (protegida; exige PR com `build_and_test` verde — issue #26). Branch de trabalho: `build/issue-28-version-rc1`.
- Versão exata: `1.0.0-rc1` (sem ponto — como escrito na issue). Tag exata: `v1.0.0-rc1`. Macro exata: `MAP2CHECK_VERSION`.
- Fonte única da versão: `Cargo.toml`. Nada de literal `"1.0.0-rc1"` em `build.rs`, `cbindgen.toml` ou testes.
- Comentários e mensagens de erro em português, como `build.rs` e `scripts/`.
- Arquivos novos começam com o cabeçalho SPDX `GPL-3.0-only`.
- CI precisa continuar verde: `cargo fmt --check`, `cargo clippy --all-targets --all-features -- -D warnings`, `cargo test --all-features`, harness FFI.
- Commits terminam com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; corpo do PR termina com `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
- Criar/publicar tag e fechar issue são ações externas: pedir confirmação ao usuário antes.

## Review Focus

1. Trocar só a versão no `Cargo.toml` (sem tocar em `rust/src/`) → o header precisa sair com a versão nova, não ficar com a antiga em cache. → `rerun-if-changed=Cargo.toml` + verificação manual na Task 1, Step 6.
2. A macro fora do include guard ou duplicada (incluir o header duas vezes geraria redefinição) → a macro deve aparecer uma vez, entre `#define __MAP2CHECK_H_INCLUDED__` e o `#endif` final. → teste na Task 1.
3. Consumidor C compilado contra um header antigo/sem a macro → deve falhar na compilação, não em runtime. → `#error` no `tests/ffi_harness.c`, Task 1.
4. `LABEL` do `Dockerfile` divergindo do crate em releases futuras → teste falha. → Task 2.
5. Tag criada antes de o M3 fechar (ou no commit errado) → a Task 4 só roda com #13 fechada e aponta para o commit de merge que fecha o M3, com confirmação do usuário.

---

### Task 1: Expor `MAP2CHECK_VERSION` no header gerado

**Files:**
- Create: `tests/header_version.rs`
- Modify: `build.rs:12-13` (config do cbindgen) e `build.rs:96-99` (rerun)
- Modify: `tests/ffi_harness.c:17` (após o `#include`) e `tests/ffi_harness.c:247-250` (início do `main`)

**Interfaces:**
- Consumes: nada.
- Produces: macro C `MAP2CHECK_VERSION` (string literal igual a `CARGO_PKG_VERSION`) em `include/map2check.h`; helper de teste `read(rel: &str) -> String` e const `VERSION` em `tests/header_version.rs` (a Task 2 adiciona um teste ao mesmo arquivo).

- [ ] **Step 1: Criar a branch de trabalho**

```bash
git fetch origin
git switch -c build/issue-28-version-rc1 origin/feature/rust
```

- [ ] **Step 2: Escrever o teste que falha**

Criar `tests/header_version.rs` (o Cargo descobre `tests/*.rs` automaticamente como teste de integração; `tests/ffi_harness.c` é ignorado):

```rust
// SPDX-License-Identifier: GPL-3.0-only
//! A versão do crate deve aparecer, idêntica, nos artefatos que a repetem
//! fora do Cargo.toml (issue #28).

use std::fs;
use std::path::Path;

const VERSION: &str = env!("CARGO_PKG_VERSION");

fn read(rel: &str) -> String {
    let path = Path::new(env!("CARGO_MANIFEST_DIR")).join(rel);
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("falha ao ler {}: {e}", path.display()))
}

#[test]
fn header_define_versao_do_crate_uma_vez_dentro_do_include_guard() {
    let header = read("include/map2check.h");
    let define = format!("#define MAP2CHECK_VERSION \"{VERSION}\"");

    assert_eq!(
        header.matches("#define MAP2CHECK_VERSION").count(),
        1,
        "MAP2CHECK_VERSION deve ser definida exatamente uma vez"
    );
    let at = header
        .find(&define)
        .unwrap_or_else(|| panic!("header não contém `{define}`"));
    let open = header
        .find("#define __MAP2CHECK_H_INCLUDED__")
        .expect("include guard ausente");
    let close = header
        .rfind("#endif /* __MAP2CHECK_H_INCLUDED__ */")
        .expect("fim do include guard ausente");
    assert!(
        open < at && at < close,
        "MAP2CHECK_VERSION está fora do include guard"
    );
}
```

- [ ] **Step 3: Rodar o teste e confirmar que falha**

Run: `cargo test --all-features --test header_version`
Expected: FAIL em `header_define_versao_do_crate_uma_vez_dentro_do_include_guard` com `MAP2CHECK_VERSION deve ser definida exatamente uma vez` (`left: 0, right: 1`).

- [ ] **Step 4: Implementar no `build.rs`**

Trocar as linhas 12-13:

```rust
    // Tenta ler as configurações do cbindgen.toml, se existir
    let config = cbindgen::Config::from_file("cbindgen.toml").unwrap_or_default();
```

por:

```rust
    // Tenta ler as configurações do cbindgen.toml, se existir
    let mut config = cbindgen::Config::from_file("cbindgen.toml").unwrap_or_default();

    // Expõe a versão do crate no header (issue #28); a fonte única é o Cargo.toml
    let version = env::var("CARGO_PKG_VERSION").unwrap();
    config.after_includes = Some(format!("\n#define MAP2CHECK_VERSION \"{version}\""));
```

E no fim do `main`, trocar:

```rust
    println!("cargo:rerun-if-changed=rust/src/");
    println!("cargo:rerun-if-changed=cbindgen.toml");
```

por:

```rust
    println!("cargo:rerun-if-changed=rust/src/");
    println!("cargo:rerun-if-changed=cbindgen.toml");
    println!("cargo:rerun-if-changed=Cargo.toml");
```

(O comentário logo acima — "APENAS se os arquivos Rust mudarem" — deixa de ser exato; trocar por `// Roda este script novamente só se o código Rust, o cbindgen.toml ou o Cargo.toml (versão) mudarem`.)

- [ ] **Step 5: Rodar o teste e confirmar que passa**

Run: `cargo test --all-features --test header_version`
Expected: PASS. Conferir também: `grep -n MAP2CHECK_VERSION include/map2check.h` → uma linha `#define MAP2CHECK_VERSION "1.0.0"` logo após `#include <stdlib.h>`.

- [ ] **Step 6: Verificar regeneração ao mudar só a versão (Review Focus 1)**

```bash
sed -i 's/^version = "1.0.0"$/version = "9.9.9-probe"/' Cargo.toml
cargo build
grep -n MAP2CHECK_VERSION include/map2check.h   # esperado: "9.9.9-probe"
git checkout -- Cargo.toml Cargo.lock
cargo build
grep -n MAP2CHECK_VERSION include/map2check.h   # esperado: "1.0.0"
```

Se a primeira `grep` mostrar `"1.0.0"`, o `rerun-if-changed=Cargo.toml` não está funcionando — corrigir antes de seguir.

- [ ] **Step 7: Proteger o lado C no harness (Review Focus 3)**

Em `tests/ffi_harness.c`, logo após `#include "../include/map2check.h"` (linha 17):

```c

/* Issue #28: o header gerado expõe a versão do crate. */
#ifndef MAP2CHECK_VERSION
#error "map2check.h não define MAP2CHECK_VERSION"
#endif
```

E no início de `main` (antes de `test_result_and_control_flags()`):

```c
int main(void) {
    if (MAP2CHECK_VERSION[0] == '\0') {
        return 1;
    }

    if (test_result_and_control_flags() != 0) {
```

- [ ] **Step 8: Rodar a suíte completa e o harness**

```bash
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
cargo build --release --all-features
clang -fsanitize=address,undefined -fno-omit-frame-pointer \
  tests/ffi_harness.c target/release/libmap2check.a \
  -ldl -lpthread -lm -o target/ffi_harness
target/ffi_harness; echo "rc=$?"
```

Expected: tudo verde; `rc=0`. (O harness tem um SIGSEGV intermitente conhecido sob ASan — ver comentário em `.github/workflows/CI.yml:61-74`; se falhar, rodar de novo até 5 vezes antes de investigar.)

- [ ] **Step 9: Commit**

```bash
git add build.rs tests/header_version.rs tests/ffi_harness.c
git commit -m "build: expose crate version as MAP2CHECK_VERSION in generated header (#28)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Subir a versão para `1.0.0-rc1` (Cargo + Dockerfile)

**Files:**
- Modify: `tests/header_version.rs` (novo teste no fim)
- Modify: `Cargo.toml:4`, `Cargo.lock` (entrada `map2check-library`), `Dockerfile:53`

**Interfaces:**
- Consumes: `read(rel: &str) -> String` e `const VERSION: &str` de `tests/header_version.rs` (Task 1).
- Produces: crate na versão `1.0.0-rc1`; header com `#define MAP2CHECK_VERSION "1.0.0-rc1"`.

- [ ] **Step 1: Adicionar o teste de coerência do Dockerfile**

No fim de `tests/header_version.rs`:

```rust

#[test]
fn label_do_dockerfile_bate_com_versao_do_crate() {
    let dockerfile = read("Dockerfile");
    let label = format!("LABEL org.opencontainers.image.version=\"{VERSION}\"");
    assert!(
        dockerfile.lines().any(|l| l.trim() == label),
        "Dockerfile não contém `{label}`"
    );
}
```

Run: `cargo test --all-features --test header_version`
Expected: PASS (ainda são ambos `1.0.0`) — o teste fica vermelho no próximo passo.

- [ ] **Step 2: Subir a versão do crate e ver o teste falhar**

Em `Cargo.toml:4`: `version = "1.0.0"` → `version = "1.0.0-rc1"`.

Run: `cargo test --all-features --test header_version`
Expected: FAIL em `label_do_dockerfile_bate_com_versao_do_crate` com `Dockerfile não contém \`LABEL org.opencontainers.image.version="1.0.0-rc1"\``; o teste do header passa (regerado com `1.0.0-rc1`). O `Cargo.lock` é atualizado automaticamente pelo build.

- [ ] **Step 3: Atualizar o Dockerfile**

`Dockerfile:53`: `LABEL org.opencontainers.image.version="1.0.0"` → `LABEL org.opencontainers.image.version="1.0.0-rc1"`.

- [ ] **Step 4: Rodar tudo**

```bash
cargo test --all-features --test header_version     # PASS (2 testes)
grep -n '^version' Cargo.toml                        # version = "1.0.0-rc1"
grep -n -A1 'name = "map2check-library"' Cargo.lock  # version = "1.0.0-rc1"
grep -n MAP2CHECK_VERSION include/map2check.h        # "1.0.0-rc1"
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
cargo deny check 2>/dev/null || true                 # opcional local; o CI roda cargo-deny
git grep -n '"1\.0\.0"' -- ':!Cargo.lock' ':!docs/superpowers/plans'   # esperado: nenhuma ocorrência da versão antiga do crate
```

Expected: tudo verde. Se o `git grep` achar `"1.0.0"` em outro lugar, verificar se é a versão do crate (atualizar) ou de uma dependência (ignorar).

- [ ] **Step 5: Commit**

```bash
git add Cargo.toml Cargo.lock Dockerfile tests/header_version.rs
git commit -m "build: bump crate version to 1.0.0-rc1 (#28)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: PR para `feature/rust` e status na issue

**Files:** nenhum.

**Interfaces:**
- Consumes: commits das Tasks 1 e 2.
- Produces: PR aberto contra `feature/rust` com `Refs #28`.

- [ ] **Step 1: Push e PR (confirmar com o usuário antes)**

```bash
git push -u origin build/issue-28-version-rc1
gh pr create --base feature/rust --title "build: version crate and C header as 1.0.0-rc1 (#28)" --body "$(cat <<'EOF'
Refs #28 (Audit-ID M3-DoD1)

- Crate em `1.0.0-rc1` (`Cargo.toml`, `Cargo.lock`) e `LABEL` do `Dockerfile` alinhado.
- `build.rs` injeta `#define MAP2CHECK_VERSION "<CARGO_PKG_VERSION>"` no header gerado (dentro do include guard); `Cargo.toml` é a fonte única e passa a disparar a regeneração do header.
- `tests/header_version.rs` garante header e Dockerfile coerentes com o crate; `tests/ffi_harness.c` falha a compilação se a macro sumir.

Não fecha a issue: a tag `v1.0.0-rc1` deve ir no commit que fecha o M3, que ainda depende de #13.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 2: Acompanhar o CI**

Run: `gh pr checks --watch`
Expected: `build_and_test` verde. Se o passo do harness ASan falhar nas 5 tentativas, é bug real — investigar com superpowers:systematic-debugging.

- [ ] **Step 3: Comentar na issue**

```bash
gh issue comment 28 --body "Critério 1 entregue no PR <número>: crate 1.0.0-rc1 e \`#define MAP2CHECK_VERSION\` no header gerado. Critério 2 (tag \`v1.0.0-rc1\`) aguarda o fechamento do M3 (#13)."
```

---

### Task 4: Tag `v1.0.0-rc1` no commit que fecha o M3 (bloqueada)

Só executar quando o PR da Task 3 estiver mergeado **e** o M3 estiver completo. Se a condição do Step 1 não for satisfeita, parar aqui e reportar ao usuário.

**Files:** nenhum.

**Interfaces:**
- Consumes: `feature/rust` com o PR da Task 3 mergeado e o PR que fecha #13 mergeado.
- Produces: tag anotada `v1.0.0-rc1` em `origin`; issue #28 fechada.

- [ ] **Step 1: Verificar o gate**

```bash
gh issue view 13 --json state -q .state                       # esperado: CLOSED
git fetch origin --tags
git show origin/feature/rust:Cargo.toml | grep '^version'      # version = "1.0.0-rc1"
git tag -l 'v1.0.0-rc1'; git ls-remote --tags origin v1.0.0-rc1   # esperado: vazio
```

Confirmar com o usuário quais outras issues do M3 precisam estar fechadas (o DoD também exige "nenhuma função stub silenciosa restante") e qual commit fecha o M3 — normalmente o merge commit do último PR do M3 em `feature/rust`:

```bash
git log --oneline --first-parent -10 origin/feature/rust
```

- [ ] **Step 2: Conferir o commit escolhido**

```bash
SHA=<commit confirmado pelo usuário>
git show "$SHA:Cargo.toml" | grep '^version'   # 1.0.0-rc1
git switch --detach "$SHA" && cargo test --all-features && git switch -
```

Expected: versão `1.0.0-rc1` e testes verdes nesse commit.

- [ ] **Step 3: Criar e publicar a tag (confirmar com o usuário antes do push)**

```bash
git tag -a v1.0.0-rc1 "$SHA" -m "map2check-library v1.0.0-rc1 (fecha M3)"
git push origin v1.0.0-rc1
git ls-remote --tags origin v1.0.0-rc1   # deve listar a tag
```

- [ ] **Step 4: Fechar a issue**

```bash
gh issue close 28 --comment "Tag \`v1.0.0-rc1\` criada em $SHA (commit que fecha o M3). Crate e header expõem 1.0.0-rc1 desde o PR <número>."
```
