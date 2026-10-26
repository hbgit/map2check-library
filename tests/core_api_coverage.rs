// SPDX-License-Identifier: GPL-3.0-only
// Todo símbolo núcleo usado pelo mapeamento ABI C → núcleo precisa existir no
// staticlib do perfil `runtime` com as features do runtime (`libfuzzer,wasm`).
// Não há camada de compatibilidade (D5): nomes do runtime C que o núcleo não
// usa não podem aparecer no artefato.

/// Nomes do runtime C que o núcleo também exporta, com assinatura própria, sem
/// ser alvo de nenhuma linha do mapeamento: `map2check_check_deref` do núcleo é
/// `(ptr, scope, line, fn)`, e os `map2check_wasm_*` da feature `wasm` usam a
/// tabela própria do núcleo. Desde a Task 2.5 o mapeamento leva esses nomes C
/// ao IR `AnalysisModeMemtrack.ll` (`__m2c_rt_memtrack_*`); os exports
/// legados ficam até a Task 2.10.
const CORE_NAMES_SHARED_WITH_C: &[&str] = &[
    "map2check_check_deref",
    "map2check_wasm_malloc",
    "map2check_wasm_free",
    "map2check_wasm_check_access",
];

fn target_dir(root: &str) -> String {
    std::env::var("CARGO_TARGET_DIR").unwrap_or_else(|_| format!("{root}/target"))
}

fn defined_symbols() -> String {
    let root = env!("CARGO_MANIFEST_DIR");
    let status =
        std::process::Command::new(std::env::var("CARGO").unwrap_or_else(|_| "cargo".into()))
            .args([
                "build",
                "--profile",
                "runtime",
                "--features",
                "libfuzzer,wasm",
            ])
            .current_dir(root)
            .status()
            .expect("cargo build");
    assert!(status.success(), "cargo build --profile runtime falhou");
    let archive = format!("{}/runtime/libmap2check.a", target_dir(root));
    let nm = std::process::Command::new("nm")
        .args(["--defined-only", "-g", &archive])
        .output()
        .expect("nm");
    assert!(nm.status.success(), "nm {archive} falhou");
    String::from_utf8_lossy(&nm.stdout).into_owned()
}

fn mapping() -> Vec<(String, String)> {
    let root = env!("CARGO_MANIFEST_DIR");
    std::fs::read_to_string(format!("{root}/docs/cutover/abi-mapping.tsv"))
        .unwrap()
        .lines()
        .skip(1)
        .map(|l| {
            let mut c = l.split('\t');
            (c.next().unwrap().into(), c.next().unwrap().into())
        })
        .collect()
}

fn is_defined(defined: &str, sym: &str) -> bool {
    defined.lines().any(|d| d.ends_with(&format!(" T {sym}")))
}

#[test]
fn every_core_target_is_exported() {
    let defined = defined_symbols();
    let missing: Vec<_> = mapping()
        .iter()
        .flat_map(|(_, core)| core.split('+').map(str::to_owned).collect::<Vec<_>>())
        .filter(|c| c != "-" && c != "__map2check_main__" && !is_defined(&defined, c))
        .collect();
    assert!(missing.is_empty(), "alvos núcleo ausentes: {missing:?}");
}

#[test]
fn no_legacy_c_name_is_exported() {
    let defined = defined_symbols();
    let leaked: Vec<_> = mapping()
        .into_iter()
        .filter(|(c, core)| {
            !core.split('+').any(|x| x == c)
                && !CORE_NAMES_SHARED_WITH_C.contains(&c.as_str())
                && is_defined(&defined, c)
        })
        .map(|(c, _)| c)
        .collect();
    assert!(
        leaked.is_empty(),
        "nomes do runtime C exportados (D5 proíbe): {leaked:?}"
    );
}
