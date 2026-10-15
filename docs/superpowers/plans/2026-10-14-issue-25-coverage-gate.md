# Issue #25 — Gate de cobertura (cargo-tarpaulin) no CI — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rodar `cargo-tarpaulin` no CI com gate `--fail-under 80` fora de `rust/src/ffi*.rs`, publicar o lcov como artefato, parar de mascarar falhas de cobertura no Dockerfile e subir a cobertura medida de 52,1% para ≥ 90% com testes unitários.

**Architecture:** Um único script, `scripts/coverage.sh`, concentra os flags do tarpaulin (engine, exclusões, formatos, limiar) e é chamado pelo CI e pelo estágio `test` do Dockerfile, que assim não divergem. O gate entra primeiro e falha (RED, 52,1% < 80%). Depois, testes de caracterização sobre código já existente o deixam verde. Os testes que tocam o estado global (`state::ANALYSIS_STATE`) ou os atômicos do LibFuzzer se serializam por um `state::test_lock()` só de teste, para não haver corrida entre testes paralelos.

**Tech Stack:** Rust 1.82.0 (fixado em `rust-toolchain.toml`), cargo-tarpaulin 0.31.3 (engine LLVM), GitHub Actions (`taiki-e/install-action@v2`, `actions/upload-artifact@v4`), Docker multi-stage.

