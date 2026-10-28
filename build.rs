use std::env;
use std::path::Path;

fn main() {
    // Pega o diretório raiz do projeto
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();

    // Garante que o diretório include/ existe
    let include_dir = Path::new(&crate_dir).join("include");
    std::fs::create_dir_all(&include_dir).expect("Falha ao criar o diretório include/");

    // Tenta ler as configurações do cbindgen.toml, se existir
    let mut config = cbindgen::Config::from_file("cbindgen.toml").unwrap_or_default();

    // Expõe a versão do crate no header (issue #28); a fonte única é o Cargo.toml
    let version = env::var("CARGO_PKG_VERSION").unwrap();
    config.after_includes = Some(format!("\n#define MAP2CHECK_VERSION \"{version}\""));

    // Gera o header e salva na pasta include/
    let header_path = include_dir.join("map2check.h");
    cbindgen::Builder::new()
        .with_crate(&crate_dir)
        .with_config(config)
        .generate()
        .expect("Falha ao gerar o header C")
        .write_to_file(&header_path);

    let mut header = std::fs::read_to_string(&header_path).expect("Falha ao ler o header C gerado");
    // cbindgen 0.28 writes two spaces after the closing `#endif`; 0.26 wrote
    // one. Keep the header byte-identical across the bump.
    header = header.replace(
        "#endif  /* __MAP2CHECK_H_INCLUDED__ */",
        "#endif /* __MAP2CHECK_H_INCLUDED__ */",
    );
    std::fs::write(header_path, header).expect("Falha ao adicionar declarações ABI ao header C");

    // Roda este script novamente só se o código Rust, o cbindgen.toml ou o
    // Cargo.toml (versão) mudarem
    println!("cargo:rerun-if-changed=rust/src/");
    println!("cargo:rerun-if-changed=cbindgen.toml");
    println!("cargo:rerun-if-changed=Cargo.toml");
}
