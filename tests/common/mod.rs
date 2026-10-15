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