**Spec:** Issue [#25](https://github.com/hbgit/map2check-library/issues/25) (Audit-ID M1-AC8, também cobre M1-E1, M3-AC3 e G-1) e `docs/plano_map2check_library_rust.md` (M1, M3, §3.4-1). Evidência de partida: `audit/relatorio_auditoria.md` e `audit/evidence/lcov_raw.txt`.

## Global Constraints

- Branch de trabalho `feat/issue-25-coverage-gate`, criada a partir de `origin/feature/rust` (`0f28571` ou mais novo). O PR vai para `feature/rust`. **Não** usar `develop`/`master`: o código Rust vive em `feature/rust`.
- Toolchain: `channel = "1.82.0"`; não usar API estabilizada depois da 1.82.
- Gate de cobertura: **`--fail-under 80`**, medido **fora de `rust/src/ffi*.rs`** (§3.4-1: "cobertura ≥ 80% fora de `ffi*.rs`").
- `unsafe` só em `ffi.rs` e no módulo `nondet::libfuzzer` (feature `libfuzzer`), como hoje; todo bloco `unsafe` novo leva um comentário `// SAFETY:`.
- Lints: `cargo clippy --all-targets --all-features -- -D warnings` e `cargo fmt --check` verdes; `unwrap/expect/panic` só em código `#[cfg(test)]` (`lib.rs:15-18`).
- Testes não podem chamar `__VERIFIER_error()`, `__VERIFIER_assert(0)` nem `__VERIFIER_assume(0)`: eles encerram o processo do `cargo test` (`libfuzzer.rs:265-270`).
- Commits assinados (`git commit -S`) e **sem** atribuição de IA, nem nos commits nem no PR (CLAUDE.md do projeto).
- Mensagens de commit no padrão `area: descrição`.

## Review Focus

1. **Corrida entre testes paralelos no estado global ou nos atômicos do LibFuzzer**: um teste chama `state::reset()` ou mexe em `FUZZER_CURSOR` enquanto outro lê, e o teste falha de vez em quando. Esperado: estável em execuções repetidas. Teste: Task 6, Step 1 roda `cargo test --all-features` 10× seguidas.
2. **O gate não ser aplicado de verdade**: exit code engolido pelo Docker (`|| ...`), pelo `tee` ou por `if: always()`. Esperado: abaixo de 80% o CI fica vermelho. Teste: Task 1, Step 4 (RED observado no Docker) e Task 6, Step 4 (CI verde só depois dos testes).
3. **A exclusão `ffi*.rs` não casar com o caminho absoluto** dentro do Docker/CI e `ffi.rs` entrar na conta. Teste: Task 1, Step 5 e Task 6, Step 3 verificam que o lcov não tem `SF:` com `ffi`.
4. **O teste de lock envenenado deixar o estado global envenenado** e derrubar outros testes. Esperado: `reset()` limpa o poison. Teste: Task 2, `reset_recovers_from_poisoned_lock` verifica `!is_poisoned()` ao final.
5. **`--out Lcov --out Html` não gerar os dois arquivos** e o upload publicar um diretório vazio. Teste: Task 1, Step 5 lista `lcov.info` e `tarpaulin-report.html`; o CI usa `if-no-files-found: error`.

---

## Estrutura de arquivos

| Arquivo | Responsabilidade | Task |
|---|---|---|
| `scripts/coverage.sh` (novo) | Fonte única dos flags do tarpaulin e do limiar | 1 |
| `.github/workflows/CI.yml` | Instala o tarpaulin, roda o script, publica o artefato `coverage` | 1 |
| `Dockerfile` | Estágio `test` chama o script; remove `\|\| mkdir -p /coverage` | 1 |
| `README.md` (seção "Cobertura") | Documenta o script e o gate | 1 |
| `rust/src/state.rs` | `test_lock()` (`#[cfg(test)]`) + testes de `next_step`, `current_step` e reset com poison | 2 |
| `rust/src/error.rs` | Teste de `From<PoisonError>` | 2 |
| `rust/src/analysismode/memory.rs` | Testes dos 5 checkers contra o estado global | 3 |
| `rust/src/nondet/libfuzzer.rs` | Testes dos geradores e de `LLVMFuzzerTestOneInput` | 4 |
| `rust/src/analysismode/overflow.rs`, `caller/mod.rs`, `nondet/mod.rs`, `memtrack/mod.rs`, `output/mod.rs` | Testes dos ramos ainda não cobertos | 5 |

Linhas hoje não cobertas, a partir de `audit/evidence/lcov_raw.txt`: `memory.rs` 36, `libfuzzer.rs` 65, `overflow.rs` 10, `state.rs` 9, `memtrack/mod.rs` 7, `caller/mod.rs` 4, `nondet/mod.rs` 4, `error.rs` 2, `output/mod.rs` 2. Total medido: 151/290.

---

### Task 1: Gate de cobertura (script, CI, Dockerfile) — RED

**Files:**
- Create: `scripts/coverage.sh`
- Modify: `.github/workflows/CI.yml` (depois do step "Rodar todos os testes", linha 34)
- Modify: `Dockerfile:27-39` (estágio `test`)
- Modify: `README.md:57-65` (seção "Cobertura")

**Interfaces:**
- Produces: `scripts/coverage.sh`, executável. Variáveis `COVERAGE_FAIL_UNDER` (default `80`) e `COVERAGE_OUT_DIR` (default `coverage`). Gera `$COVERAGE_OUT_DIR/lcov.info` e `$COVERAGE_OUT_DIR/tarpaulin-report.html`. Sai com código ≠ 0 abaixo do limiar.

- [ ] **Step 1: Criar o worktree e a branch**

```bash
cd /home/rock/Documents/Dev/map2check-library
git fetch origin
git worktree add -b feat/issue-25-coverage-gate ../map2check-library-issue25 origin/feature/rust
cd ../map2check-library-issue25
git log -1 --oneline
```
Esperado: HEAD em `0f28571 Merge pull request #3 ...` (ou mais novo). Todas as tasks seguintes rodam em `../map2check-library-issue25`.

- [ ] **Step 2: Criar `scripts/coverage.sh`**

```bash
#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Roda o cargo-tarpaulin com o gate de cobertura do projeto.
# Usado pelo CI (.github/workflows/CI.yml) e pelo estágio `test` do Dockerfile.
set -euo pipefail

FAIL_UNDER="${COVERAGE_FAIL_UNDER:-80}"
OUT_DIR="${COVERAGE_OUT_DIR:-coverage}"

exec cargo tarpaulin \
  --engine llvm \
  --all-features \
  --exclude-files 'rust/src/ffi*.rs' \
  --out Lcov --out Html \
  --output-dir "$OUT_DIR" \
  --fail-under "$FAIL_UNDER"
```

```bash
mkdir -p scripts && chmod +x scripts/coverage.sh && bash -n scripts/coverage.sh && echo syntax-ok
```
Esperado: `syntax-ok`.

- [ ] **Step 3: Usar o script no Dockerfile.** Substituir as linhas 27-39 (estágio `test`) por:

```dockerfile
# ── Stage 2: Test + Coverage ──────────────────────────────────────────────────
FROM builder AS test

COPY test/ ./test/
COPY scripts/coverage.sh ./scripts/coverage.sh

RUN cargo test --all-features 2>&1 | tee /tmp/test-results.txt

# Falha o build se a cobertura (fora de rust/src/ffi*.rs) ficar abaixo do gate.
RUN COVERAGE_OUT_DIR=/coverage scripts/coverage.sh
```
O estágio `final` (`COPY --from=test /coverage /coverage`) continua igual.

- [ ] **Step 4: Ver o gate falhar (RED)**

```bash
docker build --target test --progress=plain . > /tmp/issue25-red.log 2>&1; echo "rc=$?"
grep -nE '[0-9.]+% coverage|below the failure threshold|failure threshold' /tmp/issue25-red.log | tail -3
```
Esperado: `rc` diferente de 0 e uma linha como `52.07% coverage, 151/290 lines covered` seguida de `Coverage is below the failure threshold 52.07% < 80.00%`. Se `rc=0`, o gate não está sendo aplicado: **pare** e corrija antes de seguir (Review Focus 2).

- [ ] **Step 5: Conferir os artefatos e a exclusão do `ffi.rs`** (com o gate desligado só para inspecionar)

```bash
docker build --target builder -t m2c-issue25-builder . >/dev/null
docker run --rm -e COVERAGE_FAIL_UNDER=0 -e COVERAGE_OUT_DIR=/tmp/cov \
  -v "$PWD/scripts":/build/scripts:ro m2c-issue25-builder \
  sh -c 'scripts/coverage.sh >/dev/null 2>&1; ls /tmp/cov; grep -c "^SF:.*ffi" /tmp/cov/lcov.info || true'
docker rmi -f m2c-issue25-builder >/dev/null
```
Esperado: `lcov.info` e `tarpaulin-report.html` listados, e `0` na contagem de `SF:` com `ffi` (Review Focus 3 e 5).

- [ ] **Step 6: Adicionar os steps no CI.** Em `.github/workflows/CI.yml`, logo depois do step `Rodar todos os testes` (linha 34), inserir:

```yaml
      - name: Instalar cargo-tarpaulin
        uses: taiki-e/install-action@v2
        with:
          tool: cargo-tarpaulin@0.31.3

      - name: Cobertura (cargo-tarpaulin, gate de 80% fora de ffi*.rs)
        run: scripts/coverage.sh

      - name: Publicar relatório de cobertura
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/
          if-no-files-found: error
```

- [ ] **Step 7: Atualizar a seção "Cobertura" do README** (`README.md:57-65`), substituindo o bloco atual por:

````markdown
### Cobertura

A cobertura é medida com `cargo-tarpaulin` (engine LLVM), excluindo `rust/src/ffi*.rs`, e o build falha abaixo de **80%**. O CI e o `Dockerfile` usam o mesmo script:

```sh
scripts/coverage.sh                        # gate padrão de 80%
COVERAGE_FAIL_UNDER=0 scripts/coverage.sh  # só gera o relatório, sem gate
```

Os relatórios ficam em `coverage/lcov.info` e `coverage/tarpaulin-report.html`. No CI, eles são publicados como o artefato `coverage`.
````

- [ ] **Step 8: Commit (o RED fica registrado de propósito; não fazer push ainda)**

```bash
git add scripts/coverage.sh Dockerfile .github/workflows/CI.yml README.md
git commit -S -m "ci: enforce 80% tarpaulin coverage gate outside ffi*.rs" \
  -m "Single scripts/coverage.sh shared by CI and the Dockerfile test stage; the lcov/html report is uploaded as the 'coverage' artifact. The Dockerfile no longer masks tarpaulin failures with '|| mkdir -p /coverage'. Refs #25."
```

---

### Task 2: Lock de teste e testes de `state`/`error`

**Files:**
- Modify: `rust/src/state.rs` (antes de `mod tests`, linha 93; dentro de `mod tests`)
- Modify: `rust/src/error.rs` (adicionar `mod tests` no fim)

**Interfaces:**
- Produces: `#[cfg(test)] pub(crate) fn test_lock() -> std::sync::MutexGuard<'static, ()>` em `crate::state`. **Todo teste que lê ou escreve o estado global ou os atômicos do LibFuzzer deve manter esse guard vivo durante o teste inteiro** (Tasks 3 e 4).

- [ ] **Step 1: Escrever os testes que falham.** Em `rust/src/state.rs`, dentro de `mod tests`, adicionar `let _guard = test_lock();` como **primeira linha** do teste existente `reset_clears_global_state` e acrescentar:

```rust
    #[test]
    fn next_step_increments_and_current_step_reads_it() {
        let mut s = AnalysisState::default();
        assert_eq!(s.current_step(), 0);
        assert_eq!(s.next_step(), 1);
        assert_eq!(s.next_step(), 2);
        assert_eq!(s.current_step(), 2);
    }

    #[test]
    fn reset_recovers_from_poisoned_lock() {
        let _guard = test_lock();
        let _ = std::thread::spawn(|| {
            let _held = ensure_state().lock().unwrap();
            panic!("poison the analysis state on purpose");
        })
        .join();
        assert!(ensure_state().is_poisoned());

        reset();

        assert!(!ensure_state().is_poisoned());
        assert!(with_state(|s| Ok(s.result.ok)).unwrap());
    }
```

Em `rust/src/error.rs`, no fim do arquivo:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn poison_error_converts_to_lock_poisoned() {
        let mutex = std::sync::Mutex::new(0_u8);
        std::thread::scope(|scope| {
            let _ = scope
                .spawn(|| {
                    let _held = mutex.lock().unwrap();
                    panic!("poison the mutex on purpose");
                })
                .join();
        });
        let err: Map2CheckError = mutex.lock().unwrap_err().into();
        assert!(matches!(err, Map2CheckError::LockPoisoned(_)));
        assert!(err.to_string().starts_with("lock poisoned"));
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cargo test --all-features state:: 2>&1 | tail -5`
Esperado: erro de compilação `cannot find function test_lock in this scope`.

- [ ] **Step 3: Implementar `test_lock`.** Em `rust/src/state.rs`, logo antes de `#[cfg(test)] mod tests`:

```rust
/// Serializes unit tests that touch process-wide state (the analysis state and
/// the LibFuzzer input atomics). `cargo test` runs tests in parallel threads,
/// so without this a `reset()` in one test can wipe another test's setup.
#[cfg(test)]
pub(crate) fn test_lock() -> std::sync::MutexGuard<'static, ()> {
    static TEST_LOCK: Mutex<()> = Mutex::new(());
    TEST_LOCK
        .lock()
        .unwrap_or_else(std::sync::PoisonError::into_inner)
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `cargo test --all-features -- state:: error:: 2>&1 | grep -E '^test |test result'`
Esperado: `reset_clears_global_state`, `next_step_increments_and_current_step_reads_it`, `reset_recovers_from_poisoned_lock` e `poison_error_converts_to_lock_poisoned` com `ok`, e `test result: ok`. A mensagem `panicked at ... poison the ... on purpose` no stderr é esperada.

- [ ] **Step 5: Lints e commit**

```bash
cargo fmt && cargo fmt --check && cargo clippy --all-targets --all-features -- -D warnings
git add rust/src/state.rs rust/src/error.rs
git commit -S -m "test: serialize global-state tests and cover state/error helpers" -m "Refs #25."
```

---

### Task 3: Testes dos checkers de memória

**Files:**
- Modify: `rust/src/analysismode/memory.rs` (dentro de `mod tests`, depois de `null_load_obeys_null_valid_flag`)

**Interfaces:**
- Consumes: `crate::state::test_lock()` (Task 2); `crate::state::{reset, with_state}`; `crate::memtrack::MemTrackEntry::new(step, line, scope, var_addr, points_to, is_dynamic, is_free, ptr_name, function_name, size_destiny, size_primitive, is_null_valid)`.

- [ ] **Step 1: Escrever os testes.** Em `mod tests` de `memory.rs`, adicionar:

```rust
    use crate::memtrack::MemTrackEntry;

    fn ctx() -> VccContext {
        VccContext::new(1, 0, "test")
    }

    /// Takes the global-state test lock, resets the state and installs `entries`.
    /// Keep the returned guard alive for the whole test.
    fn with_entries(entries: Vec<MemTrackEntry>) -> std::sync::MutexGuard<'static, ()> {
        let guard = state::test_lock();
        state::reset();
        state::with_state(|s| {
            s.memtrack = entries;
            Ok(())
        })
        .unwrap();
        guard
    }

    /// Heap allocation held by pointer variable `var_addr`; `is_free` models a freed block.
    fn heap(var_addr: usize, points_to: usize, size: usize, is_free: bool) -> MemTrackEntry {
        MemTrackEntry::new(
            1, 10, 0, var_addr, points_to, !is_free, is_free, "p", "main", size, 4, false,
        )
    }

    /// Stack variable (`alloca`): neither dynamic nor freed.
    fn stack(var_addr: usize) -> MemTrackEntry {
        MemTrackEntry::new(1, 10, 0, var_addr, var_addr, false, false, "x", "main", 4, 4, false)
    }

    fn violated(property: ViolatedProperty) -> VccOutcome {
        VccOutcome::Violated { property }
    }

    #[test]
    fn load_inside_live_allocation_is_safe() {
        let _g = with_entries(vec![heap(0x10, 0x1000, 16, false)]);
        let load = LoadChecker { address: 0x1004, size: 4, is_null_valid: false };
        assert_eq!(load.check(&ctx()).unwrap(), VccOutcome::Safe);
    }

    #[test]
    fn load_past_allocation_end_is_deref_violation() {
        let _g = with_entries(vec![heap(0x10, 0x1000, 16, false)]);
        let load = LoadChecker { address: 0x100c, size: 8, is_null_valid: false };
        assert_eq!(
            load.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyDeref)
        );
    }

    #[test]
    fn load_from_freed_block_is_deref_violation() {
        let _g = with_entries(vec![heap(0x10, 0x1000, 16, true)]);
        let load = LoadChecker { address: 0x1000, size: 4, is_null_valid: false };
        assert_eq!(
            load.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyDeref)
        );
    }

    #[test]
    fn free_checker_outcomes() {
        let _g = with_entries(vec![heap(0x10, 0x1000, 16, false), heap(0x20, 0x2000, 8, true)]);
        assert_eq!(FreeChecker { address: 0 }.check(&ctx()).unwrap(), VccOutcome::Safe);
        assert_eq!(FreeChecker { address: 0x10 }.check(&ctx()).unwrap(), VccOutcome::Safe);
        assert_eq!(
            FreeChecker { address: 0x20 }.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyFree)
        );
        assert_eq!(
            FreeChecker { address: 0x99 }.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyFree)
        );
    }

    #[test]
    fn free_resolved_checker_outcomes() {
        let _g = with_entries(vec![heap(0x10, 0x1000, 16, false), heap(0x20, 0x2000, 8, true)]);
        assert_eq!(FreeResolvedChecker { address: 0 }.check(&ctx()).unwrap(), VccOutcome::Safe);
        assert_eq!(
            FreeResolvedChecker { address: 0x1000 }.check(&ctx()).unwrap(),
            VccOutcome::Safe
        );
        assert_eq!(
            FreeResolvedChecker { address: 0x2000 }.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyFree)
        );
        assert_eq!(
            FreeResolvedChecker { address: 0x9999 }.check(&ctx()).unwrap(),
            VccOutcome::Safe
        );
    }

    #[test]
    fn deref_checker_outcomes() {
        let _g = with_entries(vec![
            heap(0x10, 0x1000, 16, false),
            heap(0x20, 0x2000, 8, true),
            stack(0x30),
        ]);
        assert_eq!(
            DerefChecker { address: 0 }.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyDeref)
        );
        assert_eq!(DerefChecker { address: 0x1000 }.check(&ctx()).unwrap(), VccOutcome::Safe);
        assert_eq!(
            DerefChecker { address: 0x2000 }.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyDeref)
        );
        assert_eq!(DerefChecker { address: 0x30 }.check(&ctx()).unwrap(), VccOutcome::Safe);
        assert_eq!(
            DerefChecker { address: 0x5555 }.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyDeref)
        );
    }

    #[test]
    fn mem_cleanup_flags_leaked_allocation() {
        let _g = with_entries(vec![stack(0x30), heap(0x10, 0x1000, 16, false)]);
        assert_eq!(
            MemCleanupChecker.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyMemcleanup)
        );
    }

    #[test]
    fn mem_cleanup_accepts_freed_allocation_and_stack_vars() {
        let _g = with_entries(vec![
            stack(0x30),
            heap(0x10, 0x1000, 16, false),
            heap(0x10, 0x1000, 16, true),
        ]);
        assert_eq!(MemCleanupChecker.check(&ctx()).unwrap(), VccOutcome::Safe);
    }
