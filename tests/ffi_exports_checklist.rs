// SPDX-License-Identifier: GPL-3.0-only
//! Toda função declarada em `include/map2check.h` precisa ser chamada por ao
//! menos um teste Rust (issue #29). Um export novo sem teste quebra este teste.

use std::collections::BTreeSet;
use std::fs;
use std::path::Path;

/// Arquivos de teste e o marcador a partir do qual o conteúdo é código de teste.
/// `None` = o arquivo inteiro é teste.
const TEST_SOURCES: &[(&str, Option<&str>)] = &[
    ("rust/src/ffi_tests.rs", None),
    ("rust/src/nondet/libfuzzer.rs", Some("\nmod tests {")),
];

fn read(rel: &str) -> String {
    let path = Path::new(env!("CARGO_MANIFEST_DIR")).join(rel);
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("falha ao ler {}: {e}", path.display()))
}

fn is_ident(c: char) -> bool {
    c.is_ascii_alphanumeric() || c == '_'
}

/// Nomes das funções declaradas no header gerado pelo cbindgen: linhas no
/// nível zero (sem indentação, fora de comentários e diretivas) com `(`.
fn header_functions(header: &str) -> BTreeSet<String> {
    header
        .lines()
        .filter(|l| l.starts_with(|c: char| c.is_ascii_alphabetic() || c == '_'))
        .filter_map(|l| l.split_once('(').map(|(before, _)| before))
        .filter_map(|before| {
            let name: String = before
                .chars()
                .rev()
                .take_while(|&c| is_ident(c))
                .collect::<Vec<_>>()
                .into_iter()
                .rev()
                .collect();
            (!name.is_empty()).then_some(name)
        })
        .collect()
}

/// Remove comentários de linha (`// ...`) para que citar um símbolo num
/// comentário não conte como teste.
fn strip_line_comments(src: &str) -> String {
    src.lines()
        .map(|l| l.split_once("//").map_or(l, |(code, _)| code))
        .collect::<Vec<_>>()
        .join("\n")
}

/// `true` se `name` aparece como identificador inteiro em `code`
/// (`map2check_check_free` não casa dentro de `map2check_check_free_resolved_address`).
fn mentions(code: &str, name: &str) -> bool {
    code.match_indices(name).any(|(at, _)| {
        let before = code[..at].chars().next_back();
        let after = code[at + name.len()..].chars().next();
        !before.is_some_and(is_ident) && !after.is_some_and(is_ident)
    })
}

fn missing_symbols(header: &str, test_code: &str) -> Vec<String> {
    header_functions(header)
        .into_iter()
        .filter(|name| !mentions(test_code, name))
        .collect()
}

fn test_code() -> String {
    TEST_SOURCES
        .iter()
        .map(|&(rel, marker)| {
            let src = read(rel);
            let code = match marker {
                None => src.as_str(),
                Some(m) => {
                    let at = src
                        .find(m)
                        .unwrap_or_else(|| panic!("{rel} não contém `{}`", m.trim()));
                    &src[at..]
                }
            };
            strip_line_comments(code)
        })
        .collect::<Vec<_>>()
        .join("\n")
}

#[test]
fn todo_export_do_header_tem_teste_rust() {
    let missing = missing_symbols(&read("include/map2check.h"), &test_code());
    assert!(
        missing.is_empty(),
        "exports sem teste Rust (adicione um teste em rust/src/ffi_tests.rs): {missing:?}"
    );
}

#[test]
fn header_real_e_lido_por_completo() {
    let names = header_functions(&read("include/map2check.h"));
    for sentinel in [
        "map2check_init",                 // void f(void);
        "set_false_result",               // declaração em várias linhas
        "get_current_property",           // retorno `enum ViolatedProperty`
        "map2check_save_basic_block_log", // retorno ponteiro
        "map2check_save_nondet_log_int",  // bloco legado do trailer
        "__VERIFIER_nondet_bool",         // export do feature libfuzzer
    ] {
        assert!(names.contains(sentinel), "parser não achou `{sentinel}`");
    }
}

#[test]
fn checklist_acusa_simbolo_sem_teste() {
    let header = "void foo(void);\nint32_t bar(int32_t x,\n             int32_t y);\n";
    assert_eq!(missing_symbols(header, "foo();"), vec!["bar".to_string()]);
}

#[test]
fn checklist_nao_aceita_prefixo_de_outro_simbolo() {
    let header = "void check_free(void);\nvoid check_free_resolved(void);\n";
    assert_eq!(
        missing_symbols(header, "check_free_resolved();"),
        vec!["check_free".to_string()]
    );
}

#[test]
fn checklist_ignora_mencao_em_comentario() {
    let header = "void foo(void);\n";
    let code = strip_line_comments("// foo() é testado no harness C\nlet x = 1;");
    assert_eq!(missing_symbols(header, &code), vec!["foo".to_string()]);
}

#[test]
fn checklist_ignora_comentarios_e_diretivas_do_header() {
    let header =
        "/**\n * Chama foo(x).\n */\n#define BAR(x) (x)\n  void indented(void);\nvoid foo(void);\n";
    assert_eq!(
        header_functions(header),
        BTreeSet::from(["foo".to_string()])
    );
}
