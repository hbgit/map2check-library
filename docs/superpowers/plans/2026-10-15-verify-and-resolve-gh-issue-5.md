# Issue #5 — Documentar desvios de compatibilidade e processo de release — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar a issue #5. A meta é ter a matriz símbolo/assinatura (`docs/api-deltas.md`), os desvios semânticos reproduzíveis (`docs/semantic-deltas.md`), o guia de integração, o CHANGELOG e o processo de release documentado e empacotado. Testes mantêm tudo isso em sincronia com o código.

**Architecture:** Os documentos são Markdown com formato fixo, e um teste de integração (`tests/compat_docs.rs`) os lê. Esse teste exige: uma linha da matriz por função do `include/map2check.h`, com a declaração exata; entradas `SD-NN` em ordem, apontando para testes que existem; exemplos JSON do guia iguais à saída real do serializador. O parser de declarações do header vai para `tests/common/mod.rs`, compartilhado com `tests/ffi_exports_checklist.rs`. O empacotamento fica em `scripts/package-release.sh`, testado por `scripts/test-package-release.sh` no CI. Ele gera duas bibliotecas estáticas, porque a build `libfuzzer` não linka num programa C comum.

**Tech Stack:** Rust 1.82 (`rust-toolchain.toml`, edition 2021, literais `c"..."`), cbindgen 0.26 (header gerado pelo `build.rs`), `serde_json` (já dependência), bash + GNU tar/gzip/sha256sum/nm, clang, GitHub Actions.

**Spec:** Issue GitHub `hbgit/map2check-library#5`, "Document compatibility deviations and release process". Critérios:
1. Add and maintain `docs/api-deltas.md` with a symbol/signature compatibility matrix.
2. Add and maintain `docs/semantic-deltas.md` with reproducible cases for intentional behavior differences.
3. Update the changelog and document release packaging for the C header and integration guide.
4. Ensure the documents reflect decisions made in the ABI, JSON, and integration issues (#13, #14, #21).

Fontes usadas: `docs/plano_map2check_library_rust.md` §1.2(a)/(b), §2.1, M3, M5 e M6 (no `master`); os corpos das issues #13, #14 e #21; a biblioteca C embutida do Map2Check em `lib_old/` na branch `origin/refactory_memory_log` (commit `68d174d`).

## Verificação (estado em 2026-10-15, `origin/feature/rust` @ `9600fc0`)

| Critério | Estado |
|---|---|
| 1. Matriz símbolo/assinatura em `docs/api-deltas.md` | ❌ O arquivo existe, mas só tem 4 seções narrativas (pchar/loff_t/sector_t, assume, non_static_alloca/funct_address, `char`). Não há matriz, e nada impede que fique desatualizado. |
| 2. `docs/semantic-deltas.md` com casos reproduzíveis | ❌ Não existe. |
| 3. CHANGELOG e empacotamento do header e do guia de integração | ❌ Não há `CHANGELOG.md`, guia de integração, documento de release nem script de pacote. O `include/map2check.h` está no `.gitignore` (é gerado), então só um pacote de release o entrega. |
| 4. Refletir as decisões de #13 (ABI), #14 (JSON) e #21 (compat) | ⚠️ As três issues estão abertas. **Decisão do mantenedor:** a #5 fecha com este trabalho, registrando as decisões já tomadas e marcando o resto como pendente; #13, #14 e #21 atualizam os docs quando fecharem (os testes de `tests/compat_docs.rs` obrigam isso). #13 já exportou `get_next_step`, `map2check_map_non_static_alloca`, `map2check_map_funct_address` e `map2check_check_free_resolved_address`, mas ainda faltam registrar `next_current_step` (M3-E1) e a semântica de `free_resolved_address` (M3-I2). #14 e #21 não tomaram decisão. Os docs registram o estado atual e marcam o resto como `pending`/`pending decision`, citando a issue. |

Achados do protótipo (worktree descartável sobre `9600fc0`; todo o conteúdo deste plano foi executado lá):

- O exemplo JSON do `README.md` está errado em relação à saída real: tem `"result": "true"` (o real é `"TRUE"`), `"line"` (o real é `"line_number"`) e `"property": "NONE"` em sucesso (o real omite a chave). A Task 3 coloca exemplos verificados no guia, e a Task 6 tira o exemplo do README.
- Uma `libmap2check.a` compilada com `--all-features` **não linka** num programa C comum: `undefined reference to '__map2check_main__'`, que vem de `LLVMFuzzerTestOneInput`. Por isso o pacote leva `lib/libmap2check.a` (sem features) e `lib/libmap2check_libfuzzer.a`.
- Três comportamentos atuais divergem do legado de um jeito que parece bug. O plano **não muda código de produção**: registra esses casos como `suspected regression (#15)`, fixa o comportamento atual com testes e propõe issues na Task 7.
  - **SD-03:** uma checagem de memória segura apaga uma violação anterior, inclusive `REACHABILITY`. No legado, a primeira violação faz `abort()`.
  - **SD-06:** `map2check_check_free_resolved_address` trata endereço não rastreado como seguro. O legado `is_invalid_free` trata como inválido.
  - **SD-12:** um VLA (`map2check_map_non_static_alloca`) é acusado como vazamento por `map2check_check_mem_endprog`. O legado registra VLA como slot estático.
- Com tudo aplicado, passaram: `cargo test --all-features` (144 unit; compat_docs 8; checklist 11; header_version 3), `cargo test` sem features, `cargo clippy --all-targets --all-features -- -D warnings`, `cargo fmt --check`, `scripts/check-no-c-era-artifacts.sh` e `scripts/test-package-release.sh` (9 ok). Oito mutações nos docs (declaração trocada, linha renomeada, status errado, teste renomeado, ID duplicado, chave JSON trocada, versão do CHANGELOG, SD inexistente) fizeram o teste correspondente falhar.

## Global Constraints

- Branch base: `origin/feature/rust` @ `9600fc0` (protegida; exige PR com `build_and_test` verde, issue #26). Branch de trabalho: `docs/issue-5-compat-release`.
- Nenhuma mudança de comportamento em código de produção (`rust/src/**` fora de `ffi_tests.rs`, `build.rs`, `Cargo.toml`). Mudam só testes, docs, scripts, CI, `.gitignore`, `README.md` e `CHANGELOG.md`.
- Docs de compatibilidade (`docs/api-deltas.md`, `docs/semantic-deltas.md`, `docs/integration-guide.md`, `docs/release.md`, `CHANGELOG.md`) em inglês, como o `docs/api-deltas.md` atual. Comentários e mensagens de teste em português, como os testes existentes. `README.md` em português.
- Arquivos `.rs` e `.sh` novos começam com o cabeçalho SPDX `GPL-3.0-only`. Scripts novos ficam executáveis (`chmod +x`).
- Todo bloco `unsafe` em teste leva comentário `// SAFETY:`.
- Endereços nos testes são falsos (`0x1000`): a biblioteca só armazena e compara endereços.
- O CI precisa continuar verde: `cargo fmt --check`, `cargo clippy --all-targets --all-features -- -D warnings`, `cargo test --all-features`, cobertura (`scripts/coverage.sh`, gate de 80% fora de `ffi*.rs`), harness FFI e o guard de artefatos da era C.
- **Sem atribuição de IA** (decisão do mantenedor, mesma regra de `.github/copilot-instructions.md` no `master`): nenhum commit leva `Co-Authored-By` de IA, e nenhum corpo de PR ou issue leva "Generated with" ou rótulo equivalente. Isso vale também para a Task 7, mesmo que a ferramenta de execução sugira essas linhas.
- Push, abertura de PR, criação de issues e tag/release são ações externas: pedir confirmação ao usuário antes.

## Review Focus

1. **Programa C comum linkando a biblioteca com `libfuzzer`.** Com `--all-features`, o link falha com `undefined reference to '__map2check_main__'`. O pacote precisa entregar uma `libmap2check.a` sem features que linke e rode um programa C comum. Teste: `scripts/test-package-release.sh` compila `test/codeAPI_by_caller_test.c` contra o header e a lib **extraídos do pacote** e confere com `nm` que a lib core não define `LLVMFuzzerTestOneInput` (Task 6).
2. **Assinatura mudada no Rust sem atualizar o doc.** Por exemplo, `int32_t size` virando `int64_t`, ou uma declaração de várias linhas como `map2check_map_alloca`. A matriz precisa falhar o CI. Teste: `matriz_nucleo_cobre_o_header_com_declaracoes_exatas` compara a declaração normalizada (espaços colapsados, várias linhas juntadas) e `matriz_acusa_export_sem_linha_declaracao_divergente_e_status_errado` cobre o caso de várias linhas (Task 2).
3. **Exemplo JSON da documentação divergindo da saída real**, como já acontece no README. Teste: `integration_guide_json_examples_match_the_serializer` monta o estado pela FFI e compara com `serde_json::Value`, então espaço em branco não conta (Task 3).
4. **Entrada `SD-NN` que aponta para teste renomeado ou apagado, ou `SD-NN` citado sem existir.** O doc vira promessa vazia. Testes: `semantic_deltas_tem_ids_em_ordem_classificacao_e_testes_existentes`, `semantic_deltas_acusa_teste_inexistente_e_classificacao_sem_issue` e `todo_sd_citado_existe_em_semantic_deltas` (Task 5).
5. **Script de teste em bash com `pipefail`.** `nm ... | grep -q` falha por SIGPIPE e dá falso negativo (no protótipo, a checagem negativa "passava" pelo motivo errado), e `sort` depende do locale (`LICENSE` × `docs/`). A saída do `nm` vai para variáveis, a checagem core também exige `map2check_init` presente e a ordenação usa `LC_ALL=C sort` (Task 6).

---

### Task 1: Parser de declarações do header compartilhado

**Files:**
- Create: `tests/common/mod.rs`
- Modify: `tests/ffi_exports_checklist.rs` (imports no topo, `fn read` e `fn header_functions`)

**Interfaces:**
- Consumes: nada.
- Produces (usados pelas Tasks 2, 3 e 5 via `mod common;`): `pub fn read(rel: &str) -> String`, `pub fn normalize(text: &str) -> String`, `pub fn header_declarations(header: &str) -> BTreeMap<String, String>` (nome → declaração normalizada sem `;`).

- [ ] **Step 1: Criar a branch de trabalho e registrar o plano**

```bash
git fetch origin
git switch -c docs/issue-5-compat-release origin/feature/rust
git add docs/superpowers/plans/2026-10-15-verify-and-resolve-gh-issue-5.md
git commit -m "docs: add plan for issue #5 (compatibility docs and release process)"
```

Se o arquivo do plano não estiver na árvore (ele foi escrito fora da branch), copie-o para `docs/superpowers/plans/` antes do `git add`.

- [ ] **Step 2: Criar `tests/common/mod.rs`**

````rust
// SPDX-License-Identifier: GPL-3.0-only
//! Utilitários compartilhados pelos testes de integração que leem arquivos
//! do repositório (header gerado, documentação).

#![allow(dead_code)]

use std::collections::BTreeMap;
use std::fs;
use std::path::Path;

/// Lê um arquivo relativo à raiz do crate.
pub fn read(rel: &str) -> String {
    let path = Path::new(env!("CARGO_MANIFEST_DIR")).join(rel);
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("falha ao ler {}: {e}", path.display()))
}

fn is_ident(c: char) -> bool {
    c.is_ascii_alphanumeric() || c == '_'
}

/// Colapsa qualquer sequência de espaços em branco num único espaço.
pub fn normalize(text: &str) -> String {
    text.split_whitespace().collect::<Vec<_>>().join(" ")
}

/// Declarações de função do header gerado pelo cbindgen, por nome.
/// Uma declaração começa numa linha no nível zero (sem indentação, fora de
/// comentários e diretivas) que contém `(` e termina na primeira linha que
/// contém `);`. O valor é a declaração com espaços normalizados, sem o `;`.
pub fn header_declarations(header: &str) -> BTreeMap<String, String> {
    let mut decls = BTreeMap::new();
    let mut lines = header.lines();
    while let Some(line) = lines.next() {
        if !line.starts_with(|c: char| c.is_ascii_alphabetic() || c == '_') || !line.contains('(') {
            continue;
        }
        let mut decl = line.to_string();
        while !decl.contains(");") {
            match lines.next() {
                Some(next) => {
                    decl.push(' ');
                    decl.push_str(next);
                }
                None => break,
            }
        }
        let Some((before, _)) = decl.split_once('(') else {
            continue;
        };
        let name: String = before
            .chars()
            .rev()
            .take_while(|&c| is_ident(c))
            .collect::<Vec<_>>()
            .into_iter()
            .rev()
            .collect();
        if name.is_empty() {
            continue;
        }
        let decl = normalize(decl.trim_end().trim_end_matches(';'));
        decls.insert(name, decl);
    }
    decls
}
````

- [ ] **Step 3: Fazer o checklist usar o módulo comum**

Em `tests/ffi_exports_checklist.rs`, troque o bloco de imports:

```rust
use std::collections::BTreeSet;
use std::fs;
use std::path::Path;
```

por:

```rust
mod common;

use std::collections::BTreeSet;
use std::fs;
use std::path::Path;

use common::read;
```

Apague a função local `read` inteira (`fn read(rel: &str) -> String { ... }`, logo depois de `TEST_SOURCES`). Depois troque a função `header_functions` inteira (o doc comment "Nomes das funções declaradas no header gerado pelo cbindgen: linhas no nível zero..." e o corpo com `.lines().filter(...)`) por:

```rust
/// Nomes das funções declaradas no header gerado pelo cbindgen
/// (parser compartilhado em `tests/common/mod.rs`).
fn header_functions(header: &str) -> BTreeSet<String> {
    common::header_declarations(header).into_keys().collect()
}
```

`is_ident` continua no arquivo, porque `strip_non_code`, `calls` e `leading_ident` o usam.

- [ ] **Step 4: Rodar os testes do checklist**

Run: `cargo test --all-features --test ffi_exports_checklist`
Expected: PASS, `11 passed`. Os testes `header_real_e_lido_por_completo` (sentinelas: várias linhas, retorno `enum`, retorno ponteiro, trailer legado, libfuzzer), `checklist_acusa_simbolo_sem_teste` (declaração em duas linhas) e `checklist_ignora_comentarios_e_diretivas_do_header` validam o parser novo. Se algum falhar, o parser novo não é equivalente ao antigo: corrija `header_declarations`, não os testes.

- [ ] **Step 5: Lint e commit**

```bash
cargo fmt
cargo clippy --all-targets --all-features -- -D warnings
git add tests/common/mod.rs tests/ffi_exports_checklist.rs
git commit -m "test: share header declaration parser between integration tests (#5)"
```

---

### Task 2: Matriz símbolo/assinatura em `docs/api-deltas.md`

**Files:**
- Create: `tests/compat_docs.rs`
- Modify: `docs/api-deltas.md` (reescrita; as 4 seções narrativas existentes são mantidas, uma delas ganha um parágrafo, e entram 2 seções novas)

**Interfaces:**
- Consumes: `common::{read, normalize, header_declarations}` (Task 1).
- Produces: `tests/compat_docs.rs` com `section`, `table_rows`, `code`, `glob`, `in_header`, `core_matrix_problems`, `pass_matrix_problems`. As Tasks 3 e 5 acrescentam código no fim deste arquivo. Os títulos `## Core C API matrix` e `## Map2Check pass matrix` e o vocabulário de status (`same`, `changed`, `new`, `discontinued`, `pending`, `out-of-scope`) são o contrato entre doc e teste.

- [ ] **Step 1: Escrever o teste (falha porque a seção ainda não existe)**

Crie `tests/compat_docs.rs`:

````rust
// SPDX-License-Identifier: GPL-3.0-only
//! Os documentos de compatibilidade acompanham o código (issue #5):
//! `docs/api-deltas.md` tem uma linha por export do header com a declaração
//! exata, `docs/semantic-deltas.md` aponta para testes que existem e os
//! exemplos JSON de `docs/integration-guide.md` são a saída real.

mod common;

use std::collections::{BTreeMap, BTreeSet};

use common::{header_declarations, normalize, read};

const CORE_HEADING: &str = "## Core C API matrix";
const PASS_HEADING: &str = "## Map2Check pass matrix";
const EXPORTED: &[&str] = &["same", "changed", "new"];
const NOT_EXPORTED: &[&str] = &["discontinued", "pending", "out-of-scope"];

/// Texto da seção que começa em `heading`, até o próximo `## `.
fn section<'a>(doc: &'a str, heading: &str) -> &'a str {
    let start = doc
        .find(&format!("\n{heading}\n"))
        .unwrap_or_else(|| panic!("seção `{heading}` ausente"));
    let body = &doc[start + heading.len() + 2..];
    let end = body.find("\n## ").unwrap_or(body.len());
    &body[..end]
}