```

Os valores esperados vêm da leitura de `memtrack::{is_invalid_address, is_invalid_free, is_invalid_free_resolved, is_deref_error, has_memcleanup_error}` (`memtrack/mod.rs:98-165`). São testes de **caracterização**: fixam o comportamento atual e não adjudicam a semântica, que é escopo das issues #11 e #15.

- [ ] **Step 2: Rodar**

Run: `cargo test --all-features analysismode::memory:: 2>&1 | grep -E '^test |test result'`
Esperado: os 9 testes de `analysismode::memory::tests` com `ok`. Como o código já existe, eles passam de primeira; o RED desta frente é o gate da Task 1. **Se algum falhar**, não ajuste a expectativa para "fazer passar" sem antes reler a função do `memtrack` correspondente. Se o comportamento atual contradiz o comentário da função, registre no ledger e comente na issue #11.

- [ ] **Step 3: Lints e commit**

```bash
cargo fmt && cargo fmt --check && cargo clippy --all-targets --all-features -- -D warnings
git add rust/src/analysismode/memory.rs
git commit -S -m "test: cover memory VCC checkers against the global memtrack state" -m "Refs #25."
```

---

### Task 4: Testes dos geradores LibFuzzer e de `LLVMFuzzerTestOneInput`

**Files:**
- Modify: `rust/src/nondet/libfuzzer.rs` (dentro de `mod tests`, linhas 261-291)

**Interfaces:**
- Consumes: `crate::state::test_lock()` (Task 2); itens privados do módulo pai: `FUZZER_DATA`, `FUZZER_SIZE`, `FUZZER_CURSOR`, `FuzzerStateReset`, `Ordering` (visíveis via `use super::*`).

- [ ] **Step 1: Proteger o teste existente que lê os atômicos.** Em `verifier_nondet_pointer_does_not_panic`, adicionar `let _guard = crate::state::test_lock();` como primeira linha (senão ele avança o cursor de outro teste em paralelo).

- [ ] **Step 2: Escrever os testes.** Em `mod tests`, adicionar:

```rust
    /// Installs `data` as the current fuzzer input for the duration of `f`,
    /// under the global test lock, and clears it afterwards.
    fn with_input<R>(data: &[u8], f: impl FnOnce() -> R) -> R {
        let _guard = crate::state::test_lock();
        let _reset = FuzzerStateReset;
        FUZZER_DATA.store(data.as_ptr() as *mut u8, Ordering::SeqCst);
        FUZZER_SIZE.store(data.len(), Ordering::SeqCst);
        FUZZER_CURSOR.store(0, Ordering::SeqCst);
        f()
    }

    #[test]
    fn narrow_generators_decode_little_endian_input_in_order() {
        let data = [
            0x02, // bool: 2 % 2 == 0 -> true
            0xff, // char: -1
            0xfe, // uchar: 254
            0x01, 0x80, // short: 0x8001 -> -32767
            0x34, 0x12, // ushort: 0x1234
            0xff, 0xff, 0xff, 0xff, // int: -1
            0x78, 0x56, 0x34, 0x12, // uint: 0x1234_5678
        ];
        with_input(&data, || {
            assert!(__VERIFIER_nondet_bool());
            assert_eq!(__VERIFIER_nondet_char(), -1);
            assert_eq!(__VERIFIER_nondet_uchar(), 254);
            assert_eq!(__VERIFIER_nondet_short(), -32767);
            assert_eq!(__VERIFIER_nondet_ushort(), 0x1234);
            assert_eq!(__VERIFIER_nondet_int(), -1);
            assert_eq!(__VERIFIER_nondet_uint(), 0x1234_5678);
        });
    }

    #[test]
    fn wide_generators_decode_eight_byte_values() {
        let mut data = Vec::new();
        data.extend_from_slice(&(-2_i64).to_le_bytes());
        data.extend_from_slice(&u64::MAX.to_le_bytes());
        data.extend_from_slice(&1.5_f32.to_bits().to_le_bytes());
        data.extend_from_slice(&(-2.25_f64).to_bits().to_le_bytes());
        data.extend_from_slice(&4096_u64.to_le_bytes());
        data.extend_from_slice(&0x1000_u64.to_le_bytes());
        with_input(&data, || {
            assert_eq!(__VERIFIER_nondet_long(), -2);
            assert_eq!(__VERIFIER_nondet_ulong(), u64::MAX);
            assert_eq!(__VERIFIER_nondet_float().to_bits(), 1.5_f32.to_bits());
            assert_eq!(__VERIFIER_nondet_double().to_bits(), (-2.25_f64).to_bits());
            assert_eq!(__VERIFIER_nondet_size_t(), 4096);
            assert_eq!(__VERIFIER_nondet_pointer() as usize, 0x1000);
        });
    }

    #[test]
    fn exhausted_input_yields_zero_without_advancing() {
        with_input(&[0x07], || {
            assert_eq!(__VERIFIER_nondet_int(), 0); // needs 4 bytes, only 1 left
            assert_eq!(__VERIFIER_nondet_uchar(), 7); // failed read did not consume
            assert_eq!(__VERIFIER_nondet_uchar(), 0);
            assert!(__VERIFIER_nondet_bool()); // 0 % 2 == 0
        });
    }

    #[test]
    fn null_buffer_with_nonzero_size_yields_zero() {
        let _guard = crate::state::test_lock();
        let _reset = FuzzerStateReset;
        FUZZER_SIZE.store(8, Ordering::SeqCst);
        assert_eq!(__VERIFIER_nondet_long(), 0);
    }

    #[test]
    fn fuzzer_iteration_resets_analysis_state_and_input() {
        let _guard = crate::state::test_lock();
        crate::state::with_state(|s| {
            s.set_false(crate::caller::ViolatedProperty::Overflow, 7, "stale");
            Ok(())
        })
        .unwrap();
        let data = [1_u8, 2, 3, 4];
        // SAFETY: `data` is valid for `data.len()` bytes for the whole call.
        let rc = unsafe { LLVMFuzzerTestOneInput(data.as_ptr(), data.len()) };
        assert_eq!(rc, 0);
        assert!(crate::state::with_state(|s| Ok(s.result.ok)).unwrap());
        assert!(FUZZER_DATA.load(Ordering::SeqCst).is_null());
        assert_eq!(FUZZER_SIZE.load(Ordering::SeqCst), 0);
        assert_eq!(FUZZER_CURSOR.load(Ordering::SeqCst), 0);
    }

    #[test]
    fn fuzzer_iteration_rejects_null_data_with_nonzero_size() {
        let _guard = crate::state::test_lock();
        // SAFETY: the entry point must reject a null buffer with non-zero size
        // without reading from it; nothing is dereferenced.
        let rc = unsafe { LLVMFuzzerTestOneInput(std::ptr::null(), 16) };
        assert_eq!(rc, 0);
        assert!(FUZZER_DATA.load(Ordering::SeqCst).is_null());
    }
