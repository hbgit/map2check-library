// SPDX-License-Identifier: GPL-3.0-only
//! Toda função declarada em `include/map2check.h` precisa ser chamada por ao
//! menos um teste Rust (issue #29). Um export novo sem teste quebra este teste.

mod common;

use std::collections::BTreeSet;
use std::fs;
use std::path::Path;

use common::read;

/// Arquivos de teste e o marcador a partir do qual o conteúdo é código de teste.
/// `None` = o arquivo inteiro é teste.
const TEST_SOURCES: &[(&str, Option<&str>)] = &[
    ("rust/src/ffi_tests.rs", None),
    ("rust/src/nondet/libfuzzer.rs", Some("\nmod tests {")),
];

fn is_ident(c: char) -> bool {
    c.is_ascii_alphanumeric() || c == '_'
}

/// Nomes das funções declaradas no header gerado pelo cbindgen
/// (parser compartilhado em `tests/common/mod.rs`).
fn header_functions(header: &str) -> BTreeSet<String> {
    common::header_declarations(header).into_keys().collect()
}

/// Remove comentários (`//`, `/* */`) e literais de string e de char, para
/// que citar um símbolo num comentário ou numa mensagem não conte como teste.
fn strip_non_code(src: &str) -> String {
    let chars: Vec<char> = src.chars().collect();
    let mut out = String::with_capacity(src.len());
    let mut i = 0;
    while i < chars.len() {
        let c = chars[i];
        let next = chars.get(i + 1).copied();
        let prev_is_ident = i > 0 && is_ident(chars[i - 1]);
        if c == '/' && next == Some('/') {
            while i < chars.len() && chars[i] != '\n' {
                i += 1;
            }
        } else if c == '/' && next == Some('*') {
            let mut depth = 0;
            while i < chars.len() {
                if chars[i] == '/' && chars.get(i + 1) == Some(&'*') {
                    depth += 1;
                    i += 2;
                } else if chars[i] == '*' && chars.get(i + 1) == Some(&'/') {
                    depth -= 1;
                    i += 2;
                    if depth == 0 {
                        break;
                    }
                } else {
                    i += 1;
                }
            }
            out.push(' ');
        } else if c == 'r' && !prev_is_ident && matches!(next, Some('#' | '"')) {
            // Raw string: r"..." ou r#"..."#.
            let hashes = chars[i + 1..].iter().take_while(|&&h| h == '#').count();
            if chars.get(i + 1 + hashes) != Some(&'"') {
                out.push(c);
                i += 1;
                continue;
            }
            let close: String = std::iter::once('"')
                .chain("#".repeat(hashes).chars())
                .collect();
            let rest: String = chars[i + 2 + hashes..].iter().collect();
            let len = rest.find(&close).map_or(rest.len(), |at| at + close.len());
            i += 2 + hashes + rest[..len].chars().count();
            out.push_str("\"\"");
        } else if c == '"' {
            i += 1;
            while i < chars.len() && chars[i] != '"' {
                i += if chars[i] == '\\' { 2 } else { 1 };
            }
            i += 1;
            out.push_str("\"\"");
        } else if c == '\'' && next == Some('\\') {
            // Char literal com escape: '\n', '\'', '\u{..}'.
            i += 2;
            while i < chars.len() && chars[i] != '\'' {
                i += 1;
            }
            i += 1;
            out.push_str("' '");
        } else if c == '\'' && chars.get(i + 2) == Some(&'\'') {
            i += 3;
            out.push_str("' '");
        } else {
            // Inclui o `'` de lifetimes (`'a`, `'static`).
            out.push(c);
            i += 1;
        }
    }
    out
}

/// `true` se `code` chama `name`: o identificador inteiro seguido de `(`
/// (`map2check_check_free` não casa dentro de `map2check_check_free_resolved_address`;
/// `use super::foo;` e `let f = foo;` não contam).
fn calls(code: &str, name: &str) -> bool {
    code.match_indices(name).any(|(at, _)| {
        let before = code[..at].chars().next_back();
        let after = code[at + name.len()..].trim_start();
        !before.is_some_and(is_ident) && after.starts_with('(')
    })
}

/// Identificador que começa em `text` (depois de espaços), ou "" se não houver.
fn leading_ident(text: &str) -> &str {
    let text = text.trim_start();
    let end = text.find(|c: char| !is_ident(c)).unwrap_or(text.len());
    &text[..end]
}

/// Exports declarados no código Rust: funções `#[no_mangle]` (exceto as de
/// `#[cfg(test)]`) e o primeiro argumento de cada invocação de uma macro
/// cujo corpo gera uma função `#[no_mangle]` (`nondet_ffi!`, `overflow_ffi_binop!`…).
fn source_exports(src: &str) -> BTreeSet<String> {
    let code = strip_non_code(src);
    let mut exports = BTreeSet::new();

    for (at, m) in code.match_indices("#[no_mangle]") {
        if code[..at].trim_end().ends_with("#[cfg(test)]") {
            continue;
        }
        let after = &code[at + m.len()..];
        let Some(fn_at) = after.find("fn ") else {
            continue;
        };
        // Dentro de `macro_rules!` o nome é `$fn_name`: não é identificador.
        let name = leading_ident(&after[fn_at + 3..]);
        if !name.is_empty() {
            exports.insert(name.to_string());
        }
    }

    let generators: Vec<&str> = code
        .match_indices("macro_rules!")
        .filter_map(|(at, m)| {
            let rest = &code[at + m.len()..];
            let body_end = rest.find("\n}").unwrap_or(rest.len());
            rest[..body_end]
                .contains("#[no_mangle]")
                .then(|| leading_ident(rest))
        })
        .collect();
    for generator in generators {
        let invocation = format!("{generator}!(");
        for (at, _) in code.match_indices(&invocation) {
            if code[..at].chars().next_back().is_some_and(is_ident) {
                continue;
            }
            let name = leading_ident(&code[at + invocation.len()..]);
            if !name.is_empty() {
                exports.insert(name.to_string());
            }
        }
    }
    exports
}

