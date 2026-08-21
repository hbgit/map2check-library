use std::env;

fn main() {
    // Pega o diretório raiz do projeto
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();

    // Tenta ler as configurações do cbindgen.toml, se existir
    let config = cbindgen::Config::from_file("cbindgen.toml")
        .unwrap_or_default();

    // Gera o header e salva na pasta include/
    cbindgen::Builder::new()
        .with_crate(crate_dir)
        .with_config(config)
        .generate()
        .expect("Falha ao gerar o header C")
        .write_to_file("include/map2check.h");

    // Avisa ao compilador para rodar este script novamente APENAS se 
    // os arquivos Rust mudarem
    println!("cargo:rerun-if-changed=src/");
    println!("cargo:rerun-if-changed=cbindgen.toml");
}