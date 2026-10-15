# Issue #29 — Testes unitários Rust por export FFI — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar a issue #29 (Audit-ID M3-E3): cada função declarada em `include/map2check.h` tem ao menos um teste Rust que a chama e verifica o efeito no estado, e um teste-checklist falha quando um export novo entra sem teste.

**Architecture:** Os testes dos 44 exports de `rust/src/ffi.rs` ficam num arquivo próprio, `rust/src/ffi_tests.rs`, ligado como `#[cfg(test)] #[path = "ffi_tests.rs"] mod tests;` no fim de `ffi.rs` (unit test dentro do crate → acesso a `state::test_lock()`, `AnalysisState` e às structs legadas; o glob `rust/src/ffi*.rs` do `scripts/coverage.sh` já o exclui da cobertura). Os 18 exports do feature `libfuzzer` já têm testes em `rust/src/nondet/libfuzzer.rs`, menos os ramos que encerram o processo (`exit(0)`/`abort()`); esses ganham testes que re-executam o próprio binário de teste como processo filho. O checklist é um teste de integração (`tests/ffi_exports_checklist.rs`, mesmo estilo de `tests/header_version.rs`) que lê o header gerado, extrai os nomes das funções e exige que cada um apareça como identificador em código (não comentário) dos arquivos de teste.

**Tech Stack:** Rust 1.82 (`rust-toolchain.toml`, edition 2021, literais `c"..."`), cbindgen 0.26 (header gerado pelo `build.rs`), libtest, GitHub Actions.

**Spec:** Issue GitHub `hbgit/map2check-library#29` — "test: add Rust unit tests for each exported FFI symbol". Fonte: `docs/plano_map2check_library_rust.md` (M3 — Entregáveis: "testes unitários por símbolo") e `audit/relatorio_auditoria.md`.

## Verificação (estado em 2026-10-15, `origin/feature/rust` @ `86989e7`)

| Critério da issue | Estado |
|---|---|
| Para cada símbolo do header, ao menos um teste Rust que chama o export e verifica o efeito no estado | ❌ `include/map2check.h` declara **62** funções: 44 vêm de `rust/src/ffi.rs` (nenhum `mod tests` lá; zero testes Rust chamam esses exports) e 18 de `rust/src/nondet/libfuzzer.rs` (17 já chamados nos testes do módulo; `__VERIFIER_error` não; `__VERIFIER_assume`/`__VERIFIER_assert`/`map2check_fuzzer_assume` só no ramo que não encerra o processo) |
| Checklist (script ou teste) que falha quando um export novo não tem teste | ❌ não existe |
| Dependência M2 (`map2check_reset`) | ✅ `map2check_reset` existe (`ffi.rs:120`) e `state::test_lock()` (`state.rs`) serializa os testes que tocam o estado global |

Observações:
- A issue fala em "46 exports"; a contagem real no header gerado com `cargo build --all-features` é 62 (o cbindgen ignora `cfg(feature)` e sempre emite os símbolos de `libfuzzer.rs`). O checklist usa o header como fonte, então a contagem exata não importa.
- O header é gerado pelo `build.rs` a cada build e está no `.gitignore`; em `cargo test` ele já existe quando os testes rodam.
- Todos os testes deste plano foram prototipados numa worktree descartável sobre `86989e7`: `cargo test --all-features` → 142 unit + 6 checklist + 2 header_version verdes; `cargo clippy --all-targets --all-features -- -D warnings` limpo; `cargo test` (sem features) verde. Remover a chamada a `map2check_is_in_trackbb_container` de `ffi_tests.rs` faz o checklist falhar com `["map2check_is_in_trackbb_container"]`.
- São testes de caracterização de código existente: no protótipo todos passaram de primeira. Se algum falhar na execução, **não mude `ffi.rs` nem os checkers** — pare e reporte (é bug real, fora do escopo desta issue; abra issue separada).

## Global Constraints