/// Linhas de dados das tabelas Markdown da seção (pula cabeçalho e `|---|`),
/// cada uma como lista de células sem espaços nas pontas.
fn table_rows(section: &str) -> Vec<Vec<String>> {
    section
        .lines()
        .filter(|l| l.starts_with("| `"))
        .map(|l| {
            l.trim()
                .trim_matches('|')
                .split(" | ")
                .map(|c| c.trim().to_string())
                .collect()
        })
        .collect()
}

/// Conteúdo entre a primeira crase e a última de uma célula.
fn code(cell: &str) -> &str {
    let start = cell.find('`').map_or(0, |i| i + 1);
    let end = cell.rfind('`').unwrap_or(cell.len());
    if start <= end {
        &cell[start..end]
    } else {
        ""
    }
}

/// `true` se `pattern` (que pode ter um `*`) casa com `name`.
fn glob(pattern: &str, name: &str) -> bool {
    match pattern.split_once('*') {
        Some((pre, post)) => {
            name.len() >= pre.len() + post.len() && name.starts_with(pre) && name.ends_with(post)
        }
        None => pattern == name,
    }
}

fn in_header(symbol: &str, header: &BTreeMap<String, String>) -> bool {
    header.keys().any(|name| glob(symbol, name))
}

/// Problemas da matriz núcleo: cada export do header aparece uma vez com a
/// declaração exata; linhas exportadas estão no header; as não exportadas, não.
fn core_matrix_problems(doc: &str, header: &BTreeMap<String, String>) -> Vec<String> {
    let mut problems = Vec::new();
    let mut seen = BTreeSet::new();
    for row in table_rows(section(doc, CORE_HEADING)) {
        let [symbol, decl, _legacy, status, notes] = row.as_slice() else {
            problems.push(format!(
                "linha com {} colunas (esperado 5): {row:?}",
                row.len()
            ));
            continue;
        };
        let symbol = code(symbol);
        if !seen.insert(symbol.to_string()) {
            problems.push(format!("`{symbol}` repetido"));
        }
        if EXPORTED.contains(&status.as_str()) {
            match header.get(symbol) {
                None => problems.push(format!(
                    "`{symbol}` está como `{status}` mas não está no header"
                )),
                Some(real) if normalize(code(decl)) != *real => problems.push(format!(
                    "`{symbol}`: declaração no doc `{}` difere do header `{real}`",
                    code(decl)
                )),
                Some(_) => {}
            }
        } else if NOT_EXPORTED.contains(&status.as_str()) {
            if in_header(symbol, header) {
                problems.push(format!(
                    "`{symbol}` está como `{status}` mas está no header"
                ));
            }
        } else {
            problems.push(format!("`{symbol}`: status desconhecido `{status}`"));
        }
        if status != "same" && notes.is_empty() {
            problems.push(format!("`{symbol}` (`{status}`) sem nota"));
        }
    }
    for name in header.keys() {
        if !seen.contains(name) {
            problems.push(format!("export `{name}` do header sem linha na matriz"));
        }
    }
    problems
}

/// Problemas da matriz dos passes: status conhecido e coerente com o header.
fn pass_matrix_problems(doc: &str, header: &BTreeMap<String, String>) -> Vec<String> {
    let mut problems = Vec::new();
    for row in table_rows(section(doc, PASS_HEADING)) {
        let [symbol, _signature, status, _notes] = row.as_slice() else {
            problems.push(format!(
                "linha com {} colunas (esperado 4): {row:?}",
                row.len()
            ));
            continue;
        };
        let symbol = code(symbol);
        let exported = in_header(symbol, header);
        match status.as_str() {
            "same" | "changed" if !exported => problems.push(format!(
                "`{symbol}` está como `{status}` mas não está no header"
            )),
            "pending" | "out-of-scope" if exported => problems.push(format!(
                "`{symbol}` está como `{status}` mas está no header"
            )),
            "same" | "changed" | "pending" | "out-of-scope" => {}
            other => problems.push(format!("`{symbol}`: status desconhecido `{other}`")),
        }
    }
    problems
}

#[test]
fn matriz_nucleo_cobre_o_header_com_declaracoes_exatas() {
    let header = header_declarations(&read("include/map2check.h"));
    let problems = core_matrix_problems(&read("docs/api-deltas.md"), &header);
    assert!(
        problems.is_empty(),
        "docs/api-deltas.md desatualizado:\n{}",
        problems.join("\n")
    );
}

#[test]
fn matriz_dos_passes_e_coerente_com_o_header() {
    let header = header_declarations(&read("include/map2check.h"));
    let problems = pass_matrix_problems(&read("docs/api-deltas.md"), &header);
    assert!(problems.is_empty(), "{}", problems.join("\n"));
}

#[test]
fn matriz_acusa_export_sem_linha_declaracao_divergente_e_status_errado() {
    let header = header_declarations(
        "void foo(void);\nint32_t bar(int32_t x,\n             int32_t y);\nvoid baz(void);\n",
    );
    let doc = format!(
        "intro\n{CORE_HEADING}\n\n| Symbol | Decl | Legacy | Status | Notes |\n|---|---|---|---|---|\n\
         | `foo` | `void foo(void)` | — | same |  |\n\
         | `bar` | `int32_t bar(int32_t x)` | — | changed | nota |\n\
         | `baz` | — | — | discontinued | nota |\n\
         | `old_*` | — | — | discontinued | nota |\n\n## Next\n"
    );
    let problems = core_matrix_problems(&doc, &header);
    assert_eq!(problems.len(), 2, "{problems:?}");
    assert!(
        problems[0].contains("`bar`: declaração no doc"),
        "{problems:?}"
    );
    assert!(
        problems[1].contains("`baz` está como `discontinued` mas está no header"),
        "{problems:?}"
    );

    let doc = format!(
        "\n{CORE_HEADING}\n| `foo` | `void foo(void)` | — | same |  |\n| `bar` | `int32_t bar(int32_t x, int32_t y)` | — | renamed |  |\n"
    );
    let problems = core_matrix_problems(&doc, &header);
    assert!(
        problems
            .iter()
            .any(|p| p.contains("status desconhecido `renamed`")),
        "{problems:?}"
    );
    assert!(
        problems.iter().any(|p| p.contains("`renamed`) sem nota")),
        "{problems:?}"
    );
    assert!(
        problems
            .iter()
            .any(|p| p == "export `baz` do header sem linha na matriz"),
        "{problems:?}"
    );
}

#[test]
fn matriz_dos_passes_acusa_pendente_exportado_e_wildcard_sem_export() {
    let header =
        header_declarations("void __VERIFIER_nondet_int(void);\nvoid map2check_alloca(void);\n");
    let doc = format!(
        "\n{PASS_HEADING}\n| `__VERIFIER_nondet_*` | `int` | same | |\n\
         | `map2check_alloca` | `(ptr)` | pending | #21 |\n\
         | `map2check_wasm_*` | — | same | |\n"
    );
    let problems = pass_matrix_problems(&doc, &header);
    assert_eq!(problems.len(), 2, "{problems:?}");
    assert!(problems[0].contains("`map2check_alloca` está como `pending` mas está no header"));
    assert!(problems[1].contains("`map2check_wasm_*` está como `same` mas não está no header"));
}
````

- [ ] **Step 2: Rodar e ver falhar**

Run: `cargo test --all-features --test compat_docs`
Expected: FAIL. `matriz_nucleo_cobre_o_header_com_declaracoes_exatas` e `matriz_dos_passes_e_coerente_com_o_header` entram em panic com ``seção `## Core C API matrix` ausente`` / ``seção `## Map2Check pass matrix` ausente``. Os dois testes sintéticos (`matriz_acusa_...` e `matriz_dos_passes_acusa_...`) passam.

- [ ] **Step 3: Reescrever `docs/api-deltas.md`**

Substitua o arquivo inteiro por:

````markdown
# API deltas — Rust `map2check-library` vs. the legacy C implementations

This document is the symbol/signature compatibility matrix of the C ABI
exported by `libmap2check.a` (declared in the generated
`include/map2check.h`). Behaviour differences that need a reproducible
example live in [`semantic-deltas.md`](semantic-deltas.md) and are cited
here by ID (`SD-NN`).

Two baselines are compared:

- **Legacy C library** — the C `map2check-library` that this repository
  shipped before the Rust rewrite (`master` C branch; its history was not
  carried over). Its symbols come from the parity table in
  `docs/plano_map2check_library_rust.md` §1.2(a) on `master`.
- **Map2Check passes** — the symbols the LLVM passes of
  `hbgit/Map2Check@develop` insert today, taken from §1.2(b) of the same
  plan. The passes link against the C library embedded in Map2Check, not
  against this repository.