```

- [ ] **Step 3: Rodar**

Run: `cargo test --all-features nondet::libfuzzer:: 2>&1 | grep -E '^test |test result'`
Esperado: 10 testes `ok` (4 existentes e 6 novos). Se `narrow_generators...` falhar em `short`, confira o valor: `0x8001_u16 as i16 == -32767`.

- [ ] **Step 4: Lints e commit**

```bash
cargo fmt && cargo fmt --check && cargo clippy --all-targets --all-features -- -D warnings
git add rust/src/nondet/libfuzzer.rs
git commit -S -m "test: cover LibFuzzer nondet generators and iteration entry point" -m "Refs #25."
```

---

### Task 5: Testes dos ramos restantes (overflow, caller, nondet, memtrack, output)

**Files:**
- Modify: `rust/src/analysismode/overflow.rs` (`mod tests`)
- Modify: `rust/src/caller/mod.rs` (`mod tests`)
- Modify: `rust/src/nondet/mod.rs` (`mod tests`)
- Modify: `rust/src/memtrack/mod.rs` (`mod tests`)
- Modify: `rust/src/output/mod.rs` (`mod tests`)

**Interfaces:**
- Consumes: só tipos existentes. Nenhum desses testes toca o estado global, então dispensam `test_lock()`.

- [ ] **Step 1: Escrever os testes**

`overflow.rs`, em `mod tests` (usa os helpers existentes `ctx()` e `overflow_outcome()`):

```rust
    #[test]
    fn mul_and_shr_u32_bounds() {
        assert_eq!(MulU32 { lhs: u32::MAX, rhs: 2 }.check(&ctx()).unwrap(), overflow_outcome());
        assert_eq!(MulU32 { lhs: 3, rhs: 4 }.check(&ctx()).unwrap(), VccOutcome::Safe);
        assert_eq!(ShrU32 { lhs: 1, rhs: 32 }.check(&ctx()).unwrap(), overflow_outcome());
        assert_eq!(ShrU32 { lhs: 1, rhs: 31 }.check(&ctx()).unwrap(), VccOutcome::Safe);
    }

    #[test]
    fn i64_checkers_detect_overflow_and_accept_normal_values() {
        assert_eq!(AddI64 { lhs: i64::MAX, rhs: 1 }.check(&ctx()).unwrap(), overflow_outcome());
        assert_eq!(AddI64 { lhs: 1, rhs: 2 }.check(&ctx()).unwrap(), VccOutcome::Safe);
        assert_eq!(SubI64 { lhs: i64::MIN, rhs: 1 }.check(&ctx()).unwrap(), overflow_outcome());
        assert_eq!(SubI64 { lhs: 5, rhs: 3 }.check(&ctx()).unwrap(), VccOutcome::Safe);
        assert_eq!(MulI64 { lhs: i64::MAX, rhs: 2 }.check(&ctx()).unwrap(), overflow_outcome());
        assert_eq!(MulI64 { lhs: -4, rhs: 3 }.check(&ctx()).unwrap(), VccOutcome::Safe);
    }
