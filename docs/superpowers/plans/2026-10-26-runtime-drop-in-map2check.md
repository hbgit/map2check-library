# Runtime Rust drop-in para o Map2Check (`develop`) — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer esta biblioteca produzir, a partir de Rust, um substituto direto (drop-in) dos 21 arquivos `.bc` do runtime C que o `develop` atual do Map2Check liga, com os mesmos nomes de arquivo, símbolos, assinaturas e arquivos de resultado, e provar a equivalência por um gate diferencial contra o runtime C, sem alterar nada no Map2Check.

**Architecture:** O frontend do Map2Check (`modules/frontend/caller.cpp`, `Caller::linkLLVM`) faz `llvm-link` de `${MAP2CHECK_PATH}/lib/<Nome>.bc`, compondo o runtime por estrutura de dados, modo, gerador, wasm e witness. A biblioteca passa a exportar a ABI do runtime C (decisão D6, que revoga a D5) e um script empacota a biblioteca como esses 22 módulos de bitcode LLVM 16, no layout decidido pelo spike da Task 1.1 (D7). O teste de integração constrói o Map2Check a partir de uma cópia somente leitura do `develop` em `vendor/map2check/`, instala-o fora da cópia e roda o mesmo binário do frontend duas vezes: com os `.bc` do C e com os `.bc` do Rust sobrepostos na instalação. A troca definitiva no Map2Check é trabalho do mantenedor.

