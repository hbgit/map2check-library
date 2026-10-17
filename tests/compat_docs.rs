// SPDX-License-Identifier: GPL-3.0-only
//! Os documentos de compatibilidade acompanham o código (issue #5):
//! `docs/api-deltas.md` tem uma linha por export do header com a declaração
//! exata, `docs/semantic-deltas.md` aponta para testes que existem e os
//! exemplos JSON de `docs/integration-guide.md` são a saída real.

mod common;

use std::collections::{BTreeMap, BTreeSet};
use std::path::Path;
use std::sync::Mutex;

use common::{header_declarations, normalize, read};

/// Serializa os testes deste binário que tocam o estado global da biblioteca.
static STATE_LOCK: Mutex<()> = Mutex::new(());

/// Com `--features libfuzzer`, a biblioteca referencia `__map2check_main__`
/// em `LLVMFuzzerTestOneInput`. O stub de `rust/src/nondet/libfuzzer.rs` só
/// existe em `#[cfg(test)]` da própria crate, não quando ela é dependência
/// deste teste; sem este stub o link falha quando o código morto é mantido
/// (`cargo tarpaulin`, que usa `-C link-dead-code`).
#[cfg(feature = "libfuzzer")]
#[no_mangle]
pub extern "C" fn __map2check_main__() -> i32 {
    0
}

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
        map2check_check_free(
            c"p".as_ptr(),
            0x10 as *const _,
            0x2000 as *const _,
            0,
            20,
            c"main".as_ptr(),
        );
    }
    assert_eq!(
        report(),
        guide_example(&guide, "memory"),
        "exemplo `memory`"
    );
    map2check_reset();
}

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
    "fixed",
    "C behaviour preserved on purpose",
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
                if matches!(*k, "suspected regression" | "pending decision" | "fixed")
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