```

`caller/mod.rs`, em `mod tests`:

```rust
    #[test]
    fn violated_property_as_str_covers_every_variant() {
        let cases = [
            (ViolatedProperty::Overflow, "OVERFLOW"),
            (ViolatedProperty::MemsafetyFree, "MEMSAFETY_FREE"),
            (ViolatedProperty::MemsafetyDeref, "MEMSAFETY_DEREF"),
            (ViolatedProperty::MemsafetyMemtrack, "MEMSAFETY_MEMTRACK"),
            (ViolatedProperty::MemsafetyMemcleanup, "MEMSAFETY_MEMCLEANUP"),
            (ViolatedProperty::Reachability, "REACHABILITY"),
            (ViolatedProperty::Concurrency, "CONCURRENCY"),
            (ViolatedProperty::None, "NONE"),
        ];
        for (property, name) in cases {
            assert_eq!(property.as_str(), name);
        }
    }
```

`nondet/mod.rs`, em `mod tests`:

```rust
    #[test]
    fn type_name_covers_every_variant() {
        let cases = [
            (NonDetValue::Int(-1), "INT"),
            (NonDetValue::UInt(1), "UINT"),
            (NonDetValue::Long(-1), "LONG"),
            (NonDetValue::Char(-1), "CHAR"),
            (NonDetValue::Float(0.5), "FLOAT"),
            (NonDetValue::Double(0.5), "DOUBLE"),
        ];
        for (value, name) in cases {
            assert_eq!(value.type_name(), name);
            assert!(serde_json::to_string(&value).unwrap().contains(name));
        }
    }