- Branch base: `feature/rust` (protegida; exige PR com `build_and_test` verde — issue #26). Branch de trabalho: `test/issue-29-ffi-unit-tests`.
- Nenhuma mudança de comportamento em código de produção. Únicas alterações fora de arquivos de teste: as 4 linhas `mod tests` no fim de `rust/src/ffi.rs` e o comentário `NOTE` do `mod tests` de `libfuzzer.rs`.
- Arquivos novos começam com o cabeçalho SPDX `GPL-3.0-only`.
- Todo bloco `unsafe` nos testes leva comentário `// SAFETY:` (convenção do `ffi.rs`).
- Todo teste que toca o estado global segura `state::test_lock()` (via `fresh()` em `ffi_tests.rs`); `cargo test` roda testes em threads paralelas.
- Endereços nos testes são falsos (`addr(0x1000)`): a biblioteca só armazena e compara endereços, nunca os desreferencia.
- CI precisa continuar verde: `cargo fmt --check`, `cargo clippy --all-targets --all-features -- -D warnings`, `cargo test --all-features`, cobertura (`scripts/coverage.sh`, gate 80% fora de `ffi*.rs`), harness FFI.
- Commits terminam com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; corpo do PR termina com `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
- Push, abertura de PR e fechamento de issue são ações externas: pedir confirmação ao usuário antes.

## Review Focus

1. Símbolo que é prefixo de outro (`map2check_check_free` × `map2check_check_free_resolved_address`) → testar só o mais longo não pode satisfazer o checklist para o mais curto. → `checklist_nao_aceita_prefixo_de_outro_simbolo` (Task 7).
2. Símbolo citado só num comentário (ex.: o `NOTE` antigo de `libfuzzer.rs` citava `__VERIFIER_error()`) → não conta como teste. → `checklist_ignora_mencao_em_comentario` (Task 7).
3. Parser do header perdendo declarações com outro formato (várias linhas, retorno ponteiro, retorno `enum`, bloco legado do trailer) → o checklist passaria vazio. → `header_real_e_lido_por_completo` com sentinelas (Task 7).
4. Teste de processo filho com filtro errado (nome do teste mudou) → o filho roda zero testes, sai com 0 e o pai "passa" o `exit(0)`. → marcador `STARTED` obrigatório + ausência de `test result:` (Task 6).
5. Estado global contaminado entre testes paralelos, e checagens de memória que zeram uma violação anterior quando o acesso é seguro (`reset_result_metadata`) → `fresh()` em todo teste; `check_load_clears_a_previous_violation_when_safe` fixa o comportamento atual (Task 5). Também: `c_char` é `u8` em aarch64 → o teste de `char` usa 65, válido nos dois.

---

### Task 1: Ligar `ffi_tests.rs` e testar inicialização e gestão de resultado

**Files:**
- Create: `rust/src/ffi_tests.rs`
- Modify: `rust/src/ffi.rs` (fim do arquivo, após `map2check_check_mem_endprog`, linha ~1043)

**Interfaces:**
- Consumes: `state::test_lock()`, `state::reset()`, `state::with_state()`, `AnalysisState` (`rust/src/state.rs`); todos os exports de `ffi.rs` via `use super::*;`.
- Produces (usados pelas Tasks 2–5, mesmo arquivo): `fn fresh() -> MutexGuard<'static, ()>`, `fn snapshot<R>(f: impl FnOnce(&AnalysisState) -> R) -> R`, `fn addr(a: usize) -> *const c_void`, `fn assert_ok()`, `fn assert_violated(property: ViolatedProperty, line: u32, function_name: &str)`.
- Símbolos cobertos: `map2check_init`, `map2check_reset`, `map2check_success`, `set_false_result`, `get_current_property`, `get_current_step`, `get_next_step`, `print_all_containers_as_json`, `vcc_reset_meta_data`, `map2check_set_memcleanup`, `map2check_set_null_is_valid`.

- [ ] **Step 1: Criar a branch de trabalho**

```bash
git fetch origin
git switch -c test/issue-29-ffi-unit-tests origin/feature/rust
```

- [ ] **Step 2: Ligar o módulo de testes no fim de `rust/src/ffi.rs`**

Acrescentar, depois do `}` final de `map2check_check_mem_endprog`:

```rust

#[cfg(test)]
#[path = "ffi_tests.rs"]
mod tests;
```

(O `#[path]` é relativo ao diretório de `ffi.rs`, ou seja, `rust/src/ffi_tests.rs`.)

- [ ] **Step 3: Criar `rust/src/ffi_tests.rs` com helpers e os testes desta task**

```rust
// SPDX-License-Identifier: GPL-3.0-only
//
// Unit tests for every `extern "C"` export of `ffi.rs` (issue #29).
// Each test calls the export the way the C side would and checks its effect
// on the global `AnalysisState`. `tests/ffi_exports_checklist.rs` fails when
// a symbol of `include/map2check.h` is not called from this file.

use super::*;
use crate::state::{self, AnalysisState};
use std::os::raw::c_void;
use std::sync::MutexGuard;

/// Takes the global test lock and starts from an empty analysis state.
fn fresh() -> MutexGuard<'static, ()> {
    let guard = state::test_lock();
    state::reset();
    guard
}

/// Reads a value out of the global state.
fn snapshot<R>(f: impl FnOnce(&AnalysisState) -> R) -> R {
    state::with_state(|s| Ok(f(s))).unwrap()
}

/// A fake address: the library only stores and compares addresses, it never
/// dereferences them.
fn addr(a: usize) -> *const c_void {
    a as *const c_void
}

fn assert_ok() {
    let (ok, property) = snapshot(|s| (s.result.ok, s.result.property));
    assert!(ok, "esperava resultado ok, veio {property:?}");
    assert_eq!(property, ViolatedProperty::None);
}

fn assert_violated(property: ViolatedProperty, line: u32, function_name: &str) {
    let result = snapshot(|s| s.result.clone());
    assert!(!result.ok, "esperava violação {property:?}");
    assert_eq!(result.property, property);
    assert_eq!(result.line, line);
    assert_eq!(result.function_name, function_name);
}

// ── Initialisation ──────────────────────────────────────────────────────────

#[test]
fn init_leaves_state_empty_and_ok() {
    let _guard = fresh();
    map2check_init();
    assert_ok();
    assert_eq!(snapshot(|s| s.current_step()), 0);
    assert!(snapshot(|s| s.memtrack.is_empty()
        && s.nondets.is_empty()
        && s.bbtrack.is_empty()));
}

#[test]
fn reset_clears_records_result_step_and_flags() {
    let _guard = fresh();
    // SAFETY: null pointer is a valid malloc result.
    unsafe { map2check_map_malloc(addr(0x1000), 16) };
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(5, 7, c"main".as_ptr()) };
    map2check_set_memcleanup();
    map2check_set_null_is_valid();

    map2check_reset();

    assert_ok();
    snapshot(|s| {
        assert_eq!(s.current_step(), 0);
        assert!(s.memtrack.is_empty());
        assert!(!s.memcleanup_enabled);
        assert!(!s.null_is_valid);
    });
}

// ── Result management ───────────────────────────────────────────────────────

#[test]
fn success_does_not_change_state() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 16) };
    map2check_success();
    assert_ok();
    assert_eq!(snapshot(|s| s.memtrack.len()), 1);
}

#[test]
fn set_false_result_records_property_line_and_function() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(5, 42, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::Reachability, 42, "main");
}

#[test]
fn set_false_result_ignores_unknown_property() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(99, 42, c"main".as_ptr()) };
    assert_ok();
}

#[test]
fn set_false_result_accepts_null_function_name() {
    let _guard = fresh();
    // SAFETY: null is an accepted function_name.
    unsafe { set_false_result(0, 3, std::ptr::null()) };
    assert_violated(ViolatedProperty::Overflow, 3, "");
}

#[test]
fn get_current_property_reflects_last_violation() {
    let _guard = fresh();
    assert_eq!(get_current_property(), ViolatedProperty::None);
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(2, 1, c"f".as_ptr()) };
    assert_eq!(get_current_property(), ViolatedProperty::MemsafetyDeref);
}

#[test]
fn get_current_step_reads_without_advancing() {
    let _guard = fresh();
    assert_eq!(get_current_step(), 0);
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 8) };
    assert_eq!(get_current_step(), 1);
    assert_eq!(get_current_step(), 1);
}

#[test]
fn get_next_step_advances_the_counter() {
    let _guard = fresh();
    assert_eq!(get_next_step(), 1);
    assert_eq!(get_next_step(), 2);
    assert_eq!(snapshot(|s| s.current_step()), 2);
}

#[test]
fn print_all_containers_as_json_does_not_change_state() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_save_basic_block_log(3, c"main".as_ptr()) };
    print_all_containers_as_json();
    assert_ok();
    assert_eq!(snapshot(|s| s.bbtrack.len()), 1);
}

#[test]
fn vcc_reset_meta_data_clears_result_but_keeps_records() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 8) };
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(1, 9, c"main".as_ptr()) };

    vcc_reset_meta_data();

    let result = snapshot(|s| s.result.clone());
    assert!(result.ok);
    assert_eq!(result.property, ViolatedProperty::None);
    assert_eq!(result.line, 0);
    assert!(result.function_name.is_empty());
    assert_eq!(result.step, 1, "o contador de passos não é zerado");
    assert_eq!(snapshot(|s| s.memtrack.len()), 1);
}

#[test]
fn set_memcleanup_enables_end_of_program_check() {
    let _guard = fresh();
    assert!(!snapshot(|s| s.memcleanup_enabled));
    map2check_set_memcleanup();
    assert!(snapshot(|s| s.memcleanup_enabled));
}

#[test]
fn set_null_is_valid_sets_the_flag() {
    let _guard = fresh();
    assert!(!snapshot(|s| s.null_is_valid));
    map2check_set_null_is_valid();
    assert!(snapshot(|s| s.null_is_valid));
}
```

- [ ] **Step 4: Rodar os testes**

Run: `cargo test --all-features --lib ffi::tests`
Expected: PASS, `13 passed`. (São testes de caracterização; se algum falhar, ver "Observações" — não altere `ffi.rs`.)

- [ ] **Step 5: Lint e formato**

Run: `cargo fmt && cargo clippy --all-targets --all-features -- -D warnings`
Expected: sem warnings.

- [ ] **Step 6: Commit**

```bash
git add rust/src/ffi.rs rust/src/ffi_tests.rs
git commit -m "test: unit-test init and result-management FFI exports (#29)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Testar os exports de nondet e de basic block

**Files:**
- Modify: `rust/src/ffi_tests.rs` (acrescentar no fim)

**Interfaces:**
- Consumes: `fresh`, `snapshot` (Task 1); `non_det_log_t`, `bbtrack_log_t`, `NonDetValue` (via `use super::*;`).
- Produces: `fn assert_nondet(record: *mut non_det_log_t, expected: NonDetValue)` (local a esta seção).
- Símbolos cobertos: `map2check_save_nondet_log_{int,uint,long,char,float,double}`, `map2check_save_basic_block_log`, `map2check_is_in_trackbb_container`.

- [ ] **Step 1: Acrescentar os testes no fim de `rust/src/ffi_tests.rs`**

```rust
// ── NonDet tracking ─────────────────────────────────────────────────────────

/// Checks the single nondet record and the legacy C record returned for it.
fn assert_nondet(record: *mut non_det_log_t, expected: NonDetValue) {
    assert!(!record.is_null());
    // SAFETY: the record is owned by the global state, which no one resets
    // while the test lock is held.
    let legacy = unsafe { &*record };
    assert_eq!(legacy.step, 1);
    assert_eq!(legacy.line, 10);
    assert_eq!(legacy.scope, 2);
    snapshot(|s| {
        assert_eq!(s.nondets.len(), 1);
        let entry = &s.nondets[0];
        assert_eq!(entry.step, 1);
        assert_eq!(entry.line, 10);
        assert_eq!(entry.scope, 2);
        assert_eq!(entry.function_name, "f");
        assert_eq!(entry.value, expected);
        assert_eq!(s.legacy_nondet_logs.len(), 1);
    });
}

#[test]
fn save_nondet_log_int_records_value() {
    let _guard = fresh();
    let mut value: i32 = -7;
    // SAFETY: value and the C-string literal outlive the call.
    let record = unsafe { map2check_save_nondet_log_int(10, 2, 0, &mut value, c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::Int(-7));
}

#[test]
fn save_nondet_log_int_with_null_value_records_zero() {
    let _guard = fresh();
    // SAFETY: null value is accepted; the C-string literal outlives the call.
    let record =
        unsafe { map2check_save_nondet_log_int(10, 2, 0, std::ptr::null_mut(), c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::Int(0));
}

#[test]
fn save_nondet_log_uint_records_value() {
    let _guard = fresh();
    let mut value: u32 = u32::MAX;
    // SAFETY: value and the C-string literal outlive the call.
    let record = unsafe { map2check_save_nondet_log_uint(10, 2, 1, &mut value, c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::UInt(u32::MAX));
}

#[test]
fn save_nondet_log_long_records_value() {
    let _guard = fresh();
    let mut value: std::os::raw::c_long = -5;
    // SAFETY: value and the C-string literal outlive the call.
    let record = unsafe { map2check_save_nondet_log_long(10, 2, 2, &mut value, c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::Long(-5));
}

#[test]
fn save_nondet_log_char_records_value() {
    let _guard = fresh();
    // 65 ('A') fits both signed and unsigned `c_char` (aarch64 uses u8).
    let mut value: std::os::raw::c_char = 65;
    // SAFETY: value and the C-string literal outlive the call.
    let record = unsafe { map2check_save_nondet_log_char(10, 2, 3, &mut value, c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::Char(65));
}

#[test]
fn save_nondet_log_float_records_value() {
    let _guard = fresh();
    let mut value: f32 = 1.5;
    // SAFETY: value and the C-string literal outlive the call.
    let record = unsafe { map2check_save_nondet_log_float(10, 2, 4, &mut value, c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::Float(1.5));
}

#[test]
fn save_nondet_log_double_records_value() {
    let _guard = fresh();
    let mut value: f64 = -2.25;
    // SAFETY: value and the C-string literal outlive the call.
    let record = unsafe { map2check_save_nondet_log_double(10, 2, 5, &mut value, c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::Double(-2.25));
}

// ── Basic-block tracking ────────────────────────────────────────────────────

#[test]
fn save_basic_block_log_records_block() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    let record = unsafe { map2check_save_basic_block_log(7, c"main".as_ptr()) };
    assert!(!record.is_null());
    // SAFETY: the record is owned by the global state, kept alive under the lock.
    let legacy = unsafe { &*record };
    assert_eq!((legacy.step, legacy.line), (1, 7));
    snapshot(|s| {
        assert_eq!(s.bbtrack.len(), 1);
        assert_eq!(s.bbtrack[0].step, 1);
        assert_eq!(s.bbtrack[0].line, 7);
        assert_eq!(s.bbtrack[0].function_name, "main");
    });
}

#[test]
fn is_in_trackbb_container_reports_recorded_lines() {
    let _guard = fresh();
    assert_eq!(map2check_is_in_trackbb_container(7), 0);
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_save_basic_block_log(7, c"main".as_ptr()) };
    assert_eq!(map2check_is_in_trackbb_container(7), 1);
    assert_eq!(map2check_is_in_trackbb_container(8), 0);
}
```

- [ ] **Step 2: Rodar os testes**

Run: `cargo test --all-features --lib ffi::tests`
Expected: PASS, `22 passed`.

- [ ] **Step 3: Lint e formato**

Run: `cargo fmt && cargo clippy --all-targets --all-features -- -D warnings`
Expected: sem warnings.

- [ ] **Step 4: Commit**

```bash
git add rust/src/ffi_tests.rs
git commit -m "test: unit-test nondet and basic-block FFI exports (#29)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Testar os exports de rastreamento de memória

**Files:**
- Modify: `rust/src/ffi_tests.rs` (acrescentar no fim)

**Interfaces:**
- Consumes: `fresh`, `snapshot`, `addr` (Task 1); `crate::memtrack::MemTrackEntry` (campos públicos `step`, `line`, `scope`, `var_addr`, `points_to`, `is_dynamic`, `is_free`, `ptr_name`, `function_name`, `size_destiny`, `size_primitive`).
- Produces: `fn only_memtrack() -> crate::memtrack::MemTrackEntry`.
- Símbolos cobertos: `map2check_map_alloca`, `map2check_map_non_static_alloca`, `map2check_map_funct_address`, `map2check_map_malloc`, `map2check_map_calloc`, `map2check_map_free`, `map2check_map_store_pointer`.

- [ ] **Step 1: Acrescentar os testes no fim de `rust/src/ffi_tests.rs`**

```rust
// ── Memory tracking ─────────────────────────────────────────────────────────

/// Returns the only memtrack record, failing if there is not exactly one.
fn only_memtrack() -> crate::memtrack::MemTrackEntry {
    snapshot(|s| {
        assert_eq!(s.memtrack.len(), 1, "esperava exatamente um registro");
        s.memtrack[0].clone()
    })
}

#[test]
fn map_alloca_records_static_stack_slot() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_map_alloca(c"x".as_ptr(), addr(0x2000), 8, 4, 3, 1) };
    let e = only_memtrack();
    assert_eq!((e.step, e.line, e.scope), (1, 3, 1));
    assert_eq!((e.var_addr, e.points_to), (0x2000, 0x2000));
    assert_eq!((e.size_destiny, e.size_primitive), (8, 4));
    assert_eq!(e.ptr_name, "x");
    assert!(!e.is_dynamic && !e.is_free);
}

#[test]
fn map_alloca_ignores_negative_size() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_map_alloca(c"x".as_ptr(), addr(0x2000), -1, 4, 3, 1) };
    assert!(snapshot(|s| s.memtrack.is_empty()));
}

#[test]
fn map_non_static_alloca_records_dynamic_slot() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_map_non_static_alloca(c"vla".as_ptr(), addr(0x2000), 40, 4, 5, 2) };
    let e = only_memtrack();
    assert_eq!((e.line, e.scope, e.size_destiny), (5, 2, 40));
    assert_eq!(e.ptr_name, "vla");
    assert!(e.is_dynamic && !e.is_free);
}

#[test]
fn map_funct_address_records_pointer_sized_slot() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_map_funct_address(c"foo".as_ptr(), addr(0x4000)) };
    let e = only_memtrack();
    let width = std::mem::size_of::<*const c_void>();
    assert_eq!((e.var_addr, e.points_to), (0x4000, 0x4000));
    assert_eq!((e.size_destiny, e.size_primitive), (width, width));
    assert_eq!(e.ptr_name, "foo");
    assert!(!e.is_dynamic && !e.is_free);
}

#[test]
fn map_malloc_records_heap_allocation() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 16) };
    let e = only_memtrack();
    assert_eq!(
        (e.points_to, e.size_destiny, e.size_primitive),
        (0x1000, 16, 1)
    );
    assert!(e.is_dynamic && !e.is_free);
}

#[test]
fn map_malloc_ignores_negative_size() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), -16) };
    assert!(snapshot(|s| s.memtrack.is_empty()));
}

#[test]
fn map_calloc_records_quantity_times_size() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_calloc(addr(0x1000), 4, 8) };
    let e = only_memtrack();
    assert_eq!((e.points_to, e.size_destiny), (0x1000, 32));
    assert!(e.is_dynamic && !e.is_free);
}

#[test]
fn map_calloc_ignores_negative_arguments() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe {
        map2check_map_calloc(addr(0x1000), -1, 8);
        map2check_map_calloc(addr(0x1000), 4, -8);
    }
    assert!(snapshot(|s| s.memtrack.is_empty()));
}

#[test]
fn map_free_records_released_slot() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake address is never dereferenced.
    unsafe { map2check_map_free(c"p".as_ptr(), addr(0x1000), 1, 9, c"main".as_ptr()) };
    let e = only_memtrack();
    assert_eq!(
        (e.line, e.scope, e.var_addr, e.size_destiny),
        (9, 1, 0x1000, 0)
    );
    assert_eq!(
        (e.ptr_name.as_str(), e.function_name.as_str()),
        ("p", "main")
    );
    assert!(e.is_free && !e.is_dynamic);
}

#[test]
fn map_store_pointer_records_points_to() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_store_pointer(
            addr(0x3000),
            addr(0x1000),
            2,
            c"p".as_ptr(),
            11,
            c"main".as_ptr(),
        )
    };
    let e = only_memtrack();
    assert_eq!((e.var_addr, e.points_to), (0x3000, 0x1000));
    assert_eq!((e.line, e.scope, e.size_destiny), (11, 2, 0));
    assert_eq!(
        (e.ptr_name.as_str(), e.function_name.as_str()),
        ("p", "main")
    );
    assert!(!e.is_dynamic && !e.is_free);
}
```

- [ ] **Step 2: Rodar os testes**

Run: `cargo test --all-features --lib ffi::tests`
Expected: PASS, `32 passed`.

- [ ] **Step 3: Lint e formato**

Run: `cargo fmt && cargo clippy --all-targets --all-features -- -D warnings`
Expected: sem warnings.

- [ ] **Step 4: Commit**

```bash
git add rust/src/ffi_tests.rs
git commit -m "test: unit-test memory-tracking FFI exports (#29)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Testar `assert` e os 12 exports de overflow

**Files:**
- Modify: `rust/src/ffi_tests.rs` (acrescentar no fim)

**Interfaces:**
- Consumes: `fresh`, `assert_ok`, `assert_violated` (Task 1).
- Produces: `fn check_overflow_pair(safe: impl FnOnce(), overflowing: impl FnOnce())` — reseta o estado antes de cada lado e espera `Overflow` na linha 4, função `"f"`.
- Símbolos cobertos: `map2check_is_valid_assert`, `map2check_binop_{add,sub,mul,div}_int`, `map2check_binop_neg_int`, `map2check_binop_shl_int`, `map2check_binop_shr_int`, `map2check_binop_{add,sub,mul,div}_unsigned`, `map2check_binop_shr_unsigned`.

Semântica esperada (de `rust/src/analysismode/overflow.rs`): aritmética via `checked_*`; divisão por zero conta como overflow; `shl_int` é inseguro se `rhs >= 32`, `lhs < 0` ou o resultado passar de `i32::MAX`; `shr_*` só é inseguro se `rhs >= 32`; `neg_int` só com `i32::MIN`. `map2check_is_valid_assert(…, 0)` reporta `Reachability`.

- [ ] **Step 1: Acrescentar os testes no fim de `rust/src/ffi_tests.rs`**

```rust
// ── Analysis mode: assert ───────────────────────────────────────────────────

#[test]
fn is_valid_assert_true_keeps_result_ok() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_is_valid_assert(5, c"main".as_ptr(), 1) };
    assert_ok();
}

#[test]
fn is_valid_assert_false_reports_reachability() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_is_valid_assert(5, c"main".as_ptr(), 0) };
    assert_violated(ViolatedProperty::Reachability, 5, "main");
}

// ── Analysis mode: overflow ─────────────────────────────────────────────────

/// Runs `op` once with operands that must be safe and once with operands that
/// must overflow, starting from a fresh state each time.
fn check_overflow_pair(safe: impl FnOnce(), overflowing: impl FnOnce()) {
    state::reset();
    safe();
    assert_ok();
    state::reset();
    overflowing();
    assert_violated(ViolatedProperty::Overflow, 4, "f");
}

#[test]
fn binop_add_int_detects_overflow() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_add_int(1, 2, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_add_int(i32::MAX, 1, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_sub_int_detects_overflow() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_sub_int(5, 3, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_sub_int(i32::MIN, 1, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_mul_int_detects_overflow() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_mul_int(6, 7, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_mul_int(i32::MAX, 2, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_div_int_detects_min_over_minus_one_and_zero_divisor() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_div_int(7, 2, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_div_int(i32::MIN, -1, 4, 0, c"f".as_ptr()) },
    );
    check_overflow_pair(
        || unsafe { map2check_binop_div_int(-7, 2, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_div_int(7, 0, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_neg_int_detects_min() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_neg_int(5, 0, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_neg_int(i32::MIN, 0, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_shl_int_detects_overflow_negative_lhs_and_wide_shift() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_shl_int(1, 30, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_shl_int(1, 31, 4, 0, c"f".as_ptr()) },
    );
    check_overflow_pair(
        || unsafe { map2check_binop_shl_int(0, 31, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_shl_int(-1, 1, 4, 0, c"f".as_ptr()) },
    );
    check_overflow_pair(
        || unsafe { map2check_binop_shl_int(3, 0, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_shl_int(1, 32, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_shr_int_detects_wide_shift() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_shr_int(-8, 31, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_shr_int(8, 32, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_add_unsigned_detects_overflow() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_add_unsigned(u32::MAX - 1, 1, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_add_unsigned(u32::MAX, 1, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_sub_unsigned_detects_wraparound() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_sub_unsigned(1, 1, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_sub_unsigned(0, 1, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_mul_unsigned_detects_overflow() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_mul_unsigned(65_535, 65_537, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_mul_unsigned(u32::MAX, 2, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_div_unsigned_detects_zero_divisor() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_div_unsigned(u32::MAX, 2, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_div_unsigned(1, 0, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_shr_unsigned_detects_wide_shift() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_shr_unsigned(u32::MAX, 31, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_shr_unsigned(1, 32, 4, 0, c"f".as_ptr()) },
    );
}
```

- [ ] **Step 2: Rodar os testes**

Run: `cargo test --all-features --lib ffi::tests`
Expected: PASS, `46 passed`.

- [ ] **Step 3: Lint e formato**

Run: `cargo fmt && cargo clippy --all-targets --all-features -- -D warnings`
Expected: sem warnings.

- [ ] **Step 4: Commit**

```bash
git add rust/src/ffi_tests.rs
git commit -m "test: unit-test assert and overflow FFI exports (#29)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Testar as checagens de segurança de memória

**Files:**
- Modify: `rust/src/ffi_tests.rs` (acrescentar no fim)

**Interfaces:**
- Consumes: `fresh`, `addr`, `assert_ok`, `assert_violated` (Task 1); `map2check_map_malloc`, `map2check_map_free`, `set_false_result`, `map2check_set_null_is_valid`, `map2check_set_memcleanup` (já testados nas Tasks 1 e 3).
- Produces: nada.
- Símbolos cobertos: `map2check_check_load`, `map2check_check_free`, `map2check_check_free_resolved_address`, `map2check_check_deref`, `map2check_check_mem_endprog`.

Semântica esperada (de `rust/src/memtrack/mod.rs` e `rust/src/analysismode/memory.rs`): toda `check_*` de memória começa zerando o resultado (`reset_result_metadata`), então uma checagem segura apaga uma violação anterior; `check_load` exige `[ptr, ptr+size)` dentro de uma alocação viva e trata NULL como seguro só após `map2check_set_null_is_valid`; `check_free` aceita NULL e alocação dinâmica viva, rejeita endereço já liberado ou não rastreado (`MemsafetyFree`); `check_free_resolved_address` rejeita alvo já liberado e ignora NULL quando `is_null_valid != 0`; `check_deref` rejeita NULL, liberado e não rastreado (`MemsafetyDeref`); `check_mem_endprog` só age após `map2check_set_memcleanup` e reporta `MemsafetyMemcleanup` na linha 0, função `"end_of_program"`.

- [ ] **Step 1: Acrescentar os testes no fim de `rust/src/ffi_tests.rs`**

```rust
// ── Analysis mode: memory ───────────────────────────────────────────────────

#[test]
fn check_load_accepts_access_inside_allocation() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_load(addr(0x1008), 12, 0, 8, c"main".as_ptr());
    }
    assert_ok();
}

#[test]
fn check_load_rejects_access_past_allocation_end() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_load(addr(0x100c), 12, 0, 8, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 12, "main");
}

#[test]
fn check_load_rejects_negative_size() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_load(addr(0x1000), 12, 0, -1, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 12, "main");
}

#[test]
fn check_load_null_depends_on_null_is_valid() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; null is never dereferenced.
    unsafe { map2check_check_load(std::ptr::null(), 12, 0, 4, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyDeref, 12, "main");

    map2check_set_null_is_valid();
    // SAFETY: as above.
    unsafe { map2check_check_load(std::ptr::null(), 12, 0, 4, c"main".as_ptr()) };
    assert_ok();
}

#[test]
fn check_load_clears_a_previous_violation_when_safe() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        set_false_result(0, 1, c"earlier".as_ptr());
        map2check_check_load(addr(0x1000), 12, 0, 4, c"main".as_ptr());
    }
    assert_ok();
}

#[test]
fn check_free_accepts_live_allocation_and_null() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_free(c"p".as_ptr(), addr(0x1000), 0, 20, c"main".as_ptr());
    }
    assert_ok();
    // SAFETY: as above.
    unsafe { map2check_check_free(c"p".as_ptr(), std::ptr::null(), 0, 20, c"main".as_ptr()) };
    assert_ok();
}

#[test]
fn check_free_rejects_double_free_and_untracked_address() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_map_free(c"p".as_ptr(), addr(0x1000), 0, 19, c"main".as_ptr());
        map2check_check_free(c"p".as_ptr(), addr(0x1000), 0, 20, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyFree, 20, "main");

    state::reset();
    // SAFETY: as above.
    unsafe { map2check_check_free(c"p".as_ptr(), addr(0x9000), 0, 21, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyFree, 21, "main");
}

#[test]
fn check_free_resolved_address_rejects_freed_target() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_free_resolved_address(addr(0x1000), 30, c"main".as_ptr(), 0);
    }
    assert_ok();

    // SAFETY: as above.
    unsafe {
        map2check_map_free(c"p".as_ptr(), addr(0x1000), 0, 30, c"main".as_ptr());
        map2check_check_free_resolved_address(addr(0x1000), 31, c"main".as_ptr(), 0);
    }
    assert_violated(ViolatedProperty::MemsafetyFree, 31, "main");
}

#[test]
fn check_free_resolved_address_null_depends_on_flag() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; null is never dereferenced.
    unsafe { map2check_check_free_resolved_address(std::ptr::null(), 32, c"main".as_ptr(), 1) };
    assert_ok();
}

#[test]
fn check_deref_accepts_live_and_rejects_freed_null_or_untracked() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_deref(addr(0x1000), 0, 40, c"main".as_ptr());
    }
    assert_ok();

    // SAFETY: as above.
    unsafe {
        map2check_map_free(c"p".as_ptr(), addr(0x1000), 0, 41, c"main".as_ptr());
        map2check_check_deref(addr(0x1000), 0, 42, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 42, "main");

    // SAFETY: as above.
    unsafe { map2check_check_deref(std::ptr::null(), 0, 43, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyDeref, 43, "main");

    // SAFETY: as above.
    unsafe { map2check_check_deref(addr(0x9000), 0, 44, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyDeref, 44, "main");
}

#[test]
fn check_mem_endprog_is_a_no_op_until_memcleanup_is_enabled() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 16) };
    map2check_check_mem_endprog();
    assert_ok();

    map2check_set_memcleanup();
    map2check_check_mem_endprog();
    assert_violated(ViolatedProperty::MemsafetyMemcleanup, 0, "end_of_program");
}

#[test]
fn check_mem_endprog_accepts_freed_allocation() {
    let _guard = fresh();
    map2check_set_memcleanup();
    // SAFETY: C-string literals are valid; fake address is never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_map_free(c"p".as_ptr(), addr(0x1000), 0, 50, c"main".as_ptr());
    }
    map2check_check_mem_endprog();
    assert_ok();
}
```

- [ ] **Step 2: Rodar os testes**

Run: `cargo test --all-features --lib ffi::tests`
Expected: PASS, `58 passed`.

- [ ] **Step 3: Lint e formato**

Run: `cargo fmt && cargo clippy --all-targets --all-features -- -D warnings`
Expected: sem warnings.

- [ ] **Step 4: Commit**

```bash
git add rust/src/ffi_tests.rs
git commit -m "test: unit-test memory-safety check FFI exports (#29)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Testar os ramos que encerram o processo em `libfuzzer.rs`

**Files:**
- Modify: `rust/src/nondet/libfuzzer.rs` — comentário `NOTE` no início do `mod tests` (linhas ~265-270) e fim do `mod tests` (antes do `}` final do arquivo)

**Interfaces:**
- Consumes: `__VERIFIER_assume`, `map2check_fuzzer_assume`, `__VERIFIER_error`, `__VERIFIER_assert` (via `use super::*;`); `output::print_json` imprime o JSON com `REACHABILITY` antes do `abort()`.
- Produces: nada usado por outras tasks. Os nomes `*_child` e o caminho `nondet::libfuzzer::tests::<name>` são o contrato entre pai e filho — renomear um exige ajustar a string passada a `run_child`.
- Símbolos cobertos: `__VERIFIER_error` (antes sem teste Rust) e os ramos `0` de `__VERIFIER_assume`, `map2check_fuzzer_assume`, `__VERIFIER_assert`.

Como funciona: cada teste `*_child` só faz algo com a variável `MAP2CHECK_FFI_CHILD` definida — sem ela é um no-op que passa. O teste pai re-executa `std::env::current_exe()` com `--exact nondet::libfuzzer::tests::<child> --nocapture` e a variável definida, e inspeciona como o filho terminou. O filho imprime `STARTED` antes da chamada (prova que o filtro casou) e `SURVIVED` depois (não pode aparecer). Para `exit(0)` o pai exige código 0 **e** ausência de `test result:` (o libtest não chegou a imprimir o resumo). Para `abort()` exige SIGABRT (sinal 6) e `REACHABILITY` no stdout. O `println!` do Rust usa `LineWriter`, então as linhas chegam ao pipe antes do `exit`/`abort`. O crate só roda em Linux (o harness usa `-ldl`), por isso o uso direto de `std::os::unix::process::ExitStatusExt`.

- [ ] **Step 1: Atualizar o comentário `NOTE` do `mod tests`**

Trocar:

```rust
    // NOTE: only the non-terminating branches are unit-tested here.
    // `__VERIFIER_assume(0)`, `__VERIFIER_assert(0)` and `__VERIFIER_error()`
    // call `std::process::exit`/`std::process::abort`, which would kill the
    // whole `cargo test` binary (and every other test running in it) rather
    // than fail a single test. Those branches are instead exercised as a
    // separate process by `tests/ffi_harness.c`.
```

por:

```rust
    // NOTE: the branches that end the process (`exit(0)` / `abort()`) would
    // kill the whole `cargo test` binary if called in-process. They are
    // tested at the end of this module by re-running this test binary as a
    // child process; `tests/ffi_harness.c` also exercises them.
```

- [ ] **Step 2: Acrescentar os testes antes do `}` que fecha `mod tests` (último caractere do arquivo)**

```rust

    // ── Process-terminating branches (issue #29) ─────────────────────────────
    //
    // Each `*_child` test only does something when `CHILD_ENV` is set: the
    // parent test re-runs this same test binary filtered to that one child and
    // inspects how the child process ended.

    const CHILD_ENV: &str = "MAP2CHECK_FFI_CHILD";
    const STARTED: &str = "map2check-child-started";
    const SURVIVED: &str = "map2check-child-survived";

    fn is_child() -> bool {
        std::env::var_os(CHILD_ENV).is_some()
    }

    /// Runs `nondet::libfuzzer::tests::<name>` in a separate process.
    fn run_child(name: &str) -> std::process::Output {
        let exe = std::env::current_exe().unwrap();
        let output = std::process::Command::new(exe)
            .args(["--exact", &format!("nondet::libfuzzer::tests::{name}")])
            .args(["--nocapture", "--test-threads=1"])
            .env(CHILD_ENV, "1")
            .output()
            .unwrap();
        let stdout = String::from_utf8_lossy(&output.stdout);
        assert!(
            stdout.contains(STARTED),
            "o processo filho não rodou `{name}`:\n{stdout}"
        );
        assert!(
            !stdout.contains(SURVIVED),
            "`{name}` deveria ter encerrado o processo:\n{stdout}"
        );
        output
    }

    /// Asserts the child ended via `exit(0)` before libtest printed its summary.
    fn assert_exited_zero(output: &std::process::Output) {
        let stdout = String::from_utf8_lossy(&output.stdout);
        assert_eq!(output.status.code(), Some(0), "{stdout}");
        assert!(!stdout.contains("test result:"), "{stdout}");
    }

    /// Asserts the child aborted after printing a REACHABILITY report.
    fn assert_aborted_with_reachability(output: &std::process::Output) {
        use std::os::unix::process::ExitStatusExt;
        let stdout = String::from_utf8_lossy(&output.stdout);
        assert_eq!(
            output.status.signal(),
            Some(6),
            "esperava SIGABRT:\n{stdout}"
        );
        assert!(stdout.contains("REACHABILITY"), "{stdout}");
    }

    #[test]
    fn verifier_assume_false_child() {
        if is_child() {
            println!("{STARTED}");
            __VERIFIER_assume(0);
            println!("{SURVIVED}");
        }
    }

    #[test]
    fn verifier_assume_false_exits_with_zero() {
        assert_exited_zero(&run_child("verifier_assume_false_child"));
    }

    #[test]
    fn map2check_fuzzer_assume_false_child() {
        if is_child() {
            println!("{STARTED}");
            map2check_fuzzer_assume(0);
            println!("{SURVIVED}");
        }
    }

    #[test]
    fn map2check_fuzzer_assume_false_exits_with_zero() {
        assert_exited_zero(&run_child("map2check_fuzzer_assume_false_child"));
    }

    #[test]
    fn verifier_error_child() {
        if is_child() {
            println!("{STARTED}");
            __VERIFIER_error();
            #[allow(unreachable_code)]
            {
                println!("{SURVIVED}");
            }
        }
    }

    #[test]
    fn verifier_error_aborts_and_reports_reachability() {
        assert_aborted_with_reachability(&run_child("verifier_error_child"));
    }

    #[test]
    fn verifier_assert_false_child() {
        if is_child() {
            println!("{STARTED}");
            __VERIFIER_assert(0);
            println!("{SURVIVED}");
        }
    }

    #[test]
    fn verifier_assert_false_aborts_and_reports_reachability() {
        assert_aborted_with_reachability(&run_child("verifier_assert_false_child"));
    }
```

- [ ] **Step 3: Rodar os testes**

Run: `cargo test --all-features --lib nondet::libfuzzer`
Expected: PASS, `18 passed` (os 4 `*_child` aparecem como `ok` — no-op sem a variável).

- [ ] **Step 4: Conferir que o teste pai detecta filtro errado**

Trocar temporariamente `run_child("verifier_error_child")` por `run_child("verifier_error_childX")` e rodar `cargo test --all-features --lib nondet::libfuzzer::tests::verifier_error_aborts`.
Expected: FAIL com `o processo filho não rodou`. Desfazer a troca (`git diff rust/src/nondet/libfuzzer.rs` não deve mostrar o `X`).

- [ ] **Step 5: Lint e formato**

Run: `cargo fmt && cargo clippy --all-targets --all-features -- -D warnings`
Expected: sem warnings.

- [ ] **Step 6: Commit**

```bash
git add rust/src/nondet/libfuzzer.rs
git commit -m "test: cover process-terminating verifier exports via child process (#29)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Checklist que falha quando um export não tem teste

**Files:**
- Create: `tests/ffi_exports_checklist.rs`

**Interfaces:**
- Consumes: `include/map2check.h` (gerado pelo `build.rs`); conteúdo de `rust/src/ffi_tests.rs` (inteiro) e de `rust/src/nondet/libfuzzer.rs` a partir de `\nmod tests {`.
- Produces: helpers locais `header_functions(&str) -> BTreeSet<String>`, `strip_line_comments(&str) -> String`, `mentions(&str, &str) -> bool`, `missing_symbols(&str, &str) -> Vec<String>`. Para um export novo: se ele vier de outro arquivo com testes próprios, acrescentar esse arquivo em `TEST_SOURCES`.

Regra: um símbolo do header está coberto se aparece como identificador inteiro (bordas não são `[A-Za-z0-9_]`) em código de teste fora de comentários `//`. Nomes de testes como `map2check_check_free_rejects_…` não contam, porque o `_` seguinte é caractere de identificador — só uma chamada real (ou uso do símbolo) conta.

- [ ] **Step 1: Criar `tests/ffi_exports_checklist.rs`**

```rust
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
```

- [ ] **Step 2: Rodar o checklist**

Run: `cargo test --all-features --test ffi_exports_checklist`
Expected: PASS, `6 passed`.

- [ ] **Step 3: Conferir que o checklist falha sem teste**

Run:
```bash
sed -i 's/map2check_is_in_trackbb_container(/xx_is_in(/g' rust/src/ffi_tests.rs
cargo test --all-features --test ffi_exports_checklist 2>&1 | grep 'exports sem'
sed -i 's/xx_is_in(/map2check_is_in_trackbb_container(/g' rust/src/ffi_tests.rs
git diff --exit-code rust/src/ffi_tests.rs
```
Expected: a linha `exports sem teste Rust (...): ["map2check_is_in_trackbb_container"]`; depois `git diff --exit-code` sai com 0 (arquivo restaurado).

- [ ] **Step 4: Verificação completa (o que o CI roda)**

Run:
```bash
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test
cargo test --all-features
cargo build --release --all-features
clang -fsanitize=address,undefined -fno-omit-frame-pointer \
  tests/ffi_harness.c target/release/libmap2check.a \
  -ldl -lpthread -lm -o target/ffi_harness && target/ffi_harness
```
Expected: tudo verde; `cargo test --all-features` com `142 passed` no unit test do crate, `6 passed` no checklist e `2 passed` em `header_version`. Se `cargo-tarpaulin` estiver instalado, rodar também `scripts/coverage.sh` (o gate é fora de `ffi*.rs`; os testes novos só podem subir a cobertura de `analysismode/` e `memtrack/`). Se não estiver, a cobertura fica para o job do CI — registrar isso no PR.

- [ ] **Step 5: Commit**

```bash
git add tests/ffi_exports_checklist.rs
git commit -m "test: fail when a header export has no Rust test (#29)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 6: Push e PR (pedir confirmação ao usuário antes)**

```bash
git push -u origin test/issue-29-ffi-unit-tests
gh pr create --base feature/rust --title "test: Rust unit tests for every exported FFI symbol (#29)" --body "$(cat <<'BODY'
## Resumo
- `rust/src/ffi_tests.rs`: testes unitários para os 44 exports de `ffi.rs`; cada um chama o export e verifica o efeito no `AnalysisState`.
- `rust/src/nondet/libfuzzer.rs`: `__VERIFIER_error` e os ramos `0` de `__VERIFIER_assume`, `map2check_fuzzer_assume` e `__VERIFIER_assert` testados via processo filho (encerram o processo).
- `tests/ffi_exports_checklist.rs`: falha quando uma função de `include/map2check.h` não é chamada por nenhum teste Rust.

Sem mudança de comportamento em código de produção.

## Teste
- `cargo test --all-features` (unit, checklist, header_version)
- `cargo clippy --all-targets --all-features -- -D warnings`
- harness FFI com ASan/UBSan
- checklist conferido removendo a chamada a um export (falha com o nome do símbolo)

Closes #29

🤖 Generated with [Claude Code](https://claude.com/claude-code)
BODY
)"
```
