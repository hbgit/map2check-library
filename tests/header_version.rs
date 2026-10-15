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