```

`memtrack/mod.rs`, em `mod tests` (usa o helper existente `make_entry(var_addr, points_to, is_dynamic, is_free, size)`):

```rust
    #[test]
    fn same_slot_compares_address_scope_flags_and_line() {
        let a = make_entry(0x100, 0x200, true, false, 8);
        let mut b = make_entry(0x100, 0x300, true, false, 16);
        assert!(a.same_slot(&b)); // points_to and size do not matter
        b.line = 11;
        assert!(!a.same_slot(&b));
        let c = make_entry(0x100, 0x200, true, true, 8);
        assert!(!a.same_slot(&c));
        let d = make_entry(0x104, 0x200, true, false, 8);
        assert!(!a.same_slot(&d));
    }

    #[test]
    fn cleanup_ignores_stack_entries() {
        let entries = vec![make_entry(0x100, 0x100, false, false, 4)];
        assert!(!has_memcleanup_error(&entries));
    }
```

`output/mod.rs`, em `mod tests` (usa o helper existente `state_ok()`):

```rust
    #[test]
    fn print_json_succeeds_for_valid_state() {
        assert!(print_json(&state_ok()).is_ok());
    }
```

- [ ] **Step 2: Rodar a suíte inteira**

Run: `cargo test --all-features 2>&1 | grep -E 'test result|FAILED|panicked' | grep -v 'on purpose'`
Esperado: `test result: ok. 76 passed; 0 failed` (52 de antes + 3 da Task 2 + 8 da Task 3 + 6 da Task 4 + 7 desta task). Nenhum `FAILED`.

- [ ] **Step 3: Lints e commit**

```bash
cargo fmt && cargo fmt --check && cargo clippy --all-targets --all-features -- -D warnings
git add rust/src/analysismode/overflow.rs rust/src/caller/mod.rs rust/src/nondet/mod.rs rust/src/memtrack/mod.rs rust/src/output/mod.rs
git commit -S -m "test: cover remaining overflow, caller, nondet, memtrack and output branches" -m "Refs #25."
```

---

### Task 6: Gate verde, PR e fechamento da issue

**Files:** nenhum arquivo novo; só verificação, push e PR.

- [ ] **Step 1: Estabilidade dos testes (Review Focus 1)**

```bash
for i in $(seq 1 10); do cargo test --all-features -q > /tmp/issue25-run-$i.log 2>&1 || echo "FAIL run $i"; done; echo done
```
Esperado: só `done`, sem nenhuma linha `FAIL run N`. Se alguma falhar, use superpowers:systematic-debugging: quase sempre é um teste que toca estado global sem `test_lock()`.

- [ ] **Step 2: Suíte completa de checagens locais**

```bash
cargo fmt --check && cargo clippy --all-targets --all-features -- -D warnings \
  && cargo build --release && cargo test --all-features -q && echo ALL-GREEN
