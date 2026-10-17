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

    let compatibility_declarations = r#"
#ifndef __NONDETLOG_H_INCLUDED__
#define __NONDETLOG_H_INCLUDED__
enum var_type_t { INT_ID, UNIT_ID, LONG_ID, CHAR_ID, DOUBLE_ID, FLOAT_ID };

typedef struct _non_det_log {
  struct _non_det_log *tqe_next;
  struct _non_det_log **tqe_prev;
  long step;
  int line;
  int scope;
  int type_var;
  union {
    int *i;
    unsigned int *u;
    long *l;
    char *c;
    char str[20];
    float *f;
    double *d;
    void *p;
  } value;
  const char *function_name;
} non_det_log_t;
#endif

non_det_log_t *map2check_save_nondet_log_int(int line, int scope, enum var_type_t type_var, int *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_uint(int line, int scope, enum var_type_t type_var, unsigned int *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_long(int line, int scope, enum var_type_t type_var, long *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_char(int line, int scope, enum var_type_t type_var, char *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_float(int line, int scope, enum var_type_t type_var, float *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_double(int line, int scope, enum var_type_t type_var, double *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_unsigned(int line, int scope, int type_var, unsigned int *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_ulong(int line, int scope, int type_var, unsigned long *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_uchar(int line, int scope, int type_var, unsigned char *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_short(int line, int scope, int type_var, short *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_ushort(int line, int scope, int type_var, unsigned short *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_bool(int line, int scope, int type_var, int *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_size_t(int line, int scope, int type_var, size_t *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_loff_t(int line, int scope, int type_var, long long *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_sector_t(int line, int scope, int type_var, unsigned long *value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_pointer(int line, int scope, int type_var, void **value, const char *function_name);
non_det_log_t *map2check_save_nondet_log_pchar(int line, int scope, int type_var, char **value, const char *function_name);

void map2check_binop_add_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name);
void map2check_binop_sub_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name);
void map2check_binop_mul_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name);
void map2check_binop_div_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name);
void map2check_binop_add_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name);
void map2check_binop_sub_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name);
void map2check_binop_mul_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name);
void map2check_binop_div_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name);
void map2check_binop_shl_int(int32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name);
void map2check_binop_shr_int(int32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name);
void map2check_binop_shr_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name);
"#;

    let mut header = std::fs::read_to_string(&header_path).expect("Falha ao ler o header C gerado");
    let bbtrack_declaration = "typedef struct bbtrack_log_t {";
    assert!(
        header.contains(bbtrack_declaration),
        "O header gerado não contém a declaração bbtrack_log_t"
    );
    header = header.replace(
        bbtrack_declaration,
        "#ifndef __TRACKBBLOG_H_INCLUDED__\n#define __TRACKBBLOG_H_INCLUDED__\ntypedef struct bbtrack_log_t {",
    );
    let bbtrack_type_end = "} bbtrack_log_t;";
    assert!(
        header.contains(bbtrack_type_end),
        "O header gerado não contém o fim da declaração bbtrack_log_t"
    );
    header = header.replace(bbtrack_type_end, "} bbtrack_log_t;\n#endif");
    header = header.replace(
        "struct bbtrack_log_t *map2check_save_basic_block_log",
        "bbtrack_log_t *map2check_save_basic_block_log",
    );
    // cbindgen 0.28 writes two spaces after the closing `#endif`; 0.26 wrote
    // one. Keep the header byte-identical across the bump.
    header = header.replace(
        "#endif  /* __MAP2CHECK_H_INCLUDED__ */",
        "#endif /* __MAP2CHECK_H_INCLUDED__ */",
    );
    let include_guard_end = "#endif /* __MAP2CHECK_H_INCLUDED__ */";
    let Some(guard_index) = header.find(include_guard_end) else {
        panic!("O header gerado não contém o include guard esperado");
    };
    header.insert_str(guard_index, compatibility_declarations);
    std::fs::write(header_path, header).expect("Falha ao adicionar declarações ABI ao header C");

    // Roda este script novamente só se o código Rust, o cbindgen.toml ou o
    // Cargo.toml (versão) mudarem
    println!("cargo:rerun-if-changed=rust/src/");
    println!("cargo:rerun-if-changed=cbindgen.toml");
    println!("cargo:rerun-if-changed=Cargo.toml");
}
