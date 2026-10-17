# Relatório de auditoria — plano Rust da map2check-library

- **Data:** 2026-10-14
- **Ref auditada:** `origin/feature/rust` @ `0f28571` (PRs #2 M2 e #3 M3 mesclados). `master` @ `a72f63e` acrescenta só documentação sobre `417441b`.
- **Map2Check (somente leitura):** `develop` @ `f01e8c3`
- **Plano auditado:** `docs/plano_map2check_library_rust.md` (Fase 3, §3.1, §3.4)
- **Checklist:** `audit/checklist.md` · **Evidência bruta:** `audit/evidence/`

## Metodologia

- Comandos rodados num worktree destacado de `0f28571` (o código do usuário não foi alterado): `cargo fmt --check`, `cargo clippy --all-targets --all-features -- -D warnings`, `cargo build --release`, `cargo test` (default, `--features libfuzzer`, `--all-features`), `docker build .` e `docker build --target test` (cobertura tarpaulin extraída de `/coverage/lcov.info`).
- `llvm-nm` não está instalado; usei `nm -g --defined-only` (binutils) em `libmap2check.a`, com e sem `libfuzzer`.
- `cargo-deny`/`cargo-audit` não estão instalados; usei o resultado dos steps no CI (run 38490671308, todos `success`).
- CI, issues, PRs, milestones, labels, proteção de branch e releases coletados via `gh`.
- Regras: nada é `IMPLEMENTADO` sem conteúdo funcional + comando; dúvida → `PARCIAL`; artefato inexistente → `PENDENTE` (nunca `NÃO VERIFICÁVEL`); remoção sem o artefato a remover → `PENDENTE`.

## Resumo por milestone

| Milestone | IMPL | PARC | PEND | N/V | Total |
|---|---|---|---|---|---|
| M1 | 14 | 6 | 3 | 0 | 23 |
| M2 | 10 | 4 | 1 | 0 | 15 |
| M3 | 9 | 4 | 2 | 0 | 15 |
| M4 | 0 | 0 | 12 | 0 | 12 |
| M5 | 0 | 0 | 12 | 0 | 12 |
| M6 | 0 | 2 | 10 | 0 | 12 |
| M7 | 0 | 0 | 12 | 0 | 12 |
| M8 | 0 | 0 | 11 | 0 | 11 |
| G | 0 | 1 | 6 | 0 | 7 |
| **Total** | 33 | 17 | 69 | 0 | 119 |

**Leitura rápida:** M1–M3 estão em grande parte feitos em `feature/rust` (CI verde, fronteira FFI protegida, API núcleo quase completa). As lacunas são cobertura (52,1%), proteção de branch, publicação do header, CHANGELOG e versionamento. De M4 a M8 não há nada implementado: a feature `klee` foi removida, não existe camada compat (33 de 44 símbolos dos passes ausentes), nem testes diferenciais, nem integração no Map2Check.

## M1 — Restaurar build, CI e higiene

| ID | item | status | evidência | issue |
|---|---|---|---|---|
| M1-E1 | `.github/workflows/ci.yml` com build+test+clippy+fmt+deny+tarpaulin | **PARCIAL** — CI.yml tem build/test/clippy/fmt/deny/audit mas não tarpaulin; cobertura só roda no estágio Docker com falha mascarada | CI.yml:24-109; Dockerfile:34-39 (`|| mkdir -p /coverage`) | #25 (coberto por M1-AC8) |
| M1-E2 | `Dockerfile` corrigido | **IMPLEMENTADO** — COPY usa rust/ e test/; build verde local e no CI | Dockerfile:17,30; evidence/docker_build.log rc=0; run 38490671308 step "Build do Dockerfile" |  |
| M1-E3 | `rust-toolchain.toml` | **IMPLEMENTADO** — toolchain 1.82.0 fixado e consistente em README/Dockerfile/CI | rust-toolchain.toml:2; README.md:17; Dockerfile:4; CI.yml:20 |  |
| M1-E4 | `build.rs` gerando `include/map2check.h` | **IMPLEMENTADO** — build.rs gera o header via cbindgen; árvore limpa após build | build.rs:17-22; evidence/build.log rc=0 |  |
| M1-E5 | header commitado como artefato de release | **PARCIAL** — header commitado, mas não há release nem upload de artefato | include/map2check.h; evidence/releases.txt vazio; sem upload-artifact em CI.yml | #16 (comentar) |
| M1-E6 | remoção de `.clangd/`, `compile_commands.json`, `.travis.yml`, `.vscode/` | **IMPLEMENTADO** — nenhum dos artefatos C-era está rastreado | git ls-files @0f28571 sem .clangd/compile_commands.json/.travis.yml/.vscode |  |
| M1-E7 | `README.md` atualizado | **IMPLEMENTADO** — README descreve o build Rust e o toolchain | README.md:17 |  |
| M1-I1 | `ci: add GitHub Actions workflow (build, test, clippy -D warnings, rustfmt, cargo-deny/audit)` | **IMPLEMENTADO** — workflow com build, test, clippy -D warnings, fmt, deny e audit, todos verdes | CI.yml:24-109; run 38490671308 |  |
| M1-I2 | `build: fix Dockerfile COPY paths (rust/src, test) and align base image with MSRV` | **IMPLEMENTADO** — COPY corrigido e imagem alinhada ao MSRV 1.82 | Dockerfile:4,17,30; evidence/docker_build.log rc=0 |  |
| M1-I3 | `build: add rust-toolchain.toml and settle MSRV (README says 1.82, Dockerfile 1.78)` | **IMPLEMENTADO** — rust-toolchain.toml presente e MSRV unificado em 1.82 | rust-toolchain.toml:2; README.md:17; Dockerfile:4 |  |
| M1-I4 | `build: add build.rs generating include/map2check.h via cbindgen; publish header in CI artifacts` | **PARCIAL** — build.rs gera o header, mas o CI não publica o header como artefato | build.rs:17-22; CI.yml sem upload-artifact | #16 (comentar) |
| M1-I5 | `chore: remove C-era dead artifacts (.clangd, compile_commands.json, .travis.yml, .vscode, stale docs)` | **PARCIAL** — artefatos removidos, mas docs C-era (Doxyfile, UML .xmi) continuam | git ls-files docs/: Doxyfile, "C map2checklibrary.xmi", map2checklibrary.xmi | #27 (criada) |
| M1-I6 | `test: make cargo test --all-features green in CI, incl. feature matrix (default, libfuzzer)` | **PARCIAL** — CI roda só --all-features; não há matriz default × libfuzzer para `cargo test` | CI.yml:33-34 (sem `matrix:`); local evidence/test_default.log e test_libfuzzer.log rc=0 | #16 (comentar) |
| M1-AC1 | `cargo build --release` verde no CI | **IMPLEMENTADO** — release build verde local e no CI | evidence/build.log rc=0; run 38490671308 |  |
| M1-AC2 | `cargo test --all-features` verde no CI | **IMPLEMENTADO** — 52 testes passam local e no CI | evidence/test.log rc=0; run 38490671308 |  |
| M1-AC3 | `cargo clippy --all-targets --all-features -- -D warnings` verde no CI | **IMPLEMENTADO** — clippy -D warnings verde local e no CI | evidence/clippy.log rc=0; run 38490671308 |  |
| M1-AC4 | `cargo fmt --check` verde no CI | **IMPLEMENTADO** — fmt --check verde local e no CI | evidence/fmt.log rc=0; run 38490671308 |  |
| M1-AC5 | `cargo deny check` verde no CI | **IMPLEMENTADO** — cargo-deny verde no CI (ferramenta ausente localmente) | CI.yml:98-101; run 38490671308 |  |
| M1-AC6 | `docker build .` conclui | **IMPLEMENTADO** — docker build conclui local e no CI | evidence/docker_build.log rc=0; run 38490671308 |  |
| M1-AC7 | header contém todos os símbolos de `ffi.rs`, checado por `nm`-diff no CI | **PARCIAL** — header contém todos os exports, mas não existe passo de nm-diff no CI | evidence/missing_in_header.txt (só __map2check_main__, que é import); CI.yml sem nm | #13 (comentar) |
| M1-AC8 | cobertura tarpaulin ≥ 70% fora de `ffi.rs` | **PENDENTE** — cobertura medida 52,1% fora de ffi.rs (< 70%) e sem gate | evidence/coverage.txt (151/290 linhas) | #25 (criada) |
| M1-DoD1 | CI verde obrigatório em PR | **PENDENTE** — feature/rust não protegida; master sem required_status_checks | evidence/protection.txt; gh api .../master/protection → checks:null | #26 (coberto por M1-DoD2) |
| M1-DoD2 | branch protegida | **PENDENTE** — feature/rust sem proteção (HTTP 404); só master é protegida | evidence/protection.txt | #26 (criada) |

## M2 — Endurecer a fronteira FFI

| ID | item | status | evidência | issue |
|---|---|---|---|---|
| M2-E1 | `ffi.rs` revisado | **IMPLEMENTADO** — 44/46 exports usam ffi_guard (catch_unwind); os 2 restantes delegam a função protegida ou são cfg(test) | ffi.rs:100-108; libfuzzer.rs:197-206,212,255-259 |  |
| M2-E2 | `state.rs` novo | **IMPLEMENTADO** — estado é static LazyLock<Mutex>, sem OnceLock/Arc | state.rs:14-15 |  |
| M2-E3 | teste de estresse "panic não escapa" (harness C, entradas hostis) | **PARCIAL** — harness hostil existe, mas não chama __VERIFIER_error e o CI tenta 5× para mascarar um SIGSEGV intermitente | tests/ffi_harness.c; CI.yml:36-60 | #8 (comentar) |
| M2-I1 | `ffi: wrap every extern "C" export in catch_unwind with error logging` | **IMPLEMENTADO** — catch_unwind via ffi_guard com log em stderr; panic=abort removido do perfil release | ffi.rs:100-108; Cargo.toml sem `panic` |  |
| M2-I2 | `state: replace OnceLock<Arc<Mutex>> with static Mutex; make init idempotent and NotInitialized unreachable` | **IMPLEMENTADO** — static Mutex; init idempotente; get() sempre Ok (NotInitialized ficou como variante morta) | state.rs:14,57-59,73-75; error.rs:9 |  |
| M2-I3 | `state: add map2check_reset() export clearing containers and result` | **IMPLEMENTADO** — map2check_reset exportado, testado e exercitado pelo harness | ffi.rs:120; evidence/nm_all.txt; state::tests::reset_clears_global_state |  |
| M2-I4 | `fuzzing: remove static mut FUZZER_DATA (AtomicPtr) and reset state per LLVMFuzzerTestOneInput iteration` | **IMPLEMENTADO** — static mut trocado por atômicos; reset do estado a cada iteração | libfuzzer.rs:9-21,30-33 |  |
| M2-I5 | `lint: deny unwrap/expect/panic in non-test code; document reentrancy contract of with_state` | **IMPLEMENTADO** — deny unwrap/expect/panic fora de testes; contrato de reentrância documentado; clippy verde | lib.rs:15-18; state.rs:77-80; evidence/clippy.log rc=0 |  |
| M2-I6 | `test: C harness calling every export pre-init/null/garbage; assert no abort, no UB under ASan+UBSan` | **PARCIAL** — harness ASan+UBSan no CI, mas com retry 5× e sem __VERIFIER_error | CI.yml:50-60; tests/ffi_harness.c | #8 (comentar) |
| M2-AC1 | harness C com `-fsanitize=address,undefined` executa 100% dos exports hostis e retorna 0 | **PARCIAL** — harness retorna 0 no CI só após até 5 tentativas; o critério exige 100% dos exports e execução limpa | CI.yml:36-60; run 38490671308 | #8 (comentar) |
| M2-AC2 | duas iterações de `LLVMFuzzerTestOneInput` com containers idênticos e independentes (teste automatizado) | **PARCIAL** — duas iterações executadas, mas só rc==0 é verificado; containers não são comparados | tests/ffi_harness.c:266-273; test/codefuzz_by_caller_test.c:44-53 | #9 (comentar) |
| M2-AC3 | `grep -R "static mut" rust/src` vazio | **IMPLEMENTADO** — nenhum `static mut` em rust/src; o módulo existe e usa atômicos | grep -R "static mut" rust/src vazio; libfuzzer.rs:9-11 |  |
| M2-AC4 | clippy com lints anti-panic verde | **IMPLEMENTADO** — lints anti-panic ativos e clippy verde | lib.rs:15-18; evidence/clippy.log rc=0 |  |
| M2-DoD1 | todos os exports com comentário SAFETY atualizado | **IMPLEMENTADO** — 20 blocos unsafe, todos com SAFETY; 19 unsafe fn com seção # Safety | rust/src/ffi.rs (script: 0 blocos sem SAFETY) |  |
| M2-DoD2 | CHANGELOG | **PENDENTE** — não existe CHANGELOG | ls CHANGELOG* vazio | #5 (já aberta) |

## M3 — Completar paridade da API núcleo

| ID | item | status | evidência | issue |
|---|---|---|---|---|
| M3-E1 | `ffi.rs` completo | **PARCIAL** — falta next_current_step da §1.2(a), sem justificativa documentada | evidence/missing_core.txt | #13 (comentar) |
| M3-E2 | header regenerado | **IMPLEMENTADO** — header regenerado com todos os exports | evidence/missing_in_header.txt; include/map2check.h |  |
| M3-E3 | testes unitários por símbolo | **PARCIAL** — testes unitários cobrem módulos internos, não cada export; os exports só são exercitados pelo harness C | evidence/test_names.txt (52 testes) | #29 (criada) |
| M3-E4 | `test/*.c` migrados e compilados no CI | **IMPLEMENTADO** — os 3 test/*.c usam a API vigente e rodam no CI | CI.yml:62-96; run 38490671308 |  |
| M3-I1 | `ffi: implement map2check_map_non_static_alloca and map2check_map_funct_address` | **IMPLEMENTADO** — ambos exportados e exercitados; semântica registrada | evidence/nm_all.txt; docs/api-deltas.md:43 |  |
| M3-I2 | `ffi: implement map2check_check_free_resolved_address` | **PARCIAL** — exportado e testado, mas a escolha semântica vs. AnalysisModeMemtrack.c não está registrada | evidence/nm_all.txt; memtrack::tests::*free_resolved*; docs/api-deltas.md sem seção | #13 (comentar) |
| M3-I3 | `ffi: wire set_null_is_valid/set_memcleanup flags into state and LoadChecker` | **IMPLEMENTADO** — flags gravadas no estado e lidas por check_load/check_mem_endprog; há teste | state.rs:23-26; ffi.rs:234,252,916,1035; analysismode::memory::tests::null_load_obeys_null_valid_flag |  |
| M3-I4 | `ffi: add map2check_fuzzer_assume, __VERIFIER_assume/assert/error, missing __VERIFIER_nondet_* variants` | **IMPLEMENTADO** — fuzzer_assume, __VERIFIER_assume/assert/error e nondet_{pointer,bool,uchar} exportados e testados | evidence/nm_libfuzzer.txt; nondet::libfuzzer::tests::* |  |
| M3-I5 | `ffi: fix char ABI (i8 vs u8) in nondet log and generators` | **IMPLEMENTADO** — char usa c_char (i8), com decisão registrada | ffi.rs:283-284; docs/api-deltas.md:65 |  |
| M3-I6 | `test: port test/code*_by_caller_test.c to current API; build+run them in CI against libmap2check.a` | **IMPLEMENTADO** — test/*.c portados e executados no CI | CI.yml:62-96; run 38490671308 |  |
| M3-AC1 | diff `nm` vs §1.2(a) sem "Ausente" injustificado; exceções em `docs/api-deltas.md` | **PARCIAL** — só next_current_step ausente, sem exceção documentada; diff nm não roda no CI | evidence/missing_core.txt; docs/api-deltas.md | #13 (comentar) |
| M3-AC2 | os 3 programas de `test/` compilam, linkam e passam no CI | **IMPLEMENTADO** — os 3 programas compilam, linkam e passam no CI | CI.yml:62-96; run 38490671308 |  |
| M3-AC3 | cobertura ≥ 75% | **PENDENTE** — cobertura 52,1% (< 75%) | evidence/coverage.txt | #25 (coberto por M1-AC8) |
| M3-DoD1 | header versionado `v1.0.0-rc1` | **PENDENTE** — nenhum v1.0.0-rc1 em header, Cargo ou tags | Cargo.toml:4 (1.0.0); evidence/tags.txt | #28 (criada) |
| M3-DoD2 | nenhuma função stub silenciosa | **IMPLEMENTADO** — nenhum export com corpo vazio; o único stub (__map2check_main__) é cfg(test) | script de corpo vazio em ffi.rs → 0; libfuzzer.rs:255-259 |  |

## M4 — Spike KLEE (gate go/no-go)

| ID | item | status | evidência | issue |
|---|---|---|---|---|
| M4-E1 | `nondet/klee.rs` | **PENDENTE** — artefato inexistente | evidence/m4_m5_m6_checks.log; Cargo.toml [features] só libfuzzer | #20 (já aberta) |
| M4-E2 | `cfg(feature="klee")` em `state`/`output` | **PENDENTE** — feature klee nem existe mais no Cargo.toml; nenhum cfg(feature="klee") | evidence/m4_m5_m6_checks.log; Cargo.toml [features] só libfuzzer | #20 (já aberta) |
| M4-E3 | `scripts/build_klee_bc.sh` | **PENDENTE** — artefato inexistente | evidence/m4_m5_m6_checks.log; Cargo.toml [features] só libfuzzer | #20 (já aberta) |
| M4-E4 | `docs/klee-feasibility.md` com go/no-go | **PENDENTE** — artefato inexistente | evidence/m4_m5_m6_checks.log; Cargo.toml [features] só libfuzzer | #20 (já aberta) |
| M4-I1 | `klee: implement nondet generator via klee_make_symbolic (feature-gated)` | **PENDENTE** — artefato inexistente | evidence/m4_m5_m6_checks.log; Cargo.toml [features] só libfuzzer | #20 (já aberta) |
| M4-I2 | `klee: single-thread state cell and no-serde JSON path under feature klee` | **PENDENTE** — artefato inexistente | evidence/m4_m5_m6_checks.log; Cargo.toml [features] só libfuzzer | #20 (já aberta) |
| M4-I3 | `klee: pin Rust toolchain with KLEE-3.1-compatible LLVM; script emitting linked libmap2check_klee.bc` | **PENDENTE** — artefato inexistente | evidence/m4_m5_m6_checks.log; Cargo.toml [features] só libfuzzer | #20 (já aberta) |
| M4-I4 | `klee: rewrite run_klee_test.sh for post-CMake layout; e2e with codeklee reference program in CI (dockerized klee)` | **PENDENTE** — run_klee_test.sh foi removido; CI só faz smoke test sem KLEE | evidence/m4_m5_m6_checks.log; Cargo.toml [features] só libfuzzer; CI.yml:86 | #17 (já aberta) |
| M4-I5 | `docs: klee feasibility report incl. fallback decision (keep C lib for KLEE flow)` | **PENDENTE** — artefato inexistente | evidence/m4_m5_m6_checks.log; Cargo.toml [features] só libfuzzer | #20 (já aberta) |
| M4-AC1 | KLEE 3.1 roda `codeklee_by_caller_test` até o fim, ≥ 1 `.ktest` + resultado; ou relatório com causa-raiz e contingência §2.3 | **PENDENTE** — nem execução KLEE nem relatório de viabilidade | evidence/m4_m5_m6_checks.log; Cargo.toml [features] só libfuzzer | #20 (já aberta) |
| M4-AC2 | tempo KLEE ≤ 2× biblioteca C, medido e registrado | **PENDENTE** — sem medição registrada | evidence/m4_m5_m6_checks.log; Cargo.toml [features] só libfuzzer | #20 (já aberta) |
| M4-DoD1 | decisão go/no-go registrada e refletida no roadmap | **PENDENTE** — sem decisão go/no-go registrada | evidence/m4_m5_m6_checks.log; Cargo.toml [features] só libfuzzer | #20 (já aberta) |

## M5 — Camada de compatibilidade com passes do Map2Check

| ID | item | status | evidência | issue |
|---|---|---|---|---|
| M5-E1 | `rust/src/ffi_compat.rs` + feature `m2c-compat` (default on) | **PENDENTE** — artefato inexistente | evidence/missing_compat.txt; evidence/m4_m5_m6_checks.log | #21 (já aberta) |
| M5-E2 | golden files dos arquivos-sentinela | **PENDENTE** — artefato inexistente | evidence/missing_compat.txt; evidence/m4_m5_m6_checks.log | #19 (já aberta) |
| M5-E3 | `docs/compat-matrix.md` | **PENDENTE** — artefato inexistente | evidence/missing_compat.txt; evidence/m4_m5_m6_checks.log | #21 (já aberta) |
| M5-I1 | `compat: export map2check_init(i32), track_bb, alloca, non_static_alloca, malloc, calloc, free, free_resolved_address with pass-declared signatures` | **PENDENTE** — camada compat inexistente; 33/44 símbolos de §1.2(b) ausentes | evidence/missing_compat.txt; evidence/m4_m5_m6_checks.log | #21 (já aberta) |
| M5-I2 | `compat: export map2check_load(ptr,i64), add_store_pointer, function, target_function, posix; resolve check_deref name collision (core → map2check_check_deref_v2)` | **PENDENTE** — camada compat inexistente; 33/44 símbolos de §1.2(b) ausentes | evidence/missing_compat.txt; evidence/m4_m5_m6_checks.log | #21 (já aberta) |
| M5-I3 | `compat: export assume/assume_loop/crab_assume/assert and map2check_non_det_* / nondet_cast_* / pointer_cast family` | **PENDENTE** — camada compat inexistente; 33/44 símbolos de §1.2(b) ausentes | evidence/missing_compat.txt; evidence/m4_m5_m6_checks.log | #21 (já aberta) |
| M5-I4 | `compat: write map2check_property_{unknown,free,deref,assert,...} sentinel files matching tools.cpp regexes` | **PENDENTE** — nenhuma escrita de map2check_property_* | grep map2check_property_ rust/src vazio | #19 (já aberta) |
| M5-I5 | `test: golden tests comparing sentinel files/JSON against legacy embedded C library outputs` | **PENDENTE** — artefato inexistente | evidence/missing_compat.txt; evidence/m4_m5_m6_checks.log | #19 (já aberta) |
| M5-AC1 | `llvm-nm libmap2check.a` contém 100% da §1.2(b) (script no CI; lista em `compat-matrix.md`) | **PENDENTE** — camada compat inexistente; 33/44 símbolos de §1.2(b) ausentes | evidence/missing_compat.txt; evidence/m4_m5_m6_checks.log | #21 (já aberta) |
| M5-AC2 | 5 programas de referência: sentinelas aceitos pelo parser de `tools.cpp`, idênticos ao legado | **PENDENTE** — artefato inexistente | evidence/missing_compat.txt; evidence/m4_m5_m6_checks.log | #19 (já aberta) |
| M5-DoD1 | matriz de compat sem lacunas | **PENDENTE** — camada compat inexistente; 33/44 símbolos de §1.2(b) ausentes | evidence/missing_compat.txt; evidence/m4_m5_m6_checks.log | #21 (já aberta) |
| M5-DoD2 | header compat separado gerado | **PENDENTE** — artefato inexistente | evidence/missing_compat.txt; evidence/m4_m5_m6_checks.log | #21 (já aberta) |

## M6 — Testes diferenciais e desempenho

| ID | item | status | evidência | issue |
|---|---|---|---|---|
| M6-E1 | `tests/differential/` + workflow noturno | **PENDENTE** — artefato inexistente (sem harness diferencial, benchmark, semantic-deltas.md ou workflow agendado) | evidence/m4_m5_m6_checks.log | #15 (já aberta) |
| M6-E2 | `docs/semantic-deltas.md` | **PENDENTE** — artefato inexistente (sem harness diferencial, benchmark, semantic-deltas.md ou workflow agendado) | evidence/m4_m5_m6_checks.log | #5 (já aberta) |
| M6-E3 | relatório de benchmark | **PENDENTE** — artefato inexistente (sem harness diferencial, benchmark, semantic-deltas.md ou workflow agendado) | evidence/m4_m5_m6_checks.log | #18 (já aberta) |
| M6-I1 | `test: differential harness linking same instrumented .bc against C and Rust runtimes; verdict/property/line diff` | **PENDENTE** — artefato inexistente (sem harness diferencial, benchmark, semantic-deltas.md ou workflow agendado) | evidence/m4_m5_m6_checks.log | #15 (já aberta) |
| M6-I4 | `perf: hyperfine benchmark over 10 reference programs (LibFuzzer fixed corpus, -runs=N); optimize hot path if >10% regression (Mutex, String copies)` | **PENDENTE** — artefato inexistente (sem harness diferencial, benchmark, semantic-deltas.md ou workflow agendado) | evidence/m4_m5_m6_checks.log | #18 (já aberta) |
| M6-I5 | `ci: nightly differential + perf job with regression gate` | **PENDENTE** — artefato inexistente (sem harness diferencial, benchmark, semantic-deltas.md ou workflow agendado) | evidence/m4_m5_m6_checks.log | #18 (já aberta) |
| M6-AC1 | 0 divergências não adjudicadas (≥ 30 programas) | **PENDENTE** — artefato inexistente (sem harness diferencial, benchmark, semantic-deltas.md ou workflow agendado) | evidence/m4_m5_m6_checks.log | #15 (já aberta) |
| M6-AC2 | overhead mediano ≤ 110% do C (excedente com perfil) | **PENDENTE** — artefato inexistente (sem harness diferencial, benchmark, semantic-deltas.md ou workflow agendado) | evidence/m4_m5_m6_checks.log | #18 (já aberta) |
| M6-AC3 | job noturno ativo | **PENDENTE** — artefato inexistente (sem harness diferencial, benchmark, semantic-deltas.md ou workflow agendado) | evidence/m4_m5_m6_checks.log | #18 (já aberta) |
| M6-DoD1 | `semantic-deltas.md` aprovado pelo mantenedor | **PENDENTE** — artefato inexistente (sem harness diferencial, benchmark, semantic-deltas.md ou workflow agendado) | evidence/m4_m5_m6_checks.log | #5 (já aberta) |
| M6-I2 | `memtrack: adjudicate is_invalid_address semantics vs container_memtracklog.c (inverted logic, var_addr vs points_to)` | **PARCIAL** — is_invalid_address foi reescrito e testado, mas a adjudicação vs. container_memtracklog.c não foi documentada | memtrack/mod.rs:102; memtrack::tests::invalid_address_*; sem docs/semantic-deltas.md | #11 (comentar) |
| M6-I3 | `memtrack: adjudicate is_deref_error and has_memcleanup_error vs legacy` | **PARCIAL** — is_deref_error passou a considerar points_to (teste), mas a adjudicação não foi documentada e has_memcleanup_error não foi revisado | memtrack/mod.rs:124-138; memtrack::tests::deref_resolves_allocation_through_stored_pointer | #15 (comentar) |

## M7 — Integração no CMake do Map2Check sob flag

| ID | item | status | evidência | issue |
|---|---|---|---|---|
| M7-E1 | PR no `hbgit/Map2Check` (branch `feature/rust-runtime`) (evidência em hbgit/Map2Check) | **PENDENTE** — Map2Check@develop sem opção MAP2CHECK_RUST_RUNTIME, branch feature/rust-runtime ou PR | Map2Check f01e8c3: CMakeLists.txt/.github sem RUST_RUNTIME/corrosion; branches e PRs listados | #22 (já aberta) |
| M7-E2 | workflow atualizado (evidência em hbgit/Map2Check) | **PENDENTE** — Map2Check@develop sem opção MAP2CHECK_RUST_RUNTIME, branch feature/rust-runtime ou PR | Map2Check f01e8c3: CMakeLists.txt/.github sem RUST_RUNTIME/corrosion; branches e PRs listados | #22 (já aberta) |
| M7-E3 | doc de build (evidência em hbgit/Map2Check) | **PENDENTE** — Map2Check@develop sem opção MAP2CHECK_RUST_RUNTIME, branch feature/rust-runtime ou PR | Map2Check f01e8c3: CMakeLists.txt/.github sem RUST_RUNTIME/corrosion; branches e PRs listados | #5 (já aberta) |
| M7-I1 | `cmake: add MAP2CHECK_RUST_RUNTIME option fetching/building map2check-library via Corrosion` (evidência em hbgit/Map2Check) | **PENDENTE** — Map2Check@develop sem opção MAP2CHECK_RUST_RUNTIME, branch feature/rust-runtime ou PR | Map2Check f01e8c3: CMakeLists.txt/.github sem RUST_RUNTIME/corrosion; branches e PRs listados | #22 (já aberta) |
| M7-I2 | `frontend: teach linkLLVM()/executeAnalysis to link Rust staticlib (native flows) and Rust BC ou fallback C (KLEE flow per M4 decision)` (evidência em hbgit/Map2Check) | **PENDENTE** — Map2Check@develop sem opção MAP2CHECK_RUST_RUNTIME, branch feature/rust-runtime ou PR | Map2Check f01e8c3: CMakeLists.txt/.github sem RUST_RUNTIME/corrosion; branches e PRs listados | #22 (já aberta) |
| M7-I3 | `ci(Map2Check): matrix job running unit + small regression set with both runtimes` (evidência em hbgit/Map2Check) | **PENDENTE** — Map2Check@develop sem opção MAP2CHECK_RUST_RUNTIME, branch feature/rust-runtime ou PR | Map2Check f01e8c3: CMakeLists.txt/.github sem RUST_RUNTIME/corrosion; branches e PRs listados | #22 (já aberta) |
| M7-I4 | `docs: build and adoption guide for the Rust runtime flag` (evidência em hbgit/Map2Check) | **PENDENTE** — Map2Check@develop sem opção MAP2CHECK_RUST_RUNTIME, branch feature/rust-runtime ou PR | Map2Check f01e8c3: CMakeLists.txt/.github sem RUST_RUNTIME/corrosion; branches e PRs listados | #5 (já aberta) |
| M7-AC1 | `cmake .. -DMAP2CHECK_RUST_RUNTIME=ON && ninja` verde em `Dockerfile.dev` (evidência em hbgit/Map2Check) | **PENDENTE** — Map2Check@develop sem opção MAP2CHECK_RUST_RUNTIME, branch feature/rust-runtime ou PR | Map2Check f01e8c3: CMakeLists.txt/.github sem RUST_RUNTIME/corrosion; branches e PRs listados | #22 (já aberta) |
| M7-AC2 | paridade de vereditos 100% em `make-regression-test.sh t` (evidência em hbgit/Map2Check) | **PENDENTE** — Map2Check@develop sem opção MAP2CHECK_RUST_RUNTIME, branch feature/rust-runtime ou PR | Map2Check f01e8c3: CMakeLists.txt/.github sem RUST_RUNTIME/corrosion; branches e PRs listados | #22 (já aberta) |
| M7-AC3 | tempo da suíte Rust ≤ 110% da C (evidência em hbgit/Map2Check) | **PENDENTE** — Map2Check@develop sem opção MAP2CHECK_RUST_RUNTIME, branch feature/rust-runtime ou PR | Map2Check f01e8c3: CMakeLists.txt/.github sem RUST_RUNTIME/corrosion; branches e PRs listados | #18 (já aberta) |
| M7-DoD1 | PR aberto e revisável (evidência em hbgit/Map2Check) | **PENDENTE** — Map2Check@develop sem opção MAP2CHECK_RUST_RUNTIME, branch feature/rust-runtime ou PR | Map2Check f01e8c3: CMakeLists.txt/.github sem RUST_RUNTIME/corrosion; branches e PRs listados | #22 (já aberta) |
| M7-DoD2 | flag documentada (evidência em hbgit/Map2Check) | **PENDENTE** — Map2Check@develop sem opção MAP2CHECK_RUST_RUNTIME, branch feature/rust-runtime ou PR | Map2Check f01e8c3: CMakeLists.txt/.github sem RUST_RUNTIME/corrosion; branches e PRs listados | #22 (já aberta) |

## M8 — Promoção a default e aposentadoria do compat

| ID | item | status | evidência | issue |
|---|---|---|---|---|
| M8-I1 | `map2check: flip MAP2CHECK_RUST_RUNTIME default to ON after one green regression cycle` (evidência em hbgit/Map2Check) | **PENDENTE** — depende de M5/M7 inexistentes (remoção vacuosa não conta, regra 4) | Map2Check f01e8c3; evidence/m4_m5_m6_checks.log | #24 (já aberta) |
| M8-I2 | `passes: migrate MemoryTrackPass to core API (map2check_map_*, check_* v2)` (evidência em hbgit/Map2Check) | **PENDENTE** — depende de M5/M7 inexistentes (remoção vacuosa não conta, regra 4) | Map2Check f01e8c3; evidence/m4_m5_m6_checks.log | #23 (já aberta) |
| M8-I3 | `passes: migrate NonDetPass/TrackBasicBlockPass/AssertPass/OverflowPass/LoopPredAssumePass to core API` (evidência em hbgit/Map2Check) | **PENDENTE** — depende de M5/M7 inexistentes (remoção vacuosa não conta, regra 4) | Map2Check f01e8c3; evidence/m4_m5_m6_checks.log | #23 (já aberta) |
| M8-I4 | `frontend: consume JSON result instead of sentinel files (keep files behind legacy flag for 1 release)` (evidência em hbgit/Map2Check) | **PENDENTE** — depende de M5/M7 inexistentes (remoção vacuosa não conta, regra 4) | Map2Check f01e8c3; evidence/m4_m5_m6_checks.log | #23 (já aberta) |
| M8-I5 | `library: remove ffi_compat.rs and sentinel writer; bump to v2.0.0` (evidência em hbgit/Map2Check) | **PENDENTE** — depende de M5/M7 inexistentes (remoção vacuosa não conta, regra 4) | Map2Check f01e8c3; evidence/m4_m5_m6_checks.log | #23 (já aberta) |
| M8-I6 | `map2check: delete embedded C library after full regression parity` (evidência em hbgit/Map2Check) | **PENDENTE** — depende de M5/M7 inexistentes (remoção vacuosa não conta, regra 4) | Map2Check f01e8c3; evidence/m4_m5_m6_checks.log | #23 (já aberta) |
| M8-AC1 | regressão completa + run Test-Comp-like com 0 regressões vs. baseline C (evidência em hbgit/Map2Check) | **PENDENTE** — depende de M5/M7 inexistentes (remoção vacuosa não conta, regra 4) | Map2Check f01e8c3; evidence/m4_m5_m6_checks.log | #24 (já aberta) |
| M8-AC2 | compat e biblioteca C removidas sem `U map2check_*` órfão (evidência em hbgit/Map2Check) | **PENDENTE** — depende de M5/M7 inexistentes (remoção vacuosa não conta, regra 4) | Map2Check f01e8c3; evidence/m4_m5_m6_checks.log | #23 (já aberta) |
| M8-DoD1 | `feature/rust` mesclada (evidência em hbgit/Map2Check) | **PENDENTE** — feature/rust não está mesclada em master (master contém só docs extras sobre 417441b) | git rev-list a72f63e...0f28571 → 6/13 | #24 (já aberta) |
| M8-DoD2 | release taggeada nos dois repositórios (evidência em hbgit/Map2Check) | **PENDENTE** — sem release na biblioteca; Map2Check v8.1.1 não inclui runtime Rust | evidence/releases.txt; gh release list hbgit/Map2Check | #24 (já aberta) |
| M8-DoD3 | CHANGELOG e docs (evidência em hbgit/Map2Check) | **PENDENTE** — sem CHANGELOG na biblioteca | ls CHANGELOG* vazio | #5 (já aberta) |

## Critério global de "pronto" (§3.4)

| G | critério | atendido? | status | evidência |
|---|---|---|---|---|
| G-1 | CI da biblioteca verde (build, testes, lints, deny/audit, cobertura ≥ 80% fora de `ffi*.rs`) com toolchain fixado. | não | **PENDENTE** — CI verde e toolchain fixado, mas cobertura 52,1% < 80% e sem gate | evidence/coverage.txt; run 38490671308 |
| G-2 | `llvm-nm libmap2check.a` cobre 100% dos símbolos exigidos pelos passes do Map2Check alvo (matriz do M5) e 100% da API núcleo documentada no header `cbindgen` versionado. | não | **PENDENTE** — compat 33/44 ausentes; next_current_step ausente; header sem versão | evidence/missing_compat.txt; evidence/missing_core.txt |
| G-3 | Suíte diferencial: 0 divergências de veredito não adjudicadas contra a baseline C no conjunto de regressão do Map2Check; toda divergência restante documentada como correção intencional com fixture. | não | **PENDENTE** — sem suíte diferencial | M6-* |
| G-4 | `Map2Check` compila e passa a regressão completa com `-DMAP2CHECK_RUST_RUNTIME=ON` nos modos None e LibFuzzer, e no modo KLEE conforme a decisão registrada do M4 (bitcode Rust **ou** contingência documentada mantendo o runtime C apenas para KLEE — neste caso o "pronto" é qualificado e o débito fica rastreado em issue aberta). | não | **PENDENTE** — Map2Check sem flag Rust; sem decisão KLEE | M7-*, M4-* |
| G-5 | Overhead de execução instrumentada ≤ 110% da baseline C (mediana no benchmark do M6); excedentes quantificados e aceitos explicitamente pelo mantenedor. | não | **PENDENTE** — sem benchmark | M6-AC2 |
| G-6 | Nenhum `panic`/abort atravessando a FFI no harness hostil do M2 sob ASan/UBSan. | não | **PARCIAL** — harness hostil roda sob ASan/UBSan, mas com retry que mascara SIGSEGV intermitente | M2-AC1; CI.yml:36-60 |
| G-7 | Documentação: header C publicado, guia de build/integração, `semantic-deltas.md`, `klee-feasibility.md`, CHANGELOG e release taggeada. | não | **PENDENTE** — header versionado sem release; faltam guia de integração, semantic-deltas.md, klee-feasibility.md, CHANGELOG e tag | M1-E5, M7-I4, M6-E2, M4-E4, M2-DoD2 |

**0 de 7 critérios atendidos.** G-6 (sem panic sob ASan/UBSan) é o mais próximo: falta tirar o retry do CI. Os demais dependem de M4–M8.

## Matriz de rastreabilidade (§3.1)

| Lacuna/risco | itens | status agregado |
|---|---|---|
| R1 semântica divergente memtrack | M6-I2, M6-I3 | PARCIAL |
| R2 integração inexistente | M5-E1 … M8-DoD3 (35) | PENDENTE |
| R3 KLEE inviável | M4-E1 … M4-DoD1 (12) | PENDENTE |
| R4 panic na FFI | M2-I1, M2-I5 | IMPLEMENTADO |
| R5 reentrância fuzzing / static mut | M2-I3, M2-I4 | IMPLEMENTADO |
| R6 Mutex no hot path | M2-I2, M6-I4 | PARCIAL |
| R7 build/CI, build.rs, MSRV | M1-I1 … M4-I4 (7) | PARCIAL |
| R8 ABI menor | M3-I5, M5-I1, M5-I2, M5-I3 | PARCIAL |
| R9 artefatos mortos | M1-I5 | PARCIAL |
| R10 sem testes e2e | M3-I6, M5-I5, M6-I1, M7-I3 | PARCIAL |
| Stubs set_memcleanup/set_null_is_valid | M3-I3 | IMPLEMENTADO |
| Feature klee vazia | M4-I1, M4-I2, M4-I3 | PENDENTE |
| Símbolos ausentes API núcleo | M3-I1, M3-I2, M3-I3, M3-I4 | PARCIAL |
| Canal de resultado (arquivos vs JSON) | M5-I4, M8-I4 | PENDENTE |

## Itens NÃO VERIFICÁVEIS

Nenhum. Os itens que exigiriam KLEE, benchmark ou a regressão do Map2Check não têm nem o artefato a verificar (harness, script, flag), então ficaram `PENDENTE`.

## Observações fora do checklist

- O CI esconde com um retry de 5× um SIGSEGV intermitente em binários linkados com ASan (CI.yml:36-49). Isso enfraquece M2-AC1/G-6 e deveria ser investigado.
- O `tarpaulin` no Dockerfile termina em `|| mkdir -p /coverage`, então uma falha de cobertura nunca quebra o build.
- O branch local `feature/rust` (`0d60baf`) está desatualizado em relação a `origin/feature/rust` (`0f28571`).
- Já existem 20 issues abertas (#5–#24), derivadas do TODO.md, sem milestone e sem labels do plano. Vários itens pendentes já estão cobertos por elas (ver `audit/issues_propostas.md`).