```
Esperado: `ALL-GREEN`.

- [ ] **Step 3: Gate verde no Docker (GREEN da Task 1)**

```bash
docker build --progress=plain . > /tmp/issue25-green.log 2>&1; echo "rc=$?"
grep -nE '[0-9.]+% coverage' /tmp/issue25-green.log | tail -1
```
Esperado: `rc=0` e cobertura **≥ 90%** (estimativa: cerca de 279/290; continuam descobertas só as linhas de `__VERIFIER_error`/`assert(0)`/`assume(0)` em `libfuzzer.rs`, que encerram o processo). Se ficar entre 80% e 90%, ainda passa no gate: registre o número e as linhas descobertas (`grep -A2 'Uncovered Lines' /tmp/issue25-green.log`) no PR. Se ficar abaixo de 80%, volte às Tasks 3–5; **não** baixe o gate.

- [ ] **Step 4: Push e PR para `feature/rust`**

```bash
git push -u origin feat/issue-25-coverage-gate
gh pr create -R hbgit/map2check-library --base feature/rust --head feat/issue-25-coverage-gate \
  --title "ci: enforce 80% tarpaulin coverage gate outside ffi*.rs" \
  --body "$(cat <<'EOF'
Resolves #25 (Audit-ID M1-AC8; also covers M1-E1, M3-AC3 and the coverage part of G-1).