`tests/compat_docs.rs` keeps this file honest: every function in the
generated header must have a row in the core matrix with its exact
declaration, and every `SD-NN` cited here must exist in
`semantic-deltas.md`. Update this file in the same change that adds,
removes or changes an export.

## Status vocabulary

| Status | Meaning | Exported? |
|---|---|---|
| `same` | Same name and contract as the baseline. | yes |
| `changed` | Exported, but the signature or behaviour differs from the baseline; the Notes say how. | yes |
| `new` | No baseline counterpart. | yes |
| `discontinued` | Baseline symbol deliberately not ported. | no |
| `pending` | Required by the baseline; decision tracked in the cited issue. | no |
| `out-of-scope` | Required by the baseline, excluded on purpose. | no |

## Core C API matrix

The declaration column is copied from `include/map2check.h` with
whitespace collapsed. The header declares the `libfuzzer` symbols even
when the library is built without that feature; link them only from a
build with `--features libfuzzer`.

| Symbol | Rust declaration (`include/map2check.h`) | Legacy C library | Status | Notes |
|---|---|---|---|---|
| `map2check_init` | `void map2check_init(void)` | `map2check_init` | same | Map2Check passes call `map2check_init(int)`; see the pass matrix. |
| `map2check_reset` | `void map2check_reset(void)` | — | new | Clears containers, result, step counter and flags (#9). |
| `map2check_success` | `void map2check_success(void)` | `map2check_success` | same | Prints the JSON report (SD-01). |
| `set_false_result` | `void set_false_result(int32_t prp, int32_t line_number, const char *function_name)` | `set_false_result` | same | `ViolatedProperty` keeps the C variant order (`caller_lib_result.h:22-31`); unknown values are ignored (SD-09). |
| `get_current_property` | `enum ViolatedProperty get_current_property(void)` | `get_current_property` | same |  |
| `get_current_step` | `uint64_t get_current_step(void)` | `long get_current_step(void)` | changed | Returns `uint64_t` instead of `long`. |
| `get_next_step` | `uint64_t get_next_step(void)` | `get_next_step()` / `next_current_step()` | same | Advances and returns the step counter. `next_current_step` is not exported; see its row. |
| `print_all_containers_as_json` | `void print_all_containers_as_json(void)` | `print_all_containers_as_json` | changed | Report shape and whitespace differ (SD-01, SD-02; schema decision in #14). |
| `vcc_reset_meta_data` | `void vcc_reset_meta_data(void)` | `vcc_reset_meta_data` | same |  |
| `map2check_set_memcleanup` | `void map2check_set_memcleanup(void)` | `map2check_set_memcleanup` | same | Enables the end-of-program leak check (SD-04). |
| `map2check_set_null_is_valid` | `void map2check_set_null_is_valid(void)` | `map2check_set_null_is_valid` | same | Makes a NULL load safe (SD-05). |
| `map2check_save_nondet_log_int` | `non_det_log_t *map2check_save_nondet_log_int(int line, int scope, enum var_type_t type_var, int *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_uint` | `non_det_log_t *map2check_save_nondet_log_uint(int line, int scope, enum var_type_t type_var, unsigned int *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_long` | `non_det_log_t *map2check_save_nondet_log_long(int line, int scope, enum var_type_t type_var, long *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_float` | `non_det_log_t *map2check_save_nondet_log_float(int line, int scope, enum var_type_t type_var, float *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_double` | `non_det_log_t *map2check_save_nondet_log_double(int line, int scope, enum var_type_t type_var, double *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_char` | `non_det_log_t *map2check_save_nondet_log_char(int line, int scope, enum var_type_t type_var, char *value, const char *function_name)` | returns `non_det_log_t *`; `char` value | same | `char` is `i8` on the Rust side; see “`char` ABI”. Returned record is not linked (SD-10). |
| `map2check_save_basic_block_log` | `bbtrack_log_t *map2check_save_basic_block_log(int32_t line, const char *function_name)` | returns `bbtrack_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_is_in_trackbb_container` | `int32_t map2check_is_in_trackbb_container(int32_t line)` | `map2check_is_in_trackbb_container` | same |  |
| `map2check_map_alloca` | `void map2check_map_alloca(const char *var_name, const void *ptr_address, int32_t size, int32_t size_primitive, int32_t line_number, int32_t scope)` | `container_memtracklog.h:41` | same |  |
| `map2check_map_non_static_alloca` | `void map2check_map_non_static_alloca(const char *var_name, const void *ptr_address, int32_t size, int32_t size_primitive, int32_t line_number, int32_t scope)` | `container_memtracklog.h:44` | same | Signature and semantics reconstructed; see its section. Counted as a leak at end of program (SD-12). |
| `map2check_map_funct_address` | `void map2check_map_funct_address(const char *var_name, const void *ptr_address)` | `container_memtracklog.h:48` | same | Signature and semantics reconstructed; see its section. |
| `map2check_map_malloc` | `void map2check_map_malloc(const void *ptr_address, int32_t size)` | `map2check_map_malloc` | same | Negative sizes are ignored (SD-09). |
| `map2check_map_calloc` | `void map2check_map_calloc(const void *ptr_address, int32_t quantity, int32_t size)` | `map2check_map_calloc` | same | Negative sizes are ignored (SD-09). |
| `map2check_map_free` | `void map2check_map_free(const char *var_name, const void *ptr_address, uint32_t scope, uint32_t line_number, const char *function_name)` | `map2check_map_free` | same |  |
| `map2check_map_store_pointer` | `void map2check_map_store_pointer(const void *var_address, const void *value, uint32_t scope, const char *var_name, int32_t line_number, const char *funct_name)` | `map2check_map_store_pointer` | same |  |
| `map2check_is_valid_assert` | `void map2check_is_valid_assert(int32_t line_number, const char *function_name, int32_t expression)` | `map2check_is_valid_assert` | same | Prints the JSON report when the assertion fails. |
| `map2check_binop_add_int` | `void map2check_binop_add_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_add_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_sub_int` | `void map2check_binop_sub_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_sub_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_mul_int` | `void map2check_binop_mul_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_mul_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_div_int` | `void map2check_binop_div_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_div_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_neg_int` | `void map2check_binop_neg_int(int32_t param1, int32_t _param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_neg_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_shl_int` | `void map2check_binop_shl_int(int32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_shl_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_shr_int` | `void map2check_binop_shr_int(int32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_shr_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_add_unsigned` | `void map2check_binop_add_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_add_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_sub_unsigned` | `void map2check_binop_sub_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_sub_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_mul_unsigned` | `void map2check_binop_mul_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_mul_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_div_unsigned` | `void map2check_binop_div_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_div_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_shr_unsigned` | `void map2check_binop_shr_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_shr_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_check_load` | `void map2check_check_load(const void *ptr, int32_t line, uint32_t scope, int32_t size, const char *function_name)` | `map2check_check_load` | changed | Address-validity rule rewritten (plan R1; differential check in #15). A safe load clears an earlier violation (SD-03); NULL handling in SD-05. |
| `map2check_check_free` | `void map2check_check_free(const char *_name, const void *ptr, uint32_t _scope, uint32_t line, const char *function_name)` | `map2check_check_free` | same | `_name` and `_scope` are ignored. Untracked address is a violation (SD-06). |
| `map2check_check_free_resolved_address` | `void map2check_check_free_resolved_address(const void *ptr, uint32_t line, const char *function_name, int16_t is_null_valid)` | `analysis_memory.h:46` | same | Semantics in its section; untracked address is safe (SD-06). |
| `map2check_check_deref` | `void map2check_check_deref(const void *ptr, uint32_t scope, uint32_t line, const char *function_name)` | `map2check_check_deref` | same | Name collides with the pass ABI `map2check_check_deref(i64, ptr)`; see the pass matrix (#21). |
| `map2check_check_mem_endprog` | `void map2check_check_mem_endprog(void)` | `map2check_check_mem_endprog` | changed | Leak algorithm rewritten; no-op until `map2check_set_memcleanup()` (SD-04). |
| `LLVMFuzzerTestOneInput` | `int32_t LLVMFuzzerTestOneInput(const uint8_t *data, uintptr_t size)` | `LLVMFuzzerTestOneInput` | same | Feature `libfuzzer`. Resets the analysis state on every iteration (SD-11). |
| `__VERIFIER_nondet_bool` | `bool __VERIFIER_nondet_bool(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_char` | `int8_t __VERIFIER_nondet_char(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_uchar` | `uint8_t __VERIFIER_nondet_uchar(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_short` | `int16_t __VERIFIER_nondet_short(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_ushort` | `uint16_t __VERIFIER_nondet_ushort(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_int` | `int32_t __VERIFIER_nondet_int(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_uint` | `uint32_t __VERIFIER_nondet_uint(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_long` | `int64_t __VERIFIER_nondet_long(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_ulong` | `uint64_t __VERIFIER_nondet_ulong(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_float` | `float __VERIFIER_nondet_float(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_double` | `double __VERIFIER_nondet_double(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_size_t` | `uintptr_t __VERIFIER_nondet_size_t(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_pointer` | `void *__VERIFIER_nondet_pointer(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_assume` | `void __VERIFIER_assume(int32_t condition)` | — | new | Feature `libfuzzer`. `__VERIFIER_assume(0)` ends the process with `exit(0)` (SD-07). |
| `map2check_fuzzer_assume` | `void map2check_fuzzer_assume(int32_t condition)` | `map2check_fuzzer_assume(int)` (`nondet_gen_libfuzzer.h:41`) | same | Feature `libfuzzer`. Same `exit(0)` behaviour (SD-07). |
| `__VERIFIER_error` | `void __VERIFIER_error(void)` | — | new | Feature `libfuzzer`. Prints a REACHABILITY report, then aborts (SD-08). |
| `__VERIFIER_assert` | `void __VERIFIER_assert(int32_t condition)` | — | new | Feature `libfuzzer`. `__VERIFIER_assert(0)` calls `__VERIFIER_error()` (SD-08). |
| `next_current_step` | — | `next_current_step()` | discontinued | Use `get_next_step()`; same effect (#13). |
| `map2check_save_memtrack_log` | — | `memtracklog.h:44` | discontinued | Covered by the `map2check_map_*` exports; no external caller. |
| `map2check_gen_data_fuzzer_*` | — | bool, char, uchar, short, ushort, int32_t, int64_t, uint, unsigned, long, ulong, float, double, size_t | discontinued | Replaced by `__VERIFIER_nondet_*` (#12). |
| `map2check_gen_data_fuzzer_pchar` | — | kernel type generator | discontinued | See “Discontinued: pchar / loff_t / sector_t” (#6). |
| `map2check_gen_data_fuzzer_loff_t` | — | kernel type generator | discontinued | See “Discontinued: pchar / loff_t / sector_t” (#6). |
| `map2check_gen_data_fuzzer_sector_t` | — | kernel type generator | discontinued | See “Discontinued: pchar / loff_t / sector_t” (#6). |
| `debug_*_set_only_test` | — | 4 C test hooks | discontinued | C unit-test hooks; Rust tests use `state::test_lock()`. |

## Map2Check pass matrix

Symbols inserted by the passes of `hbgit/Map2Check@develop` (plan
§1.2(b)). The compatibility layer that would export them is #21. Until it
lands, `libmap2check.a` cannot replace the C library embedded in
Map2Check.

| Symbol | Signature expected by the passes | Status | Notes |
|---|---|---|---|
| `map2check_init` | `map2check_init(int)` | changed | Core export takes `void`. |
| `map2check_check_deref` | `map2check_check_deref(i64, ptr)` | changed | Same name, incompatible core signature `(ptr, u32, u32, ptr)`. The plan (§2.1, D1) proposes renaming the core export to `map2check_check_deref_v2` inside the compat layer; decision in #21. |
| `map2check_track_bb` | `(u32, ptr)` | pending | Core equivalent: `map2check_save_basic_block_log` (#21). |
| `map2check_alloca` | `(ptr, ptr, i64, i64, i64, i64)` | pending | Core equivalent: `map2check_map_alloca` with `int32_t` sizes (#21). |
| `map2check_non_static_alloca` | `(ptr, ptr, i64, i64, i64, i64)` | pending | Core equivalent: `map2check_map_non_static_alloca` (#21). |
| `map2check_malloc` | `(ptr, i64)` | pending | Core equivalent: `map2check_map_malloc` (#21). |
| `map2check_calloc` | `(ptr, i64, i64)` | pending | Core equivalent: `map2check_map_calloc` (#21). |
| `map2check_posix` | `(ptr, i64)` | pending | Deprecated in the embedded C library (#21). |
| `map2check_free` | `(ptr, ptr, i64, i64, ptr)` | pending | The pass passes the address of the pointer variable (#21). |
| `map2check_free_resolved_address` | `(ptr, i64, ptr, i1)` | pending | Core equivalent: `map2check_check_free_resolved_address` (#21). |
| `map2check_load` | `(ptr, i64)` | pending | Core `map2check_check_load` takes 5 arguments (#21). |
| `map2check_add_store_pointer` | 6 arguments | pending | Core `map2check_map_store_pointer` differs in order and types (#21). |
| `map2check_function` | `(ptr, ptr)` | pending | Core equivalent: `map2check_map_funct_address` (#21). |
| `map2check_target_function` | — | pending | #21. |
| `map2check_assume` | — | pending | #21. |
| `map2check_assume_loop` | — | pending | #21. |
| `map2check_crab_assume` | — | pending | #21. |
| `map2check_assert` | — | pending | #21. |
| `map2check_non_det_*` | 16 typed generators: bool, char, double, int, loff_t, long, pchar, pointer, sector_t, short, size_t, uchar, uint, ulong, unsigned, ushort | pending | #21; see also #6. |
| `map2check_nondet_cast_*` | — | pending | #21. |
| `map2check_pointer_cast` | — | pending | #21. |
| `map2check_wasm_malloc` | — | out-of-scope | Only used by the `feat-wasm-verification` flow (#21). |
| `map2check_wasm_free` | — | out-of-scope | As above. |
| `map2check_wasm_check_access` | — | out-of-scope | As above. |
| `__VERIFIER_nondet_*` | `int`, `uint`, `char`, `long`, `ushort`, `pointer` | same | Feature `libfuzzer`. |
| `__VERIFIER_assume` | `(int)` | same | Feature `libfuzzer` (SD-07). |
| `__VERIFIER_assert` | `(int)` | same | Feature `libfuzzer` (SD-08). |
| `__VERIFIER_error` | `(void)` | same | Feature `libfuzzer` (SD-08). |

The passes also expect the result channel of the embedded library: files
named `map2check_property_*` that the Map2Check frontend parses. This
library only prints the JSON report on stdout (SD-01). The file channel is
tracked in #19.

## Discontinued: `map2check_gen_data_fuzzer_pchar` / `_loff_t` / `_sector_t`

**Status:** discontinued, not ported to `feature/rust`.

The legacy C library exposed LibFuzzer-backed nondet generators for a few
Linux-kernel/POSIX-specific types (`pchar`, `loff_t`, `sector_t`) alongside
the generic numeric ones. `feature/rust` replaces the whole
`map2check_gen_data_fuzzer_*` family with the SV-COMP-standard
`__VERIFIER_nondet_*` functions (`rust/src/nondet/libfuzzer.rs`), which cover
every portable numeric/bool/pointer type. `pchar`/`loff_t`/`sector_t` have no
portable Rust equivalent (they are kernel ABI types, not part of any target
this library instruments), and no consumer in this repository or in
`Map2Check@develop`'s passes references them. Reintroducing them would mean
adding non-portable, untested surface area for a use case nobody currently
exercises.

**Decision:** do not implement. If a concrete consumer appears, add a
`__VERIFIER_nondet_*`-style generator for the specific width needed instead
of resurrecting the old kernel-typed names.

## Accepted: `__VERIFIER_assume` / `map2check_fuzzer_assume` end the process

`__VERIFIER_assume(0)` and `map2check_fuzzer_assume(0)` call
`std::process::exit(0)` instead of unwinding back to the caller. LibFuzzer
runs many inputs within a single process, and the assumption is violated
arbitrarily deep in a call stack that began at `LLVMFuzzerTestOneInput`.
There is no portable way to unwind out of it: the entry point is
`extern "C"`, and a Rust panic must not cross an FFI boundary regardless of
the release profile's panic strategy. This matches the
convention used by SV-COMP's native/concrete-execution harnesses. It does end
the fuzzing campaign for the current process — accepted as a known
limitation; full symbolic-execution semantics (path pruning under KLEE) is
deferred to the M4 KLEE spike. See doc comments in
`rust/src/nondet/libfuzzer.rs`.

## Accepted: `map2check_map_non_static_alloca` / `map2check_map_funct_address` semantics

The legacy C headers that defined these symbols
(`container_memtracklog.h:44,48`) no longer exist in this repository (the
`master` C branch's history was not carried over). Their signatures and exact
semantics were reconstructed from the paridade table and from the existing
`map2check_map_alloca`/`map2check_map_malloc` patterns in
`rust/src/ffi.rs`, not from the original C source:

- `map2check_map_non_static_alloca` — same shape as `map2check_map_alloca`,
  but the resulting entry is marked dynamic (`entry.set_malloc()`), so
  `map2check_check_mem_endprog` accounts for it like a heap allocation
  instead of a plain stack slot.
- `map2check_map_funct_address` — registers a function's address as an
  always-valid load target (pointer-width `size_destiny`), so that reading a
  function pointer through `map2check_check_load`/`map2check_check_deref`
  does not get flagged as an invalid address.

The embedded C library of Map2Check (`lib_old/AnalysisModeMemtrack.c:366-377`
on `origin/refactory_memory_log`) does the opposite for
`map2check_non_static_alloca`: it registers a static slot of
`size * size_of_primitive` bytes. The Rust choice makes an unfreed VLA show
up as a leak at end of program; see SD-12.

**Risk:** if the M5 compatibility layer (`ffi_compat.rs`, consuming the exact
signatures the Map2Check LLVM passes insert) reveals a different expected
semantics, this section documents the M3 baseline that was changed and why.

## Accepted: `char` ABI is `i8`, not the legacy `u8`

`map2check_save_nondet_log_char` now takes `i8` (matching
`__VERIFIER_nondet_char() -> i8`, already `i8` before this change) instead of
`u8`. C's `char` is platform-defined (signed on x86/x86_64, unsigned by
default on most ARM targets); this crate follows the more common
x86/x86_64 convention and does not special-case ARM. If Map2Check ever
targets a plain-`char`-is-unsigned platform, this will need a
target-specific cfg.

## Discontinued: `next_current_step`

The legacy C library had both `get_next_step()` and `next_current_step()`
for advancing the step counter (plan §1.2(a)). Only `get_next_step()` is
exported (#13): it advances the counter and returns the new value, which
covers both uses. No consumer in this repository or in the Map2Check passes
calls `next_current_step`.

## Accepted: `map2check_check_free_resolved_address` semantics

`map2check_check_free_resolved_address(ptr, line, function_name,
is_null_valid)` receives the heap address itself (after the pointer was
loaded), not the address of the pointer variable that `map2check_check_free`
receives. The Rust export:

- returns without a check when `ptr` is NULL and `is_null_valid != 0`;
- reports `MEMSAFETY_FREE` when the most recent record whose
  `mem_address_points_to` equals `ptr` is already freed;
- treats an address with no record as safe;
- only checks: it does not mark the block freed. The caller records the
  release with `map2check_map_free`.

The embedded C library of Map2Check
(`lib_old/AnalysisModeMemtrack.c:164-183` and `lib_old/ListLog.c:95-118` on
`origin/refactory_memory_log`) differs in two ways: an address with no
record is an invalid free, and the function also marks the block freed. The
first difference is SD-06. The second keeps the split between checking and
recording that the rest of the core API already uses.
````

De onde veio cada coluna, para a revisão:
- A coluna "Rust declaration" é a saída de `header_declarations` sobre o header gerado por `cargo build --all-features` em `9600fc0` (62 funções).
- A coluna "Legacy C library" e os status vêm do plano, §1.2(a). Quando a assinatura legada não foi registrada no plano, a célula cita o header C (`container_memtracklog.h:44`) em vez de inventar uma assinatura.
- A matriz dos passes vem do §1.2(b) e de `audit/evidence/missing_compat.txt` (branch `develop`).

- [ ] **Step 4: Rodar e ver passar**

Run: `cargo test --all-features --test compat_docs`
Expected: PASS, `4 passed`.

- [ ] **Step 5: Conferir que o teste pega deriva**

Troque temporariamente, na matriz, `int32_t size)` de `map2check_map_malloc` por `int64_t size)` e rode `cargo test --all-features --test compat_docs`. Expected: FAIL em `matriz_nucleo_cobre_o_header_com_declaracoes_exatas`, com ``map2check_map_malloc`: declaração no doc ... difere do header``. Desfaça a troca (`git diff docs/api-deltas.md` deve voltar a mostrar só a reescrita).

- [ ] **Step 6: Lint e commit**

```bash
cargo fmt
cargo clippy --all-targets --all-features -- -D warnings
git add tests/compat_docs.rs docs/api-deltas.md
git commit -m "docs: add symbol/signature compatibility matrix to api-deltas (#5)

Core C API rows mirror include/map2check.h exactly; Map2Check pass rows
record what #21 still has to provide. tests/compat_docs.rs fails when
the header and the matrix drift apart. Also records next_current_step
(#13 M3-E1) and the free_resolved_address semantics (#13 M3-I2)."
```

---

### Task 3: Guia de integração com exemplos JSON verificados

**Files:**
- Create: `docs/integration-guide.md`
- Modify: `tests/compat_docs.rs` (imports, `STATE_LOCK` e funções novas no fim)

**Interfaces:**
- Consumes: `map2check::ffi::*` (`map2check_reset`, `map2check_save_basic_block_log`, `map2check_save_nondet_log_int`, `set_false_result`, `map2check_map_malloc`, `map2check_check_free`), `map2check::state::with_state`, `map2check::output::to_json` (todos `pub` em `rust/src/lib.rs`).
- Produces: o teste `integration_guide_json_examples_match_the_serializer`, que a entrada SD-01 da Task 5 cita por nome, e os marcadores `<!-- example: success|violation|memory -->` no guia.

- [ ] **Step 1: Escrever o teste**

Em `tests/compat_docs.rs`, troque:

```rust
use std::collections::{BTreeMap, BTreeSet};

use common::{header_declarations, normalize, read};
```

por:

```rust
use std::collections::{BTreeMap, BTreeSet};
use std::sync::Mutex;

use common::{header_declarations, normalize, read};

/// Serializa os testes deste binário que tocam o estado global da biblioteca.
static STATE_LOCK: Mutex<()> = Mutex::new(());
```

e acrescente no fim do arquivo:

````rust

/// Bloco ```json logo após `<!-- example: NAME -->` no guia.
fn guide_example(guide: &str, name: &str) -> serde_json::Value {
    let marker = format!("<!-- example: {name} -->\n```json\n");
    let start = guide
        .find(&marker)
        .unwrap_or_else(|| panic!("exemplo `{name}` ausente do guia"))
        + marker.len();
    let len = guide[start..].find("\n```").expect("bloco json sem fim");
    serde_json::from_str(&guide[start..start + len])
        .unwrap_or_else(|e| panic!("exemplo `{name}` não é JSON válido: {e}"))
}

fn report() -> serde_json::Value {
    let json = map2check::state::with_state(|s| map2check::output::to_json(s)).unwrap();
    serde_json::from_str(&json).unwrap()
}

#[test]
fn integration_guide_json_examples_match_the_serializer() {
    use map2check::ffi::*;
    let _guard = STATE_LOCK.lock().unwrap_or_else(|e| e.into_inner());
    let guide = read("docs/integration-guide.md");

    map2check_reset();
    let mut seven: i32 = 7;
    // SAFETY: C-string literals are valid; `seven` outlives the call.
    unsafe {
        map2check_save_basic_block_log(10, c"main".as_ptr());
        map2check_save_nondet_log_int(11, 0, 0, &mut seven, c"main".as_ptr());
    }
    assert_eq!(
        report(),
        guide_example(&guide, "success"),
        "exemplo `success`"
    );

    // SAFETY: C-string literal is valid.
    unsafe { set_false_result(5, 12, c"main".as_ptr()) };
    assert_eq!(
        report(),
        guide_example(&guide, "violation"),
        "exemplo `violation`"
    );

    map2check_reset();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(0x1000 as *const _, 16);
        map2check_check_free(c"p".as_ptr(), 0x2000 as *const _, 0, 20, c"main".as_ptr());
    }
    assert_eq!(
        report(),
        guide_example(&guide, "memory"),
        "exemplo `memory`"
    );
    map2check_reset();
}
````

- [ ] **Step 2: Rodar e ver falhar**

Run: `cargo test --all-features --test compat_docs integration_guide`
Expected: FAIL com `falha ao ler .../docs/integration-guide.md`.

- [ ] **Step 3: Escrever `docs/integration-guide.md`**

````markdown
# Integration guide — linking `libmap2check.a` from C

This guide covers what a C program or an instrumentation pass needs to use
the Rust `map2check-library`: the release contents, how to link, call
order, the JSON report and the known gaps. Compatibility details are in
[`api-deltas.md`](api-deltas.md) (symbols and signatures) and
[`semantic-deltas.md`](semantic-deltas.md) (behaviour).

## Release contents

A release archive `map2check-library-<version>-<target>.tar.gz` (see
[`release.md`](release.md)) unpacks to:

```
map2check-library-<version>-<target>/
├── include/map2check.h      # C header; MAP2CHECK_VERSION == <version>
├── lib/libmap2check.a            # plain C programs (no features)
├── lib/libmap2check_libfuzzer.a  # LibFuzzer targets (feature libfuzzer)
├── docs/integration-guide.md
├── docs/api-deltas.md
├── docs/semantic-deltas.md
├── CHANGELOG.md
└── LICENSE                  # GPL-3.0-only
```

A `SHA256SUMS` file next to the archive covers it.

## Building from source

Without a release archive, run this from the repository root:

```sh
cargo build --release                       # plain C programs
cargo build --release --features libfuzzer  # LibFuzzer targets (overwrites the same .a)
```

`build.rs` regenerates `include/map2check.h` on every build. The header is
not committed (`.gitignore`), so always take it from the same build as the
library.

## Linking

```sh
cc -I include my_program.c lib/libmap2check.a -ldl -lpthread -lm -o my_program
```

- `-ldl -lpthread -lm` are the system libraries that the Rust standard
  library needs.
- Use `lib/libmap2check.a` for ordinary programs. It does not define the
  `__VERIFIER_*` functions or `LLVMFuzzerTestOneInput`, even though the
  header declares them.
- Use `lib/libmap2check_libfuzzer.a` for LibFuzzer targets. It defines
  `LLVMFuzzerTestOneInput`, which calls `int __map2check_main__(void)`. The
  program must define that function and be built with
  `clang -fsanitize=fuzzer`. Without that function, the link fails with
  `undefined reference to '__map2check_main__'`.
- The header and the library must come from the same build. The header
  carries the version as a string, `MAP2CHECK_VERSION` (for example
  `"1.0.0-rc1"`), so you can log it or check it in your build:

  ```c
  #include "map2check.h"
  #ifndef MAP2CHECK_VERSION
  #error "map2check.h is older than 1.0.0-rc1"
  #endif
  ```

## Call order

1. `map2check_init()` once, before any other call.
2. Tracking calls as the program runs: `map2check_save_basic_block_log`,
   `map2check_save_nondet_log_*`, `map2check_map_*`.
3. Check calls next to the operation they guard: `map2check_check_load`,
   `map2check_check_free`, `map2check_check_deref`, `map2check_binop_*`,
   `map2check_is_valid_assert`.
4. Optionally, `map2check_set_memcleanup()` and then
   `map2check_check_mem_endprog()` at exit.
5. `map2check_success()` or `print_all_containers_as_json()` to emit the
   report; `get_current_property()` reads the verdict without printing.
6. `map2check_reset()` to analyse another input in the same process.
   LibFuzzer builds do this on every iteration.

A violation does not stop the program, and a later safe memory check
resets the verdict (SD-03). Read the verdict right after the check you care
about.

## JSON report

`print_all_containers_as_json()` prints one pretty-printed JSON object on
stdout. Whitespace is not part of the contract; parse it. The examples
below are checked against the real serializer by
`tests/compat_docs.rs::integration_guide_json_examples_match_the_serializer`.

Calls `map2check_save_basic_block_log(10, "main")` and then
`map2check_save_nondet_log_int(11, 0, INT_ID, &seven, "main")` print:

<!-- example: success -->
```json
{
  "map2check_log": {
    "result": "TRUE",
    "step": 2,
    "Container_TrackBBLog": [
      { "step": 1, "line": 10, "function_name": "main" }
    ],
    "Container_NonDetLog": [
      {
        "step": 2,
        "line": 11,
        "scope": 0,
        "function_name": "main",
        "value": { "type": "INT", "value": 7 }
      }
    ]
  }
}
```

The same calls followed by `set_false_result(5 /* Reachability */, 12, "main")`
print:

<!-- example: violation -->
```json
{
  "map2check_log": {
    "result": "FALSE",
    "step": 2,
    "property": "REACHABILITY",
    "line_number": 12,
    "function_name": "main",
    "Container_TrackBBLog": [
      { "step": 1, "line": 10, "function_name": "main" }
    ],
    "Container_NonDetLog": [
      {
        "step": 2,
        "line": 11,
        "scope": 0,
        "function_name": "main",
        "value": { "type": "INT", "value": 7 }
      }
    ]
  }
}
```

`Container_AllocationLog` appears only for memory-safety violations (SD-02).
`map2check_map_malloc((void *)0x1000, 16)` followed by
`map2check_check_free("p", (void *)0x2000, 0, 20, "main")` prints:

<!-- example: memory -->
```json
{
  "map2check_log": {
    "result": "FALSE",
    "step": 1,
    "property": "MEMSAFETY_FREE",
    "line_number": 20,
    "function_name": "main",
    "Container_TrackBBLog": [],
    "Container_NonDetLog": [],
    "Container_AllocationLog": [
      {
        "step": 1,
        "line": 0,
        "scope": 0,
        "var_mem_address": 4096,
        "mem_address_points_to": 4096,
        "is_dynamic": true,
        "is_free": false,
        "ptr_name": "",
        "function_name": "",
        "size_destiny": 16,
        "size_primitive": 1,
        "is_null_valid": false
      }
    ]
  }
}
```

`property` takes one of `OVERFLOW`, `MEMSAFETY_FREE`, `MEMSAFETY_DEREF`,
`MEMSAFETY_MEMTRACK`, `MEMSAFETY_MEMCLEANUP`, `REACHABILITY` and
`CONCURRENCY`. Nondet `type` takes one of `INT`, `UINT`, `LONG`, `CHAR`,
`FLOAT` and `DOUBLE`. The schema is not final: container and field names
are still being reconciled with the existing consumer in #14 (SD-01).

## Known gaps

- **Map2Check passes:** the passes of `hbgit/Map2Check@develop` insert a
  different symbol family (`map2check_track_bb`, `map2check_alloca`, …) and
  cannot link against this library yet. See the pass matrix in
  `api-deltas.md` and #21.
- **Result files:** the Map2Check frontend reads `map2check_property_*`
  files; this library only prints JSON (#19).
- **KLEE:** no KLEE build exists yet; the decision is #20.
- **Thread safety:** the state sits behind one global mutex. The calls are
  safe from any thread but serialise, and a callback must not re-enter the
  library while a call is running.
````

- [ ] **Step 4: Rodar e ver passar**

Run: `cargo test --all-features --test compat_docs`
Expected: PASS, `5 passed`. Se o exemplo divergir, a mensagem `exemplo \`...\`` mostra os dois valores. Corrija o **doc** a partir da saída real: este plano não muda o serializador.

- [ ] **Step 5: Lint e commit**

```bash
cargo fmt
cargo clippy --all-targets --all-features -- -D warnings
git add tests/compat_docs.rs docs/integration-guide.md
git commit -m "docs: add C integration guide with serializer-checked JSON examples (#5)"
```

---

### Task 4: CHANGELOG versionado

**Files:**
- Create: `CHANGELOG.md`
- Modify: `tests/header_version.rs` (teste novo antes de `label_do_dockerfile_bate_com_versao_do_crate`)

**Interfaces:**
- Consumes: `VERSION` (`env!("CARGO_PKG_VERSION")`) e `read` já existentes em `tests/header_version.rs`.
- Produces: `CHANGELOG.md` com `## [Unreleased]` e `## [1.0.0-rc1] - Unreleased`. A Task 5 lê este arquivo (`todo_sd_citado_existe_em_semantic_deltas`), e a Task 6 exige a seção da versão no script de pacote.

- [ ] **Step 1: Escrever o teste**

Em `tests/header_version.rs`, logo antes de `#[test]\nfn label_do_dockerfile_bate_com_versao_do_crate() {`, insira:

```rust
#[test]
fn changelog_tem_secao_da_versao_do_crate() {
    let changelog = read("CHANGELOG.md");
    let heading = format!("## [{VERSION}]");
    assert!(
        changelog.lines().any(|l| l.starts_with(&heading)),
        "CHANGELOG.md não tem a seção `{heading}` (issue #5)"
    );
}

```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cargo test --all-features --test header_version`
Expected: FAIL com `falha ao ler .../CHANGELOG.md`.

- [ ] **Step 3: Criar `CHANGELOG.md`**

````markdown
# Changelog

All notable changes to `map2check-library` are recorded here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
versions follow [Semantic Versioning](https://semver.org/). The version
comes from `Cargo.toml` and is repeated in `MAP2CHECK_VERSION`
(`include/map2check.h`) and in the `Dockerfile` label.
`tests/header_version.rs` fails when this file has no section for the
current version.

Compatibility with the legacy C library is tracked in
[`docs/api-deltas.md`](docs/api-deltas.md) and
[`docs/semantic-deltas.md`](docs/semantic-deltas.md); a change that touches
the C ABI or the JSON report must update them.

## [Unreleased]

### Added

- `docs/api-deltas.md` symbol/signature matrix for the core C API and the
  Map2Check passes, and `docs/semantic-deltas.md` with reproducible
  behaviour differences, both checked by `tests/compat_docs.rs` (#5).
- `docs/integration-guide.md` and `docs/release.md`;
  `scripts/package-release.sh` builds the release archive with the C
  header, both static libraries and the docs (#5).

## [1.0.0-rc1] - Unreleased

First release candidate of the Rust rewrite (milestones M1–M3).

### Added

- Rust implementation of the C ABI in `rust/src/ffi.rs`, with
  `include/map2check.h` generated by `cbindgen` from `build.rs`.
- `map2check_reset()`, `get_next_step()`,
  `map2check_map_non_static_alloca`, `map2check_map_funct_address`,
  `map2check_check_free_resolved_address`, and the LibFuzzer generators
  `__VERIFIER_nondet_*`, `__VERIFIER_assume`, `__VERIFIER_assert`,
  `__VERIFIER_error` and `map2check_fuzzer_assume` (feature `libfuzzer`)
  (#2, #3).
- `#define MAP2CHECK_VERSION` in the generated header (#28).
- Unit tests for every exported FFI symbol and a checklist that fails on an
  untested export (#29).
- CI: formatting, Clippy, tests, an ASan/UBSan C harness, C integration
  programs, cargo-deny, cargo-audit, Docker build, and an 80% coverage gate
  outside `ffi*.rs` (#1, #30); branch protection for `feature/rust` and
  `master` (#26).

### Changed

- JSON report produced by `serde_json`; shape in
  `docs/integration-guide.md`, differences in SD-01.
- `map2check_save_nondet_log_char` takes `char` as `i8` (see
  `docs/api-deltas.md`).
- Every export catches panics at the FFI boundary, and the global state
  sits behind a mutex (#2).

### Removed

- `map2check_gen_data_fuzzer_*`, `next_current_step` and the C-era build
  files and docs (#27). See `docs/api-deltas.md` for each removal.
````

Os números de PR vêm de `gh pr list --state merged --base feature/rust`: #1 (M1), #2 (M2), #3 (M3), #4, #30 (coverage), #31 (#26), #32 (#27), #33 (#28) e #34 (#29). A data fica `Unreleased` até a tag `v1.0.0-rc1`, que depende do fechamento de #13 (ver #28).

- [ ] **Step 4: Rodar e ver passar**

Run: `cargo test --all-features --test header_version`
Expected: PASS, `3 passed`.

- [ ] **Step 5: Commit**

```bash
git add CHANGELOG.md tests/header_version.rs
git commit -m "docs: add CHANGELOG and require a section for the crate version (#5)"
```

---

### Task 5: Desvios semânticos reproduzíveis em `docs/semantic-deltas.md`

**Files:**
- Create: `docs/semantic-deltas.md`
- Modify: `rust/src/ffi_tests.rs` (2 testes novos)
- Modify: `tests/compat_docs.rs` (import `Path` e funções novas no fim)

**Interfaces:**
- Consumes: os helpers de `rust/src/ffi_tests.rs` (`fresh()`, `addr()`, `assert_violated()`); os testes já existentes citados nas entradas (todos conferidos em `9600fc0`); `integration_guide_json_examples_match_the_serializer` (Task 3); `CHANGELOG.md` (Task 4).
- Produces: IDs `SD-01` a `SD-12`, que `docs/api-deltas.md` e `docs/integration-guide.md` já citam; os testes `legacy_records_are_returned_unlinked` e `non_static_alloca_is_reported_as_leak_at_end_of_program`.

- [ ] **Step 1: Escrever os testes de consistência**

Em `tests/compat_docs.rs`, troque `use std::collections::{BTreeMap, BTreeSet};` por:

```rust
use std::collections::{BTreeMap, BTreeSet};
use std::path::Path;
```

e acrescente no fim do arquivo:

````rust

/// IDs `SD-NN` citados em `text`.
fn sd_ids(text: &str) -> BTreeSet<String> {
    text.match_indices("SD-")
        .filter_map(|(at, _)| {
            let digits = text.get(at + 3..at + 5)?;
            digits
                .chars()
                .all(|c| c.is_ascii_digit())
                .then(|| format!("SD-{digits}"))
        })
        .collect()
}

/// Entradas `### SD-NN — ...` de semantic-deltas.md: (id, corpo).
fn sd_entries(doc: &str) -> Vec<(String, String)> {
    doc.split("\n### ")
        .skip(1)
        .filter(|chunk| chunk.starts_with("SD-"))
        .map(|chunk| (chunk[..5].to_string(), chunk.to_string()))
        .collect()
}

const CLASSIFICATIONS: &[&str] = &[
    "intentional",
    "accepted limitation",
    "suspected regression",
    "pending decision",
];

/// Problemas de uma entrada: classificação conhecida (com issue quando
/// exigido) e testes `arquivo::função` que existem.
fn sd_entry_problems(id: &str, body: &str, root: &Path) -> Vec<String> {
    let mut problems = Vec::new();
    let field = |name: &str| {
        body.lines()
            .find_map(|l| l.strip_prefix(&format!("**{name}:**")))
            .map(str::trim)
    };
    match field("Classification") {
        None => problems.push(format!("{id}: sem **Classification:**")),
        Some(c) => match CLASSIFICATIONS.iter().find(|k| c.starts_with(*k)) {
            None => problems.push(format!("{id}: classificação desconhecida `{c}`")),
            Some(k)
                if matches!(*k, "suspected regression" | "pending decision")
                    && !c.contains('#') =>
            {
                problems.push(format!("{id}: `{k}` precisa citar uma issue (#N)"))
            }
            Some(_) => {}
        },
    }
    let Some(tests) = field("Tests") else {
        problems.push(format!("{id}: sem **Tests:**"));
        return problems;
    };
    let refs: Vec<&str> = tests.split('`').skip(1).step_by(2).collect();
    if refs.is_empty() {
        problems.push(format!("{id}: **Tests:** sem `arquivo::função`"));
    }
    for r in refs {
        let Some((file, func)) = r.rsplit_once("::") else {
            problems.push(format!("{id}: referência `{r}` não é `arquivo::função`"));
            continue;
        };
        match std::fs::read_to_string(root.join(file)) {
            Err(_) => problems.push(format!("{id}: arquivo `{file}` não existe")),
            Ok(src) if !src.contains(&format!("fn {func}(")) => {
                problems.push(format!("{id}: `{file}` não tem `fn {func}(`"))
            }
            Ok(_) => {}
        }
    }
    problems
}

#[test]
fn semantic_deltas_tem_ids_em_ordem_classificacao_e_testes_existentes() {
    let doc = read("docs/semantic-deltas.md");
    let root = Path::new(env!("CARGO_MANIFEST_DIR"));
    let entries = sd_entries(&doc);
    assert!(!entries.is_empty(), "nenhuma entrada `### SD-NN`");
    let mut problems = Vec::new();
    for (i, (id, body)) in entries.iter().enumerate() {
        let expected = format!("SD-{:02}", i + 1);
        if *id != expected {
            problems.push(format!("esperava {expected}, veio {id}"));
        }
        problems.extend(sd_entry_problems(id, body, root));
    }
    assert!(problems.is_empty(), "{}", problems.join("\n"));
}

#[test]
fn semantic_deltas_acusa_teste_inexistente_e_classificacao_sem_issue() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR"));
    let body = "SD-01 — x\n\n**Classification:** suspected regression\n\
                **Tests:** `rust/src/ffi_tests.rs::nao_existe`, `nao/existe.rs::f`\n";
    let problems = sd_entry_problems("SD-01", body, root);
    assert_eq!(problems.len(), 3, "{problems:?}");
    assert!(problems[0].contains("precisa citar uma issue"));
    assert!(problems[1].contains("não tem `fn nao_existe(`"));
    assert!(problems[2].contains("arquivo `nao/existe.rs` não existe"));
}

#[test]
fn todo_sd_citado_existe_em_semantic_deltas() {
    let defined: BTreeSet<String> = sd_entries(&read("docs/semantic-deltas.md"))
        .into_iter()
        .map(|(id, _)| id)
        .collect();
    let mut missing = Vec::new();
    for doc in [
        "docs/api-deltas.md",
        "docs/integration-guide.md",
        "CHANGELOG.md",
    ] {
        for id in sd_ids(&read(doc)) {
            if !defined.contains(&id) {
                missing.push(format!("{doc}: {id}"));
            }
        }
    }
    assert!(missing.is_empty(), "SD inexistente citado: {missing:?}");
}
````

- [ ] **Step 2: Rodar e ver falhar**

Run: `cargo test --all-features --test compat_docs`
Expected: FAIL. `semantic_deltas_tem_ids_em_ordem_classificacao_e_testes_existentes` e `todo_sd_citado_existe_em_semantic_deltas` falham com `falha ao ler .../docs/semantic-deltas.md`. O teste sintético `semantic_deltas_acusa_teste_inexistente_e_classificacao_sem_issue` passa.

- [ ] **Step 3: Adicionar os dois testes de caracterização em `rust/src/ffi_tests.rs`**

Logo depois de `fn save_basic_block_log_records_block() { ... }` (antes de `fn is_in_trackbb_container_reports_recorded_lines`), insira:

```rust
#[test]
fn legacy_records_are_returned_unlinked() {
    let _guard = fresh();
    let mut value: i32 = 1;
    // SAFETY: C-string literals are valid; `value` outlives the calls.
    let (bb1, bb2, nd) = unsafe {
        (
            map2check_save_basic_block_log(1, c"main".as_ptr()),
            map2check_save_basic_block_log(2, c"main".as_ptr()),
            map2check_save_nondet_log_int(3, 0, 0, &mut value, c"main".as_ptr()),
        )
    };
    // SAFETY: the records are owned by the global state, kept alive under the lock.
    let (bb1, bb2, nd) = unsafe { (&*bb1, &*bb2, &*nd) };
    for (next, prev) in [
        (bb1.tqe_next.is_null(), bb1.tqe_prev.is_null()),
        (bb2.tqe_next.is_null(), bb2.tqe_prev.is_null()),
        (nd.tqe_next.is_null(), nd.tqe_prev.is_null()),
    ] {
        assert!(next && prev, "registro legado ligado a uma lista");
    }
    assert_eq!((bb1.step, bb2.step, nd.step), (1, 2, 3));
}
```

Logo depois de `fn map_non_static_alloca_records_dynamic_slot() { ... }` (antes de `fn map_funct_address_records_pointer_sized_slot`), insira:

```rust
#[test]
fn non_static_alloca_is_reported_as_leak_at_end_of_program() {
    // Fixa o comportamento atual descrito em SD-12 (docs/semantic-deltas.md);
    // o legado registra o VLA como slot estático e não acusa vazamento.
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_map_non_static_alloca(c"vla".as_ptr(), addr(0x2000), 16, 4, 3, 0) };
    map2check_set_memcleanup();
    map2check_check_mem_endprog();
    assert_violated(ViolatedProperty::MemsafetyMemcleanup, 0, "end_of_program");
}
```

São testes de caracterização: passaram de primeira no protótipo. Se falharem, **não mude `ffi.rs`**. Pare e reporte, porque o comportamento descrito em SD-10/SD-12 mudou.

- [ ] **Step 4: Escrever `docs/semantic-deltas.md`**

````markdown
# Semantic deltas — Rust `map2check-library` vs. the legacy C implementations

Behaviour differences between the Rust library and the legacy C code. Each
entry has an ID (`SD-NN`) that [`api-deltas.md`](api-deltas.md) cites, a
classification, a C snippet against `include/map2check.h` that reproduces
it, and the Rust tests that pin the current behaviour.

"Legacy" means one of two C codebases, and each entry says which:

- the C `map2check-library` that this repository shipped before the rewrite
  (see `docs/plano_map2check_library_rust.md` §1.2 on `master`);
- the C library embedded in Map2Check, available here as `lib_old/` on the
  `origin/refactory_memory_log` branch (commit `68d174d`).

Where the legacy behaviour was not read from source, the entry says so. The
differential harness in #15 will settle those cases.

`tests/compat_docs.rs` checks that IDs run in order with no gaps, that every
classification is from the list below, that `pending decision` and
`suspected regression` cite an issue, and that every test named under
**Tests** exists. When a fix changes one of these behaviours, update the
entry and its tests in the same change.

## Classifications

| Classification | Meaning |
|---|---|
| `intentional` | Deliberate change, kept. |
| `accepted limitation` | Known downside, accepted for now; the entry says why. |
| `suspected regression` | Probably wrong; an issue tracks adjudication. |
| `pending decision` | Waits on the cited issue. |

### SD-01 — JSON report shape

**Classification:** pending decision (#14)
**Tests:** `tests/compat_docs.rs::integration_guide_json_examples_match_the_serializer`, `rust/src/output/mod.rs::output_is_valid_json`

**Rust:** `print_all_containers_as_json()`, `map2check_success()` and a
failing `map2check_is_valid_assert()` print one pretty-printed JSON object
on stdout. The top-level key is `map2check_log`; `result` is `"TRUE"` or
`"FALSE"`; `property`, `line_number` and `function_name` appear only when
`result` is `"FALSE"`; containers are named `Container_TrackBBLog`,
`Container_NonDetLog` and `Container_AllocationLog`. Memory records use
`var_mem_address`/`mem_address_points_to`, and nondet values are
`{"type": "INT", "value": 7}`. The exact shape is in
[`integration-guide.md`](integration-guide.md#json-report).

**Legacy (C `map2check-library`):** a hand-built compact JSON. Issue #14
lists container names `container_trackbb_log`, `container_nondet_log` and
`container_memtrack_log`, and asks whether a top-level `function_name` is
part of the schema. Whitespace alone is not a semantic difference.

**Reproduce:**

```c
map2check_init();
map2check_save_basic_block_log(10, "main");
print_all_containers_as_json();
```

### SD-02 — Allocation log only on memory violations

**Classification:** intentional
**Tests:** `rust/src/output/mod.rs::memtrack_included_only_for_memory_violations`

**Rust:** `Container_AllocationLog` is emitted only when the violated
property is `MEMSAFETY_FREE`, `MEMSAFETY_DEREF`, `MEMSAFETY_MEMTRACK` or
`MEMSAFETY_MEMCLEANUP`. Reports for other outcomes stay small.

**Legacy:** not verified against source (#15).

**Reproduce:**

```c
map2check_init();
map2check_map_malloc((void *)0x1000, 16);
set_false_result(0 /* Overflow */, 3, "main");
print_all_containers_as_json();   /* no Container_AllocationLog */
set_false_result(1 /* MemsafetyFree */, 4, "main");
print_all_containers_as_json();   /* Container_AllocationLog present */
```

### SD-03 — Violations do not stop the analysis, and a later safe memory check clears them

**Classification:** suspected regression (#15)
**Tests:** `rust/src/ffi_tests.rs::check_load_clears_a_previous_violation_when_safe`

**Rust:** a check that finds a violation records it and returns. The process
keeps running. The memory checks (`map2check_check_load`,
`map2check_check_free`, `map2check_check_free_resolved_address`,
`map2check_check_deref`, `map2check_check_mem_endprog`) reset the result to
OK before they check. So a later safe access erases any earlier violation,
including one that `set_false_result` recorded.

**Legacy (embedded C library):** every violation calls `map2check_error()`,
which writes the result files and calls `abort()`
(`lib_old/Map2CheckFunctions.c:72-102`). The first violation is final.

**Reproduce:**

```c
map2check_init();
map2check_map_malloc((void *)0x1000, 16);
set_false_result(5 /* Reachability */, 1, "main");
map2check_check_load((void *)0x1000, 2, 0, 4, "main");
/* get_current_property() == None: the REACHABILITY violation is gone */
```

### SD-04 — End-of-program leak check is opt-in

**Classification:** intentional
**Tests:** `rust/src/ffi_tests.rs::check_mem_endprog_is_a_no_op_until_memcleanup_is_enabled`, `rust/src/ffi_tests.rs::set_memcleanup_enables_end_of_program_check`

**Rust:** `map2check_check_mem_endprog()` does nothing until
`map2check_set_memcleanup()` has been called. After that call, a dynamic
allocation that was never freed reports `MEMSAFETY_MEMCLEANUP`.

**Legacy (embedded C library):** `map2check_exit()` calls
`analysis_is_program_correct()` at the end of every run
(`lib_old/Map2CheckFunctions.c:89-102`). Whether a flag gated it was not
verified (#15).

**Reproduce:**

```c
map2check_init();
map2check_map_malloc((void *)0x1000, 16);
map2check_check_mem_endprog();   /* None */
map2check_set_memcleanup();
map2check_check_mem_endprog();   /* MemsafetyMemcleanup */
```

### SD-05 — NULL load is a violation unless NULL is declared valid

**Classification:** intentional
**Tests:** `rust/src/ffi_tests.rs::check_load_null_depends_on_null_is_valid`

**Rust:** `map2check_check_load(NULL, ...)` reports `MEMSAFETY_DEREF` unless
`map2check_set_null_is_valid()` was called first. After that call it is
safe.

**Legacy (embedded C library):** `map2check_load(ptr, size)` has no NULL
case and no flag (`lib_old/AnalysisModeMemtrack.c:156-162`).

**Reproduce:**

```c
map2check_init();
map2check_check_load(NULL, 12, 0, 4, "main");   /* MemsafetyDeref */
map2check_set_null_is_valid();
map2check_check_load(NULL, 12, 0, 4, "main");   /* None */
```

### SD-06 — Freeing an address with no record

**Classification:** suspected regression (#15)
**Tests:** `rust/src/ffi_tests.rs::check_free_rejects_double_free_and_untracked_address`, `rust/src/analysismode/memory.rs::free_resolved_checker_outcomes`

**Rust:** `map2check_check_free` reports `MEMSAFETY_FREE` for an address
with no record, but `map2check_check_free_resolved_address` treats that
address as safe.

**Legacy (embedded C library):** `is_invalid_free` returns true for an
address with no record (`lib_old/ListLog.c:95-118`), and both
`map2check_free` and `map2check_free_resolved_address` use it.

**Reproduce:**

```c
map2check_init();
map2check_check_free_resolved_address((void *)0x5000, 3, "main", 0);  /* None */
map2check_check_free("p", (void *)0x5000, 0, 4, "main");             /* MemsafetyFree */
```

### SD-07 — `__VERIFIER_assume(0)` ends the process

**Classification:** accepted limitation
**Tests:** `rust/src/nondet/libfuzzer.rs::verifier_assume_false_exits_with_zero`, `rust/src/nondet/libfuzzer.rs::map2check_fuzzer_assume_false_exits_with_zero`

**Rust:** `__VERIFIER_assume(0)` and `map2check_fuzzer_assume(0)` call
`exit(0)`. A Rust panic must not unwind across `extern "C"`, so there is no
safe way to return to `LLVMFuzzerTestOneInput`. The cost is that the
current fuzzing process ends. See “Accepted: `__VERIFIER_assume` /
`map2check_fuzzer_assume` end the process” in `api-deltas.md`.

**Legacy:** not verified against source (#15).

**Reproduce (link with `--features libfuzzer`):**

```c
__VERIFIER_assume(0);   /* process exits with status 0 */
```

### SD-08 — `__VERIFIER_error()` reports REACHABILITY, then aborts

**Classification:** intentional
**Tests:** `rust/src/nondet/libfuzzer.rs::verifier_error_aborts_and_reports_reachability`, `rust/src/nondet/libfuzzer.rs::verifier_assert_false_aborts_and_reports_reachability`

**Rust:** `__VERIFIER_error()` and `__VERIFIER_assert(0)` record
`REACHABILITY`, print the JSON report and call `abort()`. LibFuzzer treats
the abort as a crash.

**Legacy (embedded C library):** a violation ends in `abort()` through
`map2check_error()` (`lib_old/Map2CheckFunctions.c:72-102`).

**Reproduce (link with `--features libfuzzer`):**

```c
map2check_init();
__VERIFIER_error();   /* prints "REACHABILITY", then SIGABRT */
```

### SD-09 — Invalid arguments are ignored instead of causing undefined behaviour

**Classification:** intentional
**Tests:** `rust/src/ffi_tests.rs::map_alloca_ignores_negative_size`, `rust/src/ffi_tests.rs::map_malloc_ignores_negative_size`, `rust/src/ffi_tests.rs::map_calloc_ignores_negative_arguments`, `rust/src/ffi_tests.rs::set_false_result_ignores_unknown_property`, `rust/src/ffi_tests.rs::set_false_result_accepts_null_function_name`, `rust/src/ffi_tests.rs::check_load_rejects_negative_size`

**Rust:** the FFI layer never trusts its arguments. Negative sizes in the
`map2check_map_*` calls drop the record, and a `calloc` size that
overflows is dropped too. `set_false_result` ignores an unknown property
value. NULL or non-UTF-8 strings become `""`. A negative size in
`map2check_check_load` is a `MEMSAFETY_DEREF` violation. Panics are caught
at the boundary.

**Legacy (embedded C library):** no validation; for example,
`map2check_calloc` multiplies `quantity * size` without an overflow check
(`lib_old/AnalysisModeMemtrack.c:333-335`).

**Reproduce:**

```c
map2check_init();
map2check_map_malloc((void *)0x1000, -1);   /* no record */
set_false_result(99, 1, NULL);              /* ignored; result stays OK */
```

### SD-10 — Returned log records are not linked

**Classification:** intentional
**Tests:** `rust/src/ffi_tests.rs::legacy_records_are_returned_unlinked`

**Rust:** `map2check_save_nondet_log_*` and `map2check_save_basic_block_log`
return a pointer to a record that the library owns. Its `tqe_next` and
`tqe_prev` are always NULL. The pointer stays valid until the next
`map2check_reset()` or fuzzing iteration (SD-11). Callers must not free it
or walk the list.

**Legacy (C `map2check-library`):** records were `TAILQ` entries linked
into global lists.

**Reproduce:**

```c
map2check_init();
bbtrack_log_t *a = map2check_save_basic_block_log(1, "main");
bbtrack_log_t *b = map2check_save_basic_block_log(2, "main");
/* a->tqe_next == NULL && b->tqe_prev == NULL */
```

### SD-11 — Each LibFuzzer iteration starts from an empty state

**Classification:** intentional
**Tests:** `rust/src/nondet/libfuzzer.rs::fuzzer_iteration_resets_analysis_state_and_input`

**Rust:** `LLVMFuzzerTestOneInput` resets the analysis state before it calls
`__map2check_main__`. Records and results from one input never leak into
the next.

**Legacy:** not verified against source (#15).

**Reproduce:** run any LibFuzzer target linked with `--features libfuzzer`
for two inputs; the second report has no records from the first.

### SD-12 — A variable-length array counts as a leak at end of program

**Classification:** suspected regression (#15)
**Tests:** `rust/src/ffi_tests.rs::map_non_static_alloca_records_dynamic_slot`, `rust/src/ffi_tests.rs::non_static_alloca_is_reported_as_leak_at_end_of_program`

**Rust:** `map2check_map_non_static_alloca` marks its record dynamic, as
the reconstructed semantics in `api-deltas.md` describe. With
`map2check_set_memcleanup()` on, a VLA that goes out of scope without a
matching free reports `MEMSAFETY_MEMCLEANUP`.

**Legacy (embedded C library):** `map2check_non_static_alloca` registers a
static slot of `size * size_of_primitive` bytes
(`lib_old/AnalysisModeMemtrack.c:366-377`), so a VLA never counts as a
leak.

**Reproduce:**

```c
map2check_init();
int n = 4; int vla[n];
map2check_map_non_static_alloca("vla", vla, sizeof(vla), sizeof(int), 3, 0);
map2check_set_memcleanup();
map2check_check_mem_endprog();   /* MemsafetyMemcleanup */
```
````

As referências ao legado foram lidas do código:
- `lib_old/Map2CheckFunctions.c:72-102`: `map2check_error` chama `map2check_exit`, que chama `abort()`.
- `lib_old/ListLog.c:95-118`: `is_invalid_free` devolve `TRUE` para endereço não encontrado.
- `lib_old/AnalysisModeMemtrack.c`: `map2check_load` em 156-162, `map2check_free_resolved_address` em 164-183, `map2check_calloc` em 333-335 e `map2check_non_static_alloca`/`map2check_alloca` em 366-377.

Para conferir: `git show origin/refactory_memory_log:lib_old/<arquivo>`.

- [ ] **Step 5: Rodar e ver passar**

Run: `cargo test --all-features --test compat_docs && cargo test --all-features --lib ffi::tests`
Expected: PASS. `compat_docs` com `8 passed` e `ffi::tests` incluindo os 2 testes novos.

- [ ] **Step 6: Conferir que o teste pega deriva**

Renomeie temporariamente em `docs/semantic-deltas.md` a referência `check_load_clears_a_previous_violation_when_safe` para `check_load_clears_a_previous_violation` e rode `cargo test --all-features --test compat_docs`. Expected: FAIL com ``SD-03: `rust/src/ffi_tests.rs` não tem `fn check_load_clears_a_previous_violation(` ``. Desfaça.

- [ ] **Step 7: Lint e commit**

```bash
cargo fmt
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
git add docs/semantic-deltas.md rust/src/ffi_tests.rs tests/compat_docs.rs
git commit -m "docs: add reproducible semantic deltas against the legacy C code (#5)

Twelve SD entries, each with a C snippet, a classification and the Rust
tests that pin today's behaviour. SD-03, SD-06 and SD-12 are recorded as
suspected regressions for adjudication in #15; no production code changes."
```

---

### Task 6: Empacotamento de release, documento de release, CI e README

**Files:**
- Create: `scripts/package-release.sh`, `scripts/test-package-release.sh`, `docs/release.md`
- Modify: `.github/workflows/CI.yml` (step novo antes de "Checar segurança de dependências (cargo-deny)")
- Modify: `.gitignore` (fim do arquivo)
- Modify: `README.md` (seção `## Output JSON` até antes de `## Map2Check flow com a biblioteca`)

**Interfaces:**
- Consumes: `CHANGELOG.md` (Task 4); `docs/integration-guide.md`, `docs/api-deltas.md`, `docs/semantic-deltas.md` (Tasks 2, 3 e 5); `test/codeAPI_by_caller_test.c` (existente); `MAP2CHECK_VERSION` no header (`build.rs`).
- Produces: `dist/map2check-library-<versão>-<alvo>.tar.gz` + `dist/SHA256SUMS`; a variável `CHANGELOG_FILE` (override usado só pelo teste).

- [ ] **Step 1: Escrever o teste do script**

Crie `scripts/test-package-release.sh`:

````bash
#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Teste de scripts/package-release.sh (issue #5). Requer cargo, clang e nm.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/scripts/package-release.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0
ok() { echo "ok - $1"; }
bad() { echo "FAIL - $1"; fail=1; }

VERSION="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT/Cargo.toml" | head -n1)"
NAME="map2check-library-$VERSION-$(rustc -vV | sed -n 's/^host: //p')"

# CHANGELOG sem a versão atual: falha antes de compilar, citando a versão
printf '# Changelog\n\n## [0.0.0] - 2000-01-01\n' > "$TMP/CHANGELOG.md"
rc=0; out="$(CHANGELOG_FILE="$TMP/CHANGELOG.md" "$PKG" "$TMP/bad" 2>&1)" || rc=$?
if [ "$rc" -ne 0 ] && grep -qF "## [$VERSION]" <<<"$out"; then ok "recusa CHANGELOG sem a versão"; else bad "CHANGELOG sem a versão (rc=$rc out=$out)"; fi
if [ -z "$(ls -A "$TMP/bad" 2>/dev/null)" ]; then ok "nada gravado quando recusa"; else bad "gravou arquivos ao recusar"; fi

# Pacote real
"$PKG" "$TMP/dist" >/dev/null
if [ -f "$TMP/dist/$NAME.tar.gz" ]; then ok "nome do arquivo"; else bad "arquivo $NAME.tar.gz ausente: $(ls "$TMP/dist")"; fi
if (cd "$TMP/dist" && sha256sum -c --quiet SHA256SUMS); then ok "SHA256SUMS confere"; else bad "SHA256SUMS"; fi

expected="$(printf '%s\n' \
  "$NAME/" "$NAME/CHANGELOG.md" "$NAME/LICENSE" \
  "$NAME/docs/" "$NAME/docs/api-deltas.md" "$NAME/docs/integration-guide.md" "$NAME/docs/semantic-deltas.md" \
  "$NAME/include/" "$NAME/include/map2check.h" \
  "$NAME/lib/" "$NAME/lib/libmap2check.a" "$NAME/lib/libmap2check_libfuzzer.a" | LC_ALL=C sort)"
actual="$(tar -tzf "$TMP/dist/$NAME.tar.gz" | LC_ALL=C sort)"
if [ "$actual" = "$expected" ]; then ok "conteúdo exato"; else bad "conteúdo: $(diff <(echo "$expected") <(echo "$actual") || true)"; fi

mkdir -p "$TMP/x" && tar -xzf "$TMP/dist/$NAME.tar.gz" -C "$TMP/x"
P="$TMP/x/$NAME"
if grep -qxF "#define MAP2CHECK_VERSION \"$VERSION\"" "$P/include/map2check.h"; then ok "versão no header"; else bad "versão no header"; fi

# Biblioteca sem features: sem LLVMFuzzerTestOneInput; a de libfuzzer o define.
# A saída do nm vai para variáveis: `nm | grep -q` com pipefail falha por SIGPIPE.
core_syms="$(nm -g --defined-only "$P/lib/libmap2check.a" 2>/dev/null)"
fuzz_syms="$(nm -g --defined-only "$P/lib/libmap2check_libfuzzer.a" 2>/dev/null)"
if grep -q ' T map2check_init$' <<<"$core_syms" && ! grep -q ' T LLVMFuzzerTestOneInput$' <<<"$core_syms"; then ok "core sem LLVMFuzzerTestOneInput"; else bad "core: símbolos inesperados"; fi
if grep -q ' T LLVMFuzzerTestOneInput$' <<<"$fuzz_syms"; then ok "libfuzzer define LLVMFuzzerTestOneInput"; else bad "libfuzzer sem LLVMFuzzerTestOneInput"; fi

# Um programa C comum linka e roda só com o conteúdo do pacote
mkdir -p "$TMP/c/include" && cp "$P/include/map2check.h" "$TMP/c/include/"
sed 's|"../include/map2check.h"|"map2check.h"|' "$ROOT/test/codeAPI_by_caller_test.c" > "$TMP/c/main.c"
if clang -I "$TMP/c/include" "$TMP/c/main.c" "$P/lib/libmap2check.a" -ldl -lpthread -lm -o "$TMP/c/app" \
   && "$TMP/c/app" >/dev/null; then ok "programa C linka e roda com o pacote"; else bad "programa C com o pacote"; fi

exit "$fail"
````

```bash
chmod +x scripts/test-package-release.sh
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `scripts/test-package-release.sh`
Expected: FAIL. O primeiro caso imprime `FAIL - CHANGELOG sem a versão (rc=127 ...` (o script não existe), porque `scripts/package-release.sh` não existe, e o `set -e` interrompe na chamada do pacote real.

- [ ] **Step 3: Escrever o script de pacote**

Crie `scripts/package-release.sh`:

````bash
#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Monta o arquivo de release (issue #5): header C, as duas bibliotecas
# estáticas, guia de integração, docs de compatibilidade, CHANGELOG e LICENSE.
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
````

```bash
chmod +x scripts/package-release.sh
printf '\n# Arquivos de release (scripts/package-release.sh)\ndist/\n' >> .gitignore
```

- [ ] **Step 4: Rodar e ver passar**

Run: `scripts/test-package-release.sh`
Expected: 9 linhas `ok - ...` e exit 0:
```
ok - recusa CHANGELOG sem a versão
ok - nada gravado quando recusa
ok - nome do arquivo
ok - SHA256SUMS confere
ok - conteúdo exato
ok - versão no header
ok - core sem LLVMFuzzerTestOneInput
ok - libfuzzer define LLVMFuzzerTestOneInput
ok - programa C linka e roda com o pacote
```
Leva alguns minutos: são duas builds release com LTO.

- [ ] **Step 5: Escrever `docs/release.md`**

````markdown
# Release process

A release publishes one archive per target with the generated C header,
two static libraries, the integration guide and the compatibility docs.
`scripts/package-release.sh` builds it, and CI runs the same script on
every push through `scripts/test-package-release.sh`.

## Archive layout

`dist/map2check-library-<version>-<target>.tar.gz`, where `<version>` comes
from `Cargo.toml` and `<target>` is the `rustc` host triple (for example
`x86_64-unknown-linux-gnu`):

| Path in the archive | Source |
|---|---|
| `include/map2check.h` | Generated by `build.rs`; `MAP2CHECK_VERSION` must equal `<version>`. |
| `lib/libmap2check.a` | `cargo build --release` (no features), for plain C programs. |
| `lib/libmap2check_libfuzzer.a` | `cargo build --release --features libfuzzer`, for LibFuzzer targets; the program must define `int __map2check_main__(void)`. |
| `docs/integration-guide.md`, `docs/api-deltas.md`, `docs/semantic-deltas.md` | Repository. |
| `CHANGELOG.md`, `LICENSE` | Repository. |

`dist/SHA256SUMS` sits next to the archive. There are two libraries
because the `libfuzzer` build references `__map2check_main__`. Without
that symbol in the program, linking the `libfuzzer` library fails with
`undefined reference to '__map2check_main__'`.

## Steps

1. **Version.** On a branch off `feature/rust`, set `version` in
   `Cargo.toml` and the `org.opencontainers.image.version` label in
   `Dockerfile`. `tests/header_version.rs` fails if they disagree.
2. **Changelog.** Move the `[Unreleased]` entries into a new
   `## [<version>] - YYYY-MM-DD` section of `CHANGELOG.md`, and leave an
   empty `[Unreleased]` above it.
3. **Compatibility docs.** Make sure `docs/api-deltas.md` and
   `docs/semantic-deltas.md` reflect every ABI or behaviour change since
   the last release. `cargo test --all-features --test compat_docs` must
   pass.
4. **Pull request.** Open a PR to `feature/rust` (or `master` after the
   promotion) and merge it once `build_and_test` is green.
5. **Package.** On the merged commit, run:

   ```sh
   scripts/package-release.sh            # writes dist/
   (cd dist && sha256sum -c SHA256SUMS)
   ```

6. **Tag.** Create a signed tag on the merged commit and push it:

   ```sh
   git tag -s v<version> -m "map2check-library v<version>"
   git push origin v<version>
   ```

7. **GitHub release.** Attach the archive and checksums. Use
   `--prerelease` for `-rcN` versions:

   ```sh
   gh release create v<version> dist/*.tar.gz dist/SHA256SUMS \
     --title "v<version>" --notes-file <(sed -n '/^## \[<version>\]/,/^## \[/p' CHANGELOG.md | sed '$d') \
     --prerelease
   ```

Steps 6 and 7 publish outside the repository; the maintainer runs them.
````

- [ ] **Step 6: Adicionar o step no CI**

Em `.github/workflows/CI.yml`, logo antes de `      - name: Checar segurança de dependências (cargo-deny)`, insira:

```yaml
      - name: Testar empacotamento de release (header, bibliotecas e docs)
        run: scripts/test-package-release.sh

```

O runner `ubuntu-latest` já tem `clang` (instalado no início do job), GNU tar, `sha256sum` e `nm` (binutils).

- [ ] **Step 7: Atualizar o `README.md`**

Substitua tudo, desde a linha `## Output JSON` até a linha anterior a `## Map2Check flow com a biblioteca` (o parágrafo, o bloco ```json desatualizado e a frase sobre `Container_AllocationLog`), por:

````markdown
## Output JSON

Ao final da análise, `print_all_containers_as_json()` emite no stdout um objeto `map2check_log` com o veredito (`result`: `"TRUE"`/`"FALSE"`), a propriedade violada e os containers `Container_TrackBBLog`, `Container_NonDetLog` e, só em violações de memória, `Container_AllocationLog`. O formato exato, com exemplos verificados contra o serializador, está em [`docs/integration-guide.md`](docs/integration-guide.md#json-report).

## Compatibilidade e releases

- [`docs/api-deltas.md`](docs/api-deltas.md): matriz de símbolos e assinaturas da API C (núcleo e passes do Map2Check) em relação ao C legado.
- [`docs/semantic-deltas.md`](docs/semantic-deltas.md): diferenças de comportamento, cada uma com caso reproduzível e teste.
- [`docs/integration-guide.md`](docs/integration-guide.md): como linkar `libmap2check.a`, ordem de chamadas e formato do relatório JSON.
- [`docs/release.md`](docs/release.md) e [`CHANGELOG.md`](CHANGELOG.md): processo de release e histórico de versões.

`tests/compat_docs.rs` falha em três casos: quando um export do header não está na matriz (ou está com a declaração errada), quando um `SD-NN` aponta para um teste que não existe e quando os exemplos JSON do guia divergem da saída real. Toda mudança na ABI C ou no relatório JSON atualiza esses documentos no mesmo PR.

Para montar o pacote de release localmente:

```sh
scripts/package-release.sh   # dist/map2check-library-<versão>-<alvo>.tar.gz + SHA256SUMS
```

````

- [ ] **Step 8: Verificar guard da era C, lint e commit**

```bash
scripts/check-no-c-era-artifacts.sh
cargo fmt --check
git add scripts/package-release.sh scripts/test-package-release.sh docs/release.md .github/workflows/CI.yml .gitignore README.md
git commit -m "build: package release archive with header, libraries and docs (#5)

scripts/package-release.sh ships libmap2check.a (no features) and
libmap2check_libfuzzer.a: the libfuzzer build references
__map2check_main__ and does not link into a plain C program.
CI runs scripts/test-package-release.sh, which links a C program
against the unpacked archive. docs/release.md documents the steps;
README points to the compatibility docs instead of a stale JSON sample."
```

---

### Task 7: Verificação final, PR e issues de acompanhamento

**Files:** nenhum arquivo novo.

**Interfaces:**
- Consumes: tudo das Tasks 1–6.
- Produces: PR para `feature/rust`; opcionalmente, issues para SD-03, SD-06 e SD-12.

- [ ] **Step 1: Rodar a bateria completa do CI localmente**

```bash
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo build --release
cargo test --all-features
cargo test
scripts/test-branch-protection.sh
scripts/test-check-no-c-era-artifacts.sh
scripts/check-no-c-era-artifacts.sh
scripts/coverage.sh
scripts/test-package-release.sh
```

Expected: tudo com exit 0. `cargo test --all-features` mostra `compat_docs` com `8 passed`, `header_version` com `3 passed` e `ffi_exports_checklist` com `11 passed`. A cobertura não muda, porque nenhum código de produção mudou.

- [ ] **Step 2: Conferir o diff contra os Global Constraints**

Run: `git diff --stat origin/feature/rust...HEAD`
Expected: só `CHANGELOG.md`, `README.md`, `.gitignore`, `.github/workflows/CI.yml`, `docs/{api-deltas,semantic-deltas,integration-guide,release}.md`, o plano, `scripts/{package-release,test-package-release}.sh`, `tests/{common/mod.rs,compat_docs.rs,ffi_exports_checklist.rs,header_version.rs}` e `rust/src/ffi_tests.rs`. Nenhum outro arquivo de `rust/src/`.

- [ ] **Step 3: Pedir confirmação e abrir o PR**

Peça confirmação ao usuário antes de `git push` e `gh pr create`. O corpo do PR deve:
- listar os 4 critérios da issue e onde cada um foi atendido;
- dizer que #13, #14 e #21 continuam abertas e aparecem nos docs como `pending`/`pending decision`;
- apontar os três `suspected regression` (SD-03, SD-06, SD-12);
- conter `Closes #5`;
- não ter nenhuma linha de atribuição de IA (ver Global Constraints).

```bash
git push -u origin docs/issue-5-compat-release
gh pr create --base feature/rust --title "docs: compatibility matrix, semantic deltas and release packaging (#5)" --body-file <arquivo com o corpo>
```

O `Closes #5` foi decidido pelo mantenedor: a #5 fecha quando o PR for mesclado, e #13, #14 e #21 continuam abertas, cada uma responsável por atualizar os docs quando fechar.

- [ ] **Step 4: Propor as issues de acompanhamento (com confirmação)**

Pergunte ao usuário se deve abrir uma issue por `suspected regression`. Corpos sugeridos, um por issue:
- **SD-03** "memtrack: safe memory check clears an earlier violation (incl. REACHABILITY)": cenário C da entrada SD-03; legado `abort()` na 1ª violação (`lib_old/Map2CheckFunctions.c:72-102`); causa provável: `reset_result_metadata()` no início de `map2check_check_load`/`_free`/`_free_resolved_address`/`_deref`/`_mem_endprog` (`rust/src/ffi.rs`).
- **SD-06** "memtrack: check_free_resolved_address treats untracked address as safe": legado `is_invalid_free` → `TRUE` (`lib_old/ListLog.c:95-118`); causa: `is_invalid_free_resolved` usa `.unwrap_or(false)` (`rust/src/memtrack/mod.rs`).
- **SD-12** "memtrack: VLA from map2check_map_non_static_alloca reported as memcleanup leak": legado registra slot estático de `size * size_of_primitive` (`lib_old/AnalysisModeMemtrack.c:366-377`); causa: `entry.set_malloc()` em `map2check_map_non_static_alloca` (`rust/src/ffi.rs`).

Se as issues forem criadas, troque `(#15)` pelo número novo na linha **Classification** da entrada correspondente, rode `cargo test --all-features --test compat_docs` e faça commit (`docs: link suspected regressions to their issues (#5)`).
