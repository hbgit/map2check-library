// SPDX-License-Identifier: GPL-3.0-only
// O runtime ligado ao programa analisado precisa desenrolar panics através de
// catch_unwind (ffi_guard), e não abortar o processo: um abort sob AFL++
// persistente apareceria como crash do programa analisado (falso positivo).
// O build KLEE usa abort em separado, numa task posterior.
#[test]
fn runtime_profile_unwinds_on_panic() {
    let manifest =
        std::fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/Cargo.toml")).unwrap();
    let table = manifest.split("[profile.runtime]").nth(1).expect(
        "perfil runtime ausente: adicione [profile.runtime] com inherits = \"release\" e panic = \"unwind\" ao Cargo.toml",
    );
    let table = table.split("\n[").next().unwrap();
    assert!(
        table.contains("inherits = \"release\""),
        "[profile.runtime] deve herdar de release: {table}"
    );
    assert!(
        table.contains("panic = \"unwind\""),
        "[profile.runtime] deve declarar panic = \"unwind\" (ffi_guard depende de catch_unwind): {table}"
    );
}