## Changes
- `scripts/coverage.sh`: single source of the tarpaulin flags (LLVM engine, `--all-features`, excludes `rust/src/ffi*.rs`, lcov + html, `--fail-under 80`).
- CI: installs cargo-tarpaulin 0.31.3, runs the gate and uploads the `coverage` artifact.
- Dockerfile: the `test` stage runs the same script; the `|| mkdir -p /coverage` that masked failures is gone.
- Unit tests for the memory checkers, LibFuzzer generators/entry point, state/error helpers and the remaining overflow/caller/nondet/memtrack/output branches. Tests that touch process-wide state are serialized by `state::test_lock()`.

## Coverage
- Before: 52.1% (151/290) outside `ffi.rs`, no gate.
- After: <fill in with the number from step 3>% (<covered>/<total>).

Still uncovered on purpose: `__VERIFIER_error`, `__VERIFIER_assert(0)` and `__VERIFIER_assume(0)` terminate the process and are exercised by `tests/ffi_harness.c` instead.
EOF
)"
```
Antes de rodar, troque as duas linhas `<fill in ...>`/`<covered>/<total>` pelo número real do Step 3 (é texto do PR, não do código).

- [ ] **Step 5: Acompanhar o CI do PR**

```bash
gh pr checks --watch -R hbgit/map2check-library feat/issue-25-coverage-gate
gh run list -R hbgit/map2check-library --branch feat/issue-25-coverage-gate --limit 1 --json databaseId --jq '.[0].databaseId' \
  | xargs -I{} gh run view -R hbgit/map2check-library {} --json jobs --jq '.jobs[].steps[]|"\(.conclusion)\t\(.name)"'
```
Esperado: todos os steps `success`, incluindo `Cobertura (cargo-tarpaulin, gate de 80% fora de ffi*.rs)` e `Publicar relatório de cobertura`; o artefato `coverage` aparece em `gh run view <id>`.

- [ ] **Step 6: Fechar a issue depois do merge.** O PR tem como base `feature/rust`, que não é a branch padrão, então o `Resolves #25` **não** fecha a issue automaticamente. Depois que o mantenedor fizer o merge:

```bash
gh issue close 25 -R hbgit/map2check-library \
  --comment "Resolvido pelo PR <número> (mesclado em feature/rust): gate de 80% no CI, artefato 'coverage' publicado, Dockerfile sem '|| mkdir'. Cobertura: <número do Step 3>%."
```

- [ ] **Step 7: Limpar o worktree** (só depois do merge)

```bash
cd /home/rock/Documents/Dev/map2check-library && git worktree remove ../map2check-library-issue25
```