**Tech Stack:** Rust (crate em `rust-toolchain.toml`; bitcode do runtime com rustc 1.72.1/LLVM 16, rota A' da D1), cbindgen, serde_json; Map2Check `develop` em Docker (`vendor/map2check/Dockerfile.dev`: Ubuntu 22.04, LLVM/Clang 16, KLEE 3.1, AFL++ 4.40c); Python 3 para o comparador do gate.

**Spec:** decisões do usuário na sessão de 2026-10-26: (1) recomeçar o cutover do zero, sem usar as alterações antigas no repositório do Map2Check (o merge `a0f8b9cd` do PR #76 saiu do `develop` por force push em 2026-10-22); (2) o agente só modifica este repositório e obtém o Map2Check apenas do branch `develop` ([CLAUDE.md](../../../CLAUDE.md), "Regras obrigatórias"); (3) integração por **drop-in da ABI C**; (4) o código Rust existente é **mantido e revalidado** contra o runtime C do `develop` atual. Este plano substitui [2026-10-15-cutover-runtime-c-map2check.md](2026-10-15-cutover-runtime-c-map2check.md), que fica como registro histórico.

## Global Constraints

- O agente altera somente este repositório. `gh` com efeito remoto, `git push`, tags e releases só com pedido explícito do usuário na mensagem atual.
- O Map2Check vem sempre do branch `develop`, por `git clone --depth 1 --branch develop`, para `vendor/map2check/`; todo `.git` da cópia é removido logo após o download; o commit fica em `vendor/MAP2CHECK_VERSION`; os fontes da cópia nunca são editados. Builds, instalações e saídas ficam em `target/map2check-it/`.
- Se um teste exigir mudança no Map2Check, o agente para e informa o usuário.
- Referência de comportamento: o runtime C em `vendor/map2check/modules/backend/library/` no commit de `vendor/MAP2CHECK_VERSION`. Qualquer diferença observável (veredito, arquivo de resultado, saída) é bug, salvo se registrada como `SD-xx` em `docs/semantic-deltas.md` e aprovada pelo usuário.
- Nomes dos módulos entregues (exatamente os que `caller.cpp` liga): `Map2CheckFunctions TrackBBLog NonDetLog PropertyGenerator ContainerRealloc ContainerBTree BTree AnalysisModeMemtrack AnalysisModeMemcleanup AnalysisModeOverflow AnalysisModeAssert AnalysisModeNone AllocationLog ListLog HeapLog NonDetGeneratorNone NonDetGeneratorKlee NonDetGeneratorAFL WasmRuntimeStubs WitnessGeneration WitnessGenerationNone` + `.bc` (21 arquivos).
- Todo `.bc` entregue é legível por `llvm-dis-16`. O código da biblioteca compila com rustc 1.72.1 (`rust-version = "1.72"`), além da toolchain fixada.
- Sem código C novo na biblioteca. Módulos de seleção ou de cola, se a D7 os exigir, são LLVM IR textual (`.ll`) montado com `llvm-as-16`. Exceção aprovada na D7 (2026-10-26): os módulos de gerador do layout A-fwd contêm lógica de gerador em IR gerado por `scripts/gen_ll.py`, testada como código.
- Desempenho (critérios mantidos do plano anterior, aprovados pelo mantenedor): mediana de `wall_rust / wall_c` ≤ 1,10; mediana da razão de pico de RSS ≤ 1,36; contagem de TIMEOUT por gerador não aumenta.
- Qualidade da biblioteca (CI atual): `cargo fmt --check`, `cargo clippy --all-targets --all-features -- -D warnings`, `cargo test --all-features`, `cargo deny check`, gate de cobertura e `tests/ffi_harness.c` sob ASan/UBSan.
- Commits assinados, sem atribuição de IA. `include/map2check.h` só muda via `build.rs`/`cbindgen.toml`.

## Review Focus

1. **Combinação de link que nenhum teste unitário monta** (por exemplo `--btree` + memcleanup + `afl` + `--wasm`, com e sem `WitnessGeneration.bc`): esperado `llvm-link` sem símbolo duplicado e link nativo sem símbolo indefinido fora da lista permitida do gerador. Teste: `scripts/it/check-link-matrix.sh` sobre as 120 combinações (Task 1.1, reaplicado nas Tasks 3.1 e 4.1).
2. **TRUE sob KLEE:** um runtime que faz chamadas externas ou bifurca caminhos a mais faz o KLEE descartar caminhos, e o frontend (`kleeDroppedPaths()`) rebaixa TRUE para UNKNOWN. Esperado: mesma contagem de `VERIFICATION SUCCEEDED` que o C com `symex`. Teste: `klee_safe_program_drops_no_paths` (Task 2.7) e o gate por gerador (Task 4.1).
3. **Iterações do AFL++ em persistent mode no mesmo processo:** o estado de uma entrada não pode vazar para a seguinte, e a rejeição por `nondet_assume` precisa cancelar só a entrada atual. Teste: `afl_persistent_iterations_start_from_clean_state` (Task 2.8).
4. **Programa sem violação que chama `exit()` no meio, com `--memcleanup-property`:** esperado FALSE-MEMCLEANUP quando há bloco alcançável não liberado, como o C faz no `atexit`. Teste: `memcleanup_reports_leak_at_exit` (Task 2.6).
5. **Largura e sinal dos tipos na ABI** (`long`, `unsigned`, `loff_t`, `sector_t`, ponteiros, `_Bool`): uma assinatura com o nome certo e o tipo errado não dá erro de link, só valor errado. Teste: `tests/abi/check-signatures.sh` (Task 2.0) e o ida-e-volta por tipo `nondet_roundtrip_<tipo>` (Task 2.2).

---

## Ponto de partida (fatos verificados em 2026-10-26)

- `develop` do Map2Check: `3e914528` (9.0, alternância AFL++/KLEE como padrão). O runtime C são 21 `.c` (3 301 linhas) e 13 headers em `modules/backend/library/`, compilados com `clang -c -emit-llvm` e instalados em `lib/`.
- O C exporta 182 símbolos; 8 coincidem em nome com exports atuais da biblioteca (`map2check_init`, `map2check_success`, `map2check_check_deref`, `__VERIFIER_assert`, `__VERIFIER_error`, `map2check_wasm_{check_access,free,malloc}`), nem todos com a mesma assinatura. Os passes citam 47 nomes de função do runtime.
- Cada `AnalysisMode*.c` e cada `NonDetGenerator*.c` define os mesmos símbolos (`analysis_init`, `main`, `map2check_non_det_*`, ...): a escolha é feita por qual `.bc` é ligado.
- `NonDetGeneratorAFL.c` define `main`, lê `__AFL_FUZZ_TESTCASE_BUF` e cancela entradas com `longjmp`; `NonDetGeneratorKlee.c` usa `klee_make_symbolic`/`klee_assume`.
- A biblioteca já tem: rota de bitcode LLVM 16 (`klee/Cargo.toml`, pós-processamento `scripts/klee-*.py`; o `scripts/build-klee-runtime.sh` da rota antiga saiu na Task 2.10, e o build do núcleo drop-in é `scripts/build-runtime-bc.sh`), canal de arquivos legado (`rust/src/output/legacy_files.rs`), modos e memtrack (`rust/src/analysismode/`, `rust/src/memtrack/`), nondet (`rust/src/nondet/`) e wasm (`rust/src/wasm.rs`), escritos para a API núcleo.
- O repositório do Map2Check tem submódulos (`tests/castle/CASTLE-Benchmark`, `tests/juliet/juliet-test-suite-c`); o corpus do gate (`tests/regression_test/test_cases/sv-benchmarks`, 39 `.yml`) não depende deles.

## Decisões

| Id | Decisão | Estado |
|---|---|---|
| D6 | A biblioteca exporta a ABI do runtime C do `develop` (nomes, assinaturas, arquivos de resultado). Revoga a D5. Os exports da API núcleo que colidem ou que nenhum consumidor usa saem do C ABI (versão 2.0.0). | Aprovada pelo usuário em 2026-10-26 |
| D7 | Layout dos 21 módulos `.bc` e tratamento de `main`/`longjmp` do AFL++ e dos intrínsecos KLEE. | Pendente: spike da Task 1.1, **para e pede aprovação** |
| D1 | Bitcode LLVM 16 via rustc 1.72.1 (rota A'), agora para todos os geradores, já que tudo passa por `llvm-link-16`. | Herdada; reconfirmada na Task 1.1 |
| D2, D3 | Wasm portado; `--btree` com o mesmo container do Rust (`ContainerBTree.bc`/`BTree.bc` não mudam o comportamento observável). | Herdadas; registrar no reinício (Task 0.1) |

---

## Fase 0 — Reinício e ambiente de integração

### Task 0.1: Registro do reinício e download reprodutível do Map2Check

**Files:**
- Create: `scripts/fetch-map2check.sh`, `scripts/test-fetch-map2check.sh`
- Modify: `vendor/MAP2CHECK_VERSION` (gerado pelo script), `docs/cutover/decisoes.md` (seção "Reinício de 2026-10-26": force push `a0f8b9cd → fbbcb929`, D5 revogada por D6, D2/D3 mantidas), `TODO.md` (a seção do repositório externo aponta para este plano), `.github/workflows/CI.yml` (roda o teste do script)

**Interfaces:**
- Produces: `scripts/fetch-map2check.sh [--with-submodules] [<dest>]` (padrão `vendor/map2check`); escreve `vendor/MAP2CHECK_VERSION` com as chaves `url branch commit commit_date commit_subject fetched`, uma por linha, `chave=valor`. URL vinda de `MAP2CHECK_URL` (padrão `https://github.com/hbgit/Map2Check`).

- [ ] **Step 1:** Escrever `scripts/test-fetch-map2check.sh`, no estilo de `scripts/test-check-no-c-era-artifacts.sh`, usando um repositório local de fixture (`file://`) com branches `develop` e `other` e um submódulo. Casos: clona `develop` mesmo com `other` como HEAD do remoto; nenhum `.git` (diretório ou arquivo) sobra em `<dest>`; `MAP2CHECK_VERSION` tem as 6 chaves e `commit` igual ao `develop` da fixture; um segundo download substitui o destino; sem `--with-submodules` os submódulos ficam vazios; `<dest>` fora do repositório é recusado.
- [ ] **Step 2:** Rodar o teste e ver falhar (script inexistente).
- [ ] **Step 3:** Implementar o script: `git clone --depth 1 --branch develop [--recurse-submodules --shallow-submodules]`, `rev-parse HEAD` antes de `find <dest> -name .git -prune -exec rm -rf {} +`, escrita atômica do arquivo de versão.
- [ ] **Step 4:** Rodar o teste e ver passar; rodar o script de verdade e conferir `git status --short` (só `vendor/MAP2CHECK_VERSION`).
- [ ] **Step 5:** Escrever a seção do reinício em `decisoes.md` e o ajuste do `TODO.md`; ligar o teste no CI.
- [ ] **Step 6:** Commit `chore: fetch Map2Check develop as an unversioned local copy and record the restart`.

### Task 0.2: Inventário da ABI do runtime C

**Files:**
- Create: `scripts/runtime-abi-inventory.py`, `scripts/test_runtime_abi_inventory.py`, `docs/runtime-abi/inventory.tsv`, `docs/runtime-abi/rust-gap.tsv`

**Interfaces:**
- Produces: `inventory.tsv` com cabeçalho `symbol kind signature module referenced_by`, onde `kind ∈ {func,data}`, `signature` é o protótipo C normalizado pelo clang (`int (int, const char *)`), `module` é o `.bc` que o define (vários separados por `+` quando o C o define em mais de um), `referenced_by ⊆ {pass,frontend,runtime}` separado por `+`. `rust-gap.tsv`: `symbol status rust_signature`, `status ∈ {same,different,missing}`.
- Consumes: `vendor/map2check/` (Task 0.1).

- [ ] **Step 1:** Escrever `test_runtime_abi_inventory.py` (unittest) sobre uma árvore de fixture mínima (dois `.c`, um header, um passe com `getOrInsertFunction("map2check_x", ...)` e uma macro `CALL_IF_HELPER` como em `NonDetPass.cpp:186`): espera as linhas exatas do TSV, inclusive a expansão `map2check_non_det_<c_type>` para cada `c_type` da macro.
- [ ] **Step 2:** Rodar `python3 -I -m unittest scripts/test_runtime_abi_inventory.py` e ver falhar.
- [ ] **Step 3:** Implementar o script: assinaturas por `clang -fsyntax-only -Xclang -ast-dump=json` em cada `.c`; símbolos definidos por `nm` do objeto; referências por literais e macros em `modules/backend/pass/*.cpp` e `modules/frontend/*.cpp`; o gap pelo `nm` de `target/release/libmap2check.a` e pelo `include/map2check.h`.
- [ ] **Step 4:** Rodar o teste e ver passar; gerar os dois TSVs a partir de `vendor/map2check/` e conferir 182 símbolos definidos.
- [ ] **Step 5:** Commit `docs: inventory the C runtime ABI of Map2Check develop`.

### Task 0.3: Build do Map2Check a partir da cópia, sem tocá-la

**Files:**
- Create: `scripts/it/build-map2check.sh`, `scripts/it/Dockerfile.time`, `scripts/it/test-build-map2check.sh`

**Interfaces:**
- Produces: imagem `map2check-dev:develop-<commit12>` (de `vendor/map2check/Dockerfile.dev`) e `map2check-dev:develop-<commit12>-time` (acrescenta `/usr/bin/time`); instalação em `target/map2check-it/c/` (com `bin/map2check` e `lib/*.bc`); `scripts/it/build-map2check.sh [--image-only]`.

- [ ] **Step 1:** Escrever o teste: depois do build, (a) o manifesto `sha256sum` de todos os arquivos de `vendor/map2check/` é igual ao de antes; (b) `target/map2check-it/c/lib/` contém os 21 `.bc` do Global Constraints (o `WasmRuntimeStubs.bc` exige wabt na imagem); (c) `llvm-dis-16` lê cada um.
- [ ] **Step 2:** Rodar e ver falhar.
- [ ] **Step 3:** Implementar: a cópia é montada **somente leitura** (`-v vendor/map2check:/src:ro`), o build vai para `target/map2check-it/build` e o `install` para `target/map2check-it/c`, com os flags do `CLAUDE.md` do Map2Check (`cmake -G Ninja -DLLVM_DIR=/usr/lib/llvm-16/lib/cmake/llvm`).
- [ ] **Step 4:** Rodar e ver passar.
- [ ] **Step 5:** Commit `test: build Map2Check develop from the read-only vendor copy`.

### Task 0.4: Runner do corpus, comparador e linha de base do C

**Files:**
- Create: `scripts/it/run-corpus.sh`, `scripts/it/compare_baselines.py`, `scripts/it/test_compare_baselines.py`, `docs/cutover/deltas-aceitos.tsv` (só o cabeçalho), `docs/cutover/baselines/c-<commit12>.tsv`

**Interfaces:**
- Produces: `run-corpus.sh <install-dir> <out.tsv>` com `REPS` (padrão 5), `GENERATORS` (padrão `afl symex hybrid`; `hybrid` = sem `--nondet-generator`, com `--timeout`), `TIMEOUT_S`; TSV de 11 colunas `task prp gen rep verdict tag line function witness wall_s maxrss_kb`. `compare_baselines.py <c.tsv> <rust.tsv> --deltas docs/cutover/deltas-aceitos.tsv` imprime uma linha por critério e termina com `gate: PASS` ou `gate: FAIL` (exit 0/1). `deltas-aceitos.tsv`: `task prp gen field c_value rust_value sd_ref`.

- [ ] **Step 1:** Escrever `test_compare_baselines.py` com um caso por critério do gate: veredito por moda de 5 repetições; tag/`Line:`/`Function:` iguais em FAILED; witness presente onde o C gerou; contagem de acertos não diminui; divergência aceita só com `sd_ref` existente em `docs/semantic-deltas.md`; mediana `wall` 1,10 passa e 1,11 falha; TIMEOUT a mais falha; mediana RSS 1,36 passa e 1,37 falha; tarefa isolada > 1,5 só gera aviso.
- [ ] **Step 2:** Rodar e ver falhar.
- [ ] **Step 3:** Implementar o comparador e o runner (o runner roda cada tarefa num diretório novo sob `target/map2check-it/runs/`, dentro da imagem `-time`, com a instalação montada somente leitura).
- [ ] **Step 4:** Rodar o teste e ver passar.
- [ ] **Step 5:** Gerar a linha de base do C (`run-corpus.sh target/map2check-it/c ...`) e confirmar que `compare_baselines.py` do C contra ele mesmo dá `gate: PASS`.
- [ ] **Step 6:** Commit `test: corpus runner, gate comparator and C baseline for Map2Check develop`.

---

## Fase 1 — Layout dos módulos (D7) — ponto de parada

### Task 1.1: Spike do layout e matriz de link

**Files:**
- Create: `scripts/it/check-link-matrix.sh`, `scripts/it/test-check-link-matrix.sh`, `docs/cutover/d7-layout.md`; protótipo em `spikes/d7-layout/` (fora do build da crate)

**Interfaces:**
- Produces: `check-link-matrix.sh <lib-dir>`: monta as 120 combinações de `Caller::linkLLVM` (container 2 × modo 5 × gerador 3 × wasm 2 × witness 2) sobre um programa de fumaça, exige `llvm-link-16` sem erro, `llvm-nm-16 --undefined-only` contido na lista permitida do gerador (libc/libm; `klee_*` para `symex`; `__afl_*` para `afl`; `wasm_rt_*` com wasm) e, para `none`/`afl`, link nativo com `clang-16`/`afl-clang-fast`. Saída: uma linha por combinação, `matrix: PASS|FAIL`.

- [ ] **Step 1:** Escrever o teste do script com dois diretórios de fixture: um válido (os `.bc` do C de `target/map2check-it/c/lib`) que dá `matrix: PASS`, e um com um símbolo duplicado entre módulos que dá `FAIL` apontando a combinação.
- [ ] **Step 2:** Implementar `check-link-matrix.sh` e ver o teste passar.
- [ ] **Step 3:** Prototipar as estratégias e medir cada uma com a matriz: **(A)** `Map2CheckFunctions.bc` = runtime Rust inteiro; os módulos de modo/gerador/container/witness são `.ll` que definem globais fortes de seleção sobre padrões fracos do núcleo; referências a `klee_*`/`__afl_*` marcadas `extern_weak` no pós-processamento. **(B)** módulos de gerador como crates Rust `no_std` emitidos como `--crate-type=lib --emit=llvm-bc`, ligados ao núcleo. Para o AFL++, decidir entre `main` + `setjmp`/`longjmp` em `.ll` (o `longjmp` nunca atravessa frames Rust) e um loop sem `longjmp`; medir execuções/s contra o C.
- [ ] **Step 4:** Para a estratégia escolhida: matriz `PASS`; KLEE roda o programa de fumaça seguro com `kleeDroppedPaths() == 0`; o AFL++ executa ≥ 90% das execuções/s do C no mesmo programa.
- [ ] **Step 5:** Registrar em `docs/cutover/d7-layout.md` as medições, a escolha e o mapa `módulo .bc → conteúdo`; commit `docs: D7 module layout spike for the drop-in runtime`.
- [ ] **Step 6:** **Parar e pedir aprovação do usuário para a D7.** As Fases 2 e 3 dependem dela.

---

## Fase 2 — Paridade da ABI (código existente revalidado)

Em todas as tasks desta fase: a semântica de referência é o `.c` citado na cópia `vendor/`; cada função exportada ganha teste Rust que fixa o comportamento lido no C (valores, arquivos escritos, mensagens); o código existente indicado é reaproveitado e adaptado, não reescrito sem motivo; símbolos exportados seguem o mapa da D7; `docs/runtime-abi/pending.txt` perde os símbolos que a task entrega.

### Task 2.0: Guardas de conformidade da ABI

**Files:**
- Create: `tests/abi/check-signatures.sh`, `scripts/runtime-abi-coverage.sh`, `scripts/test-runtime-abi-coverage.sh`, `docs/runtime-abi/pending.txt`
- Modify: `.github/workflows/CI.yml`, `cbindgen.toml` (se precisar de tipos `long`/`unsigned long` nativos, `usize_is_size_t`)

**Interfaces:**
- Produces: `check-signatures.sh <vendor-header-dir>`: para cada header do runtime C, compila com `clang -fsyntax-only -Werror` uma unidade que inclui o header e `include/map2check.h`; tipos conflitantes falham. `runtime-abi-coverage.sh`: falha se o conjunto de símbolos de `inventory.tsv` com `referenced_by` contendo `pass` ou `frontend`, menos os exports da biblioteca, for diferente de `pending.txt` (nem falta nem sobra).

- [ ] **Step 1:** Escrever `test-runtime-abi-coverage.sh` (pendência esquecida falha; símbolo entregue ainda listado falha; igualdade passa).
- [ ] **Step 2:** Implementar os dois scripts; gerar `pending.txt` inicial; ver o teste passar e `check-signatures.sh` passar para os headers cujos símbolos já existem com a mesma assinatura.
- [ ] **Step 3:** Ligar ambos no CI; commit `test: guard the C runtime ABI signatures and coverage`.

### Task 2.1: Núcleo, rastreio de blocos, propriedade e witness

**Files:** referência `Map2CheckFunctions.c`, `TrackBBLog.c`, `PropertyGenerator.c`, `WitnessGeneration.c`, `WitnessGenerationNone.c`; modificar `rust/src/ffi.rs`, `rust/src/state.rs`, `rust/src/bbtrack/mod.rs`, `rust/src/output/legacy_files.rs`; testes em `rust/src/ffi_tests.rs`.

**Interfaces:**
- Produces: os 17 símbolos que `inventory.tsv` atribui a `Map2CheckFunctions.bc` (entre eles `map2check_init`, `map2check_track_bb`, `map2check_assume`, `map2check_target_function`, `map2check_success`, `__VERIFIER_error`), os de `TrackBBLog.bc`, `PropertyGenerator.bc` (`write_property*`) e dos dois módulos de witness (`generate_aux_files`, `generate_confirmation_file`), com as assinaturas do inventário.

- [ ] **Step 1:** Testes: um por função exportada, mais `property_file_matches_c_format` (conteúdo byte a byte de `map2check_property` e `map2check_property_<prp>` igual ao que o C escreve para a mesma chamada, com o texto copiado do C), `track_bb_log_matches_c_format`, e o comportamento do C para arquivos de propriedade de uma execução anterior no mesmo diretório.
- [ ] **Step 2:** Rodar `cargo test --all-features` e ver falhar.
- [ ] **Step 3:** Implementar; nomes da API núcleo que colidem com a ABI C (`map2check_init`, `map2check_success`) passam a ter a assinatura C.
- [ ] **Step 4:** Testes, `check-signatures.sh` e `runtime-abi-coverage.sh` passam.
- [ ] **Step 5:** Commit `feat: export the core functions of the Map2Check C runtime ABI`.

### Task 2.2: Log de nondet e gerador `none`

**Files:** referência `NonDetLog.c`, `NonDetGeneratorNone.c`; modificar `rust/src/nondet/mod.rs`, `rust/src/ffi.rs`.

**Interfaces:**
- Produces: `map2check_nondet_<t>` (log), `map2check_non_det_<t>` e `main` do gerador `none` (segundo a D7), `klee_log.csv` no formato do C, para todos os `<t>` do inventário (incluindo `u8 u16 u32 loff_t sector_t pchar pointer memory`).

- [ ] **Step 1:** Testes `nondet_roundtrip_<t>` (valor extremo de cada largura/sinal registrado e relido igual) e `klee_log_csv_matches_c_format`.
- [ ] **Step 2–4:** ver falhar, implementar, ver passar (com os dois scripts de ABI).
- [ ] **Step 5:** Commit `feat: export the nondet log and the none generator`.

### Task 2.3: Modo overflow

**Files:** referência `AnalysisModeOverflow.c`; modificar `rust/src/analysismode/overflow.rs`, `rust/src/ffi.rs`.

**Interfaces:** Produces: `map2check_binop_{add,sub,mul}[_uint]`, `map2check_binop_sdiv`, `map2check_binop_srem`, `analysis_*` do modo e os demais símbolos que `inventory.tsv` atribui a `AnalysisModeOverflow.bc`.

- [ ] **Step 1:** Testes por operação nos limites (`INT_MAX + 1`, `INT_MIN - 1`, `INT_MIN / -1`, `x % 0`, `UINT_MAX + 1`), com a tag e o texto de propriedade do C.
- [ ] **Step 2–4:** ver falhar, implementar, ver passar.
- [ ] **Step 5:** Commit `feat: export the overflow analysis mode`.

### Task 2.4: Modos assert e none (alcance e cover-branches)

**Files:** referência `AnalysisModeAssert.c`, `AnalysisModeNone.c`; modificar `rust/src/analysismode/assert.rs`, `rust/src/analysismode/mode.rs`, `rust/src/ffi.rs`.

- [ ] **Step 1:** Testes: `map2check_assert`/`__VERIFIER_assert` com 0 e 1; `map2check_target_function` em modo none produz a propriedade de alcance do C; `analysis_is_program_correct` por modo.
- [ ] **Step 2–4:** ver falhar, implementar, ver passar.
- [ ] **Step 5:** Commit `feat: export the assert and none analysis modes`.

### Task 2.5: Modo memtrack, logs de memória e containers

**Files:** referência `AnalysisModeMemtrack.c`, `AllocationLog.c`, `ListLog.c`, `HeapLog.c`, `ContainerRealloc.c`, `ContainerBTree.c`, `BTree.c`; modificar `rust/src/memtrack/mod.rs`, `rust/src/analysismode/memory.rs`, `rust/src/ffi.rs`.

**Interfaces:** Produces: `map2check_{malloc,calloc,realloc,free,free_resolved_address,alloca,add_store_pointer,check_deref,check_cstring,...}` com as assinaturas do inventário; `list_log.csv` no formato do C; `analysis_*` do modo.

- [ ] **Step 1:** Testes portados de cada caminho de veredito do C: deref inválido, free inválido, double free, free de endereço não-heap, `check_cstring` além do bloco, e os formatos de `list_log.csv`; `--btree` e Array dão o mesmo resultado (D3).
- [ ] **Step 2–4:** ver falhar, implementar, ver passar.
- [ ] **Step 5:** Commit `feat: export the memtrack analysis mode`.

### Task 2.6: Modo memcleanup

**Files:** referência `AnalysisModeMemcleanup.c`; modificar `rust/src/analysismode/memory.rs`, `rust/src/ffi.rs`.

- [ ] **Step 1:** Testes: `memcleanup_reports_leak_at_exit` (processo filho chama `exit(0)` com bloco alcançável não liberado; espera FALSE-MEMCLEANUP no arquivo de propriedade) e os demais caminhos do `.c`.
- [ ] **Step 2–4:** ver falhar, implementar, ver passar.
- [ ] **Step 5:** Commit `feat: export the memcleanup analysis mode`.

### Task 2.7: Gerador KLEE

**Files:** referência `NonDetGeneratorKlee.c`; modificar `rust/src/nondet/klee.rs`, `klee/Cargo.toml`, `scripts/build-klee-runtime.sh` (só o que a D7 pedir). (Situação após a Task 2.10: `rust/src/nondet/klee.rs` e `scripts/build-klee-runtime.sh` foram removidos; o gerador KLEE é IR de `scripts/runtime-ir/gen_ll.py`.)

- [ ] **Step 1:** Teste de integração `klee_safe_program_drops_no_paths` (programa seguro com 3 nondet e um laço limitado, ligado pela combinação `symex` da matriz, roda no KLEE da imagem; espera zero caminhos descartados e o mesmo número de testes `.ktest` que o C) e `klee_unsafe_program_reports_same_line`.
- [ ] **Step 2–4:** ver falhar, implementar, ver passar.
- [ ] **Step 5:** Commit `feat: export the KLEE nondet generator`.

### Task 2.8: Gerador AFL++

**Files:** referência `NonDetGeneratorAFL.c`; criar ou modificar o módulo indicado pela D7 (por exemplo `rust/src/nondet/afl.rs` e `rt/afl_main.ll`).

- [ ] **Step 1:** Testes: `afl_persistent_iterations_start_from_clean_state` (duas entradas no mesmo processo; a primeira viola, a segunda não; a segunda não herda a violação); `afl_assume_rejection_cancels_only_current_input`; entrada curta completada como o C completa (zeros).
- [ ] **Step 2–4:** ver falhar, implementar, ver passar; execuções/s ≥ 90% do C no programa de fumaça.
- [ ] **Step 5:** Commit `feat: export the AFL++ nondet generator`.

### Task 2.9: Stubs wasm

**Files:** referência `WasmRuntimeStubs.c`; modificar `rust/src/wasm.rs`.

- [ ] **Step 1:** Testes por stub `wasm_rt_*` e por `map2check_wasm_*` com a assinatura do C.
- [ ] **Step 2–4:** ver falhar, implementar, ver passar.
- [ ] **Step 5:** Commit `feat: export the wasm runtime stubs`.

### Task 2.10: Remover a API núcleo antiga do C ABI

**Files:** `rust/src/ffi.rs`, `tests/ffi_harness.c`, `test/code*_by_caller_test.c`, `docs/api-deltas.md`, `Cargo.toml` (`version = "2.0.0-rc.1"`).

- O núcleo `Map2CheckFunctions.bc` não pode definir `__VERIFIER_assert` nem outro nome que só um módulo de modo define (D7: um programa que define `__VERIFIER_assert` liga nos modos sem assert). A exportação legada em `rust/src/nondet/{libfuzzer,klee}.rs` sai nesta task ou fica fora do build `.bc`; `check-link-matrix.sh --ref` sobre a saída da Task 3.1 é o teste. Com isso, `scripts/runtime-ir/test-assert-none-link.sh` perde o `-Wl,--allow-multiple-definition` e a nota do export legado passa a falhar se o símbolo reaparecer.

- [ ] **Step 1:** Remover os exports da API núcleo que não estão no inventário; reescrever `ffi_harness.c` e os três programas de `test/` contra a ABI C (mesmos cenários de estresse).
- [ ] **Step 2:** `pending.txt` vazio; rodar a suíte completa de qualidade (Global Constraints) e o harness com ASan/UBSan.
- [ ] **Step 3:** Commit `refactor!: the C ABI is the Map2Check runtime ABI only`.

---

## Fase 3 — Empacotamento

### Task 3.1: Os 21 módulos `.bc` e a sobreposição de instalação

**Files:** Create `scripts/build-runtime-bc.sh`, `scripts/it/overlay-install.sh`, `scripts/it/test-overlay-install.sh`; modify `.github/workflows/CI.yml` (job que gera os `.bc` e roda a matriz na imagem `map2check-dev:develop-<commit12>`).

**Interfaces:**
- Produces: `build-runtime-bc.sh <out-dir>` gera exatamente os 21 arquivos do Global Constraints, segundo a D7, de forma determinística (dois builds dão `sha256` iguais). `overlay-install.sh <c-install> <bc-dir> <out-install>` copia a instalação do C e troca só `lib/*.bc`.

- [ ] **Step 1:** Testes: lista de arquivos exata; `llvm-dis-16` lê todos; determinismo; o overlay não altera `bin/`; `check-link-matrix.sh` dá `matrix: PASS` sobre a saída.
  Também: no build `.bc`, o núcleo chama os `generate_aux_files`/`generate_confirmation_file` externos (definidos por `WitnessGeneration.bc` → `__m2c_rt_witness_*`, ou vazios em `WitnessGenerationNone.bc`), em vez de decidir por `config.witness`; teste de que uma execução com witness escreve os arquivos auxiliares exatamente uma vez e sem witness nenhuma vez. Os `map2check_assume*` (adiados da Task 2.1) foram entregues na Task 2.10 pelo IR de cola do núcleo; aqui eles entram no `Map2CheckFunctions.bc` final. O `klee_log.csv` do witness sai só pelo `nondet_generate_aux_witness_files` do gerador ligado, como em `WitnessGeneration.c:26-27`: o `none` não escreve nada, e o KLEE usa os ganchos `__m2c_rt_nondet_log_{len,get_i64,set_i64}` com o limite de 1024 linhas de `NonDetGeneratorKlee.c:33-62`. Teste por gerador. O `map2check_init` do núcleo chama o `analysis_init` externo do módulo de modo ligado e depois o `nondet_init` do gerador, nessa ordem (`Map2CheckFunctions.c:37-38`); teste de que um programa ligado aos `.bc`, sem chamar `analysis_init` à mão, escreve os arquivos de propriedade e aborta em cada modo. Na reexecução de um crash do AFL++ pelo binário de witness, o drop-in escreve `map2check_checked_error` como o C; o caso `afl_crash_replay` de `scripts/runtime-ir/test-afl-generator.sh` passa de informativo a asserção. Também: depois de um `wasm_rt_trap`, o drop-in escreve `map2check_checked_error` como o C (Task 2.9 só verificou `map2check_property__unknown`). Quando os programas de host puderem ligar o `WitnessGeneration.ll`, reavaliar e, se não houver mais uso, remover o export `__m2c_rt_witness_enable` (Task 2.10).
- [ ] **Step 2–4:** ver falhar, implementar, ver passar.
- [ ] **Step 5:** Commit `build: package the runtime as the 21 bitcode modules Map2Check links`.

### Task 3.2: Pacote de release

**Files:** `scripts/package-release.sh`, `scripts/test-package-release.sh`, `docs/release.md`.

- [ ] **Step 1:** Teste: o tarball contém `lib/*.bc` (os 21), `include/map2check.h`, `MAP2CHECK_VERSION` com o commit do `develop` validado e `SHA256SUMS`.
- [ ] **Step 2–4:** ver falhar, implementar, ver passar.
- [ ] **Step 5:** Commit `build: ship the bitcode runtime in the release package`.

---

## Fase 4 — Gate diferencial

### Task 4.1: Primeira execução do gate

- Diferença esperada, fora da paridade: em execuções com violação sob `symex`, a divisão entre caminhos completos e parciais do KLEE pode diferir do C (ordem do searcher com `--exit-on-error-type=Abort`); o total de `.ktest`, o veredito, a linha e a função precisam bater (Task 2.7, `scripts/runtime-ir/test-klee-generator.sh`). Ponto de atenção para o tempo de parede: no programa `assume` da Task 2.8 o AFL++ do drop-in fez 0,899 das exec/s do C (mediana de 5), contra 1,008 no programa de fumaça.

- [ ] **Step 1:** Rodar `run-corpus.sh` na instalação sobreposta (Task 3.1) com os mesmos `REPS`, geradores e imagem da linha de base do C.
- [ ] **Step 2:** `compare_baselines.py` → `gate: PASS`. Cada divergência vira uma task de correção na fase 2 com teste RED/GREEN, ou um `SD-xx` aprovado pelo usuário e listado em `deltas-aceitos.tsv`.
- [ ] **Step 3:** Registrar em `docs/cutover/gate-<data>.md` (commit do `develop`, commit da biblioteca, razões wall/RSS, tarefas > 1,5 com perfil); commit `docs: first differential gate of the drop-in runtime`.

### Task 4.2: Segunda execução consecutiva

- [ ] **Step 1:** Baixar de novo o `develop` (Task 0.1); se o commit mudou, regenerar a linha de base do C nele (Task 0.4, Step 5).
- [ ] **Step 2:** Repetir a Task 4.1 sobre esse commit; exige `gate: PASS`.
- [ ] **Step 3:** Commit `docs: second differential gate of the drop-in runtime`.

---

## Fase 5 — Entrega ao mantenedor

### Task 5.1: Documentação, versão e guia de troca

**Files:** `README.md`, `CLAUDE.md` (seção de arquitetura), `docs/integration-guide.md`, `CHANGELOG.md`, `TODO.md`, `docs/cutover/handoff-map2check.md`.

- [ ] **Step 1:** `integration-guide.md`: como instalar os 21 `.bc` no lugar dos do C (`overlay-install.sh` ou cópia para `${MAP2CHECK_PATH}/lib`), o commit do `develop` validado e como reproduzir o gate. `handoff-map2check.md`: o que o mantenedor precisaria mudar no Map2Check para adotar o pacote (CMake, CI, remoção do C), como sugestão, sem nenhuma ação do agente lá.
- [ ] **Step 2:** `CHANGELOG.md` com a entrada 2.0.0-rc.1 (D6, ABI C, empacotamento, resultado dos dois gates); `README.md`/`CLAUDE.md` deixam de descrever a API núcleo como a interface com o Map2Check; `TODO.md` atualizado.
- [ ] **Step 3:** Commit `docs: hand the drop-in runtime over to the Map2Check maintainer`.
- [ ] **Step 4:** Informar o usuário de que a release (tag `v2.0.0-rc.1`, PR para `develop`/`main`) está pronta; push, PR, tag e release só com pedido explícito.

---

## Execution order

0.1 → 0.2 → 0.3 → 0.4 → **1.1 (D7, aprovação)** → 2.0 → 2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.6 → 2.7 → 2.8 → 2.9 → 2.10 → 3.1 → 3.2 → 4.1 → 4.2 → 5.1.
