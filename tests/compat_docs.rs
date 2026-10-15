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