fn missing_symbols(header: &str, test_code: &str) -> Vec<String> {
    header_functions(header)
        .into_iter()
        .filter(|name| !calls(test_code, name))
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
            strip_non_code(code)
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
    let code = strip_non_code("// foo() é testado no harness C\nlet x = 1;");
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

#[test]
fn checklist_ignora_mencao_em_comentario_de_bloco_e_string() {
    let header = "void foo(void);\n";
    let code = strip_non_code("/* foo() */ assert!(ok, \"foo() falhou\"); let c = c\"foo()\";");
    assert_eq!(missing_symbols(header, &code), vec!["foo".to_string()]);
}

#[test]
fn checklist_exige_chamada_e_nao_so_o_nome() {
    let header = "void foo(void);\nvoid bar(void);\n";
    assert_eq!(
        missing_symbols(header, "use super::foo; let f = foo; bar ();"),
        vec!["foo".to_string()]
    );
}

#[test]
fn strip_preserva_codigo_com_char_literal_e_lifetime() {
    let code = strip_non_code("let q = '\"'; fn f<'a>(x: &'a str) { foo(); }");
    assert!(code.contains("foo()"), "código após '\"' sumiu: {code}");
}

#[test]
fn source_exports_acha_no_mangle_e_macros_geradoras() {
    let src = r#"
macro_rules! gen_ffi {
    ($fn_name:ident) => {
        #[no_mangle]
        pub extern "C" fn $fn_name() {}
    };
}

macro_rules! plain {
    ($x:ident) => {};
}

#[no_mangle]
pub unsafe extern "C" fn real_export() {}

// #[no_mangle] pub extern "C" fn commented_out() {}

#[cfg(test)]
#[no_mangle]
pub extern "C" fn test_only() -> i32 { 0 }

gen_ffi!(from_macro);
plain!(not_an_export);
"#;
    assert_eq!(
        source_exports(src),
        BTreeSet::from(["from_macro".to_string(), "real_export".to_string()])
    );
}

/// O runtime KLEE (`rust/src/nondet/klee.rs`, feature `klee` do
/// `klee/Cargo.toml`) fica fora do header (`cbindgen:ignore`): é ligado como
/// bitcode, não pelo header.
const KLEE_RUNTIME: &str = "rust/src/nondet/klee.rs";

#[test]
fn todo_export_do_codigo_esta_no_header() {
    let rust_src: String = rust_sources()
        .iter()
        .filter(|p| p.as_str() != KLEE_RUNTIME)
        .map(|p| read(p))
        .collect::<Vec<_>>()
        .join("\n");
    let in_source = source_exports(&rust_src);
    let in_header = header_functions(&read("include/map2check.h"));
    let not_in_header: Vec<_> = in_source.difference(&in_header).collect();
    let not_in_source: Vec<_> = in_header.difference(&in_source).collect();
    assert!(
        not_in_header.is_empty() && not_in_source.is_empty(),
        "exports fora do header: {not_in_header:?}; no header sem export no código: {not_in_source:?}"
    );
}

/// O runtime KLEE exporta os mesmos símbolos, com as mesmas assinaturas, que
/// o gerador libFuzzer declara no header, mais o `main` que o KLEE executa
/// (como `NonDetGeneratorKlee.c` de `develop`).
#[test]
fn exports_do_runtime_klee_sao_os_do_header_mais_main() {
    let klee = source_exports(&read(KLEE_RUNTIME));
    let header = common::header_declarations(&read("include/map2check.h"));
    let fora: Vec<_> = klee
        .iter()
        .filter(|name| name.as_str() != "main" && !header.contains_key(name.as_str()))
        .collect();
    assert!(fora.is_empty(), "exports KLEE fora do header: {fora:?}");
    for name in [
        "main",
        "__VERIFIER_nondet_int",
        "__VERIFIER_assume",
        "__VERIFIER_error",
    ] {
        assert!(klee.contains(name), "o runtime KLEE não exporta {name}");
    }
}

/// Arquivos `.rs` de `rust/src/`, relativos à raiz do crate.
fn rust_sources() -> Vec<String> {
    fn walk(dir: &Path, root: &Path, out: &mut Vec<String>) {
        for entry in fs::read_dir(dir).unwrap() {
            let path = entry.unwrap().path();
            if path.is_dir() {
                walk(&path, root, out);
            } else if path.extension().is_some_and(|e| e == "rs") {
                out.push(
                    path.strip_prefix(root)
                        .unwrap()
                        .to_string_lossy()
                        .into_owned(),
                );
            }
        }
    }
    let root = Path::new(env!("CARGO_MANIFEST_DIR"));
    let mut out = Vec::new();
    walk(&root.join("rust/src"), root, &mut out);
    out.sort();
    out
}
