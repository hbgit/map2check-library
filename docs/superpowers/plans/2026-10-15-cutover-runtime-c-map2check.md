# Cutover do runtime C do Map2Check para a biblioteca Rust — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir o runtime C do Map2Check (`hbgit/Map2Check:modules/backend/library`) pela biblioteca Rust deste repositório (`libmap2check`) e remover o runtime C, sem regressão de veredito nem de desempenho e com rollback possível até um ponto de não-retorno explícito.

**Architecture:** O runtime C (`develop` do Map2Check, `f01e8c3e`) são 21 arquivos `.c` compilados para `.bc` (LLVM 16). O frontend (`modules/frontend/caller.cpp:550`, `Caller::linkLLVM`) os liga ao programa instrumentado com `llvm-link`, escolhendo o conjunto por modo (memtrack, memcleanup, overflow, assert, reachability, cover-branches), por gerador (none, KLEE, AFL++), por estrutura de dados (Array ou BTree) e por wasm. A biblioteca Rust passa a ser o único runtime. A biblioteca só exporta a sua API núcleo, sem camada de compatibilidade (D5). Primeiro ela ganha paridade funcional. Depois, numa branch do Map2Check, os passes LLVM passam a emitir diretamente a API núcleo e o frontend passa a ligar `libmap2check.a` (migração direta, sem ABI dupla). A branch é validada contra o C por testes diferenciais e mergeada num único merge commit, revertível. Só depois de um ciclo de release o C é removido.

**Tech Stack:** Rust 1.82 (LLVM 19), cbindgen 0.26, serde_json; Map2Check (`develop`): C++17, CMake, LLVM/Clang 16, KLEE (z3/stp), AFL++ 4.40c (persistent mode, PCGUARD), wabt 1.0.41, benchexec.

**Spec:** a mensagem do usuário que pediu este plano (cutover para Rust apenas), mais as respostas da sessão de 2026-10-15: **escopo = runtime C do Map2Check**; **programas C de teste da ABI deste repositório ficam como testes**; **D5: sem camada de compatibilidade** e **migração direta dos passes, sem tabela de ABI dupla** (decisões do usuário). Requisitos de paridade de referência: [TODO.md](../../../TODO.md), issues #6–#24 e #36–#38, [docs/api-deltas.md](../../api-deltas.md) e [docs/semantic-deltas.md](../../semantic-deltas.md).

## Global Constraints

- Nada em C é removido sem equivalente Rust validado pelo gate diferencial (Task 4.2) no fluxo correspondente.
- Nenhuma funcionalidade é declarada obsoleta sem uma justificativa registrada em `docs/cutover/decisoes.md`, com evidência e aprovação explícita do mantenedor.
- Passos pequenos e reversíveis: até a Fase 3, `develop` do Map2Check não muda de runtime; da Task 5.1 até o ponto de não-retorno (Fase 6), voltar ao C é um `git revert -m 1` do merge.
- Regressão de desempenho máxima aceitável: **10% na mediana** do tempo de parede por tarefa (TODO.md, "Medir e controlar a regressão de desempenho").
- Alvo no Map2Check: branch **`develop`** (`f01e8c3e` em 2026-10-15; 173 commits à frente de `master`). Números de linha citados neste plano referem-se a `develop`, salvo indicação.
- Toolchain do Map2Check: **LLVM/Clang 16** e **AFL++ 4.40c** (`Dockerfile.dev`). Geradores aceitos pelo CLI: `afl` e `symex` (`modules/frontend/map2check.cpp:929`). Toolchain deste repositório: **Rust 1.82.0 com LLVM 19.1.1** (`rust-toolchain.toml`).
- Commits com assinatura verificada; tags de preservação assinadas (`git tag -s`).
- Sem atribuição de IA em commits, PRs ou issues ([CLAUDE.md](../../../CLAUDE.md)).
- O header `include/map2check.h` é gerado por `build.rs`; nunca editá-lo à mão.
- **Sem camada de compatibilidade (D5):** a biblioteca Rust não exporta os nomes nem as assinaturas do runtime C. Nada de feature `compat`, módulo `compat.rs` ou aliases. Quem se adapta são os passes do Map2Check.
- **Migração direta:** os passes emitem só a API núcleo; não há tabela de ABI C nem opção de build para voltar ao C. O rollback até a Fase 6 é `git revert -m 1` do merge de `feat/rust-runtime` (Task 5.1).
- Branch de integração: `develop` nos dois repositórios (aqui, `main` é a branch de release). No Map2Check o padrão local é `master`; o PR vai contra `develop`.

## Review Focus

1. **Tarefa que gera `VERIFICATION SUCCEEDED`:** no inventário feito em `master`, só o caminho KLEE (`--nondet-generator symex`) prova TRUE (`master:modules/frontend/map2check.cpp:270-285`); a Task 0.2 confirmou 4 SUCCEEDED com `symex` em `develop`. Se o runtime Rust não rodar sob KLEE, toda tarefa TRUE vira silêncio ou UNKNOWN. Esperado: a mesma contagem de TRUE que o C. O teste está na Task 4.2 (o gate exige paridade por gerador, incluindo `symex`).
2. **Duas execuções no mesmo diretório de trabalho:** o runtime C sobrescreve `map2check_property`, mas deixa arquivos antigos de propriedade (`map2check_property_free`, ...) que o frontend lê em ordem fixa (`tools.cpp:114-204`). Esperado: o veredito depende só da execução atual. O teste está na Task 2.4 (`stale_property_files_are_removed_on_init`).
3. **Iterações sucessivas do AFL++ em persistent mode no mesmo processo:** o estado de uma entrada contamina a seguinte. Esperado: cada iteração (`__AFL_LOOP` ou `LLVMFuzzerTestOneInput` via driver) parte do estado zerado. O teste está na Task 2.1 (#9).
4. **Programa sem violação que chama `exit()` no meio, com `--memcleanup-property`:** o C verifica vazamento no `atexit`. Esperado: FALSE-MEMCLEANUP quando há bloco alcançável não liberado. O teste está na Task 2.2 (`memcleanup_reports_leak_at_exit`).
5. **Arquivo `.bc` Rust ligado com `llvm-link-16`:** bitcode do LLVM 19 não é lido pelo LLVM 16 ("Unknown attribute kind" / "Invalid record"). Esperado: o build falha alto e cedo, não na hora da verificação. O teste está na Task 1.1 (spike) e na Task 3.1 (o CMake falha se o artefato não for legível por `llvm-dis-16`).

---

## 0. Achados que corrigem a premissa do pedido

> **Revisão de 2026-10-15 (durante a execução):** o inventário original foi feito sobre o `master` local do Map2Check (`83471fba`). O alvo é `develop` (`f01e8c3e`), que trocou LibFuzzer por **AFL++** (`NonDetGeneratorAFL.c` substitui `NonDetGeneratorLibFuzzy.c`; CLI `afl|symex`), acrescentou `--slice`, o modo `COVER_BRANCHES_MODE` e o símbolo `map2check_binop_srem`, e reduziu o runtime a 21 arquivos `.c` (3 039 linhas). As seções abaixo já refletem `develop`.

- **Neste repositório já não há C legado.** A implementação C/C++ foi removida em `f1cbcfe` (84 arquivos, 8 083 linhas), e a remoção já está em `develop` e em `main`. O último commit com o C é `f4c43b5`. A tag `archive/memory_check` aponta para um commit de 2021 e **não** preserva esse estado. O que resta em C são três programas consumidores da ABI (`test/code*_by_caller_test.c`) e o harness `tests/ffi_harness.c`. Por decisão do usuário, eles **ficam** como testes.
- **O runtime C ainda em uso está no Map2Check**, em `modules/backend/library` (`develop`: 21 `.c` com 3 039 linhas, 13 headers). Ele não é a mesma API desta biblioteca: os nomes divergem (`map2check_binop_add` × `map2check_binop_add_int`, `map2check_assert` × `map2check_is_valid_assert`, `map2check_malloc` × `map2check_map_malloc`, `map2check_non_det_int` × `__VERIFIER_nondet_int`). Dos nomes `map2check_*` que aparecem nos passes, cerca de 30 não existem no header Rust. A lista `audit/evidence/missing_compat.txt` dá 33, mas está inflada: `map2check_pointer_cast` (`OverflowPass.cpp:255`) e `map2check_nondet_cast_<t>` (`NonDetPass.cpp:167`) são só nomes de valores do IR (`Twine` de instruções de cast), não chamadas ao runtime. Recalcular na Task 0.3, porque a evidência é de `Map2Check@f01e8c3` e o `master` local está em `83471fba`. Como não haverá camada de compatibilidade (D5), essa diferença se resolve mudando o que os passes emitem (Task 3.2), não a biblioteca.
- **O runtime é ligado como bitcode, não como `.a`.** `caller.cpp:550-641` faz `llvm-link` de `.bc` no programa instrumentado, e esse `.bc` final vai para `afl-clang-fast` (`caller.cpp:395-440`, binários `-fuzzed.out` e `-cmplog.out`) ou para o KLEE (`caller.cpp:729`). O rustc 1.82 emite bitcode LLVM 19, que o `llvm-link-16` não lê. **Esse é o bloqueio técnico central** (Fase 1).
- **O runtime C é composto por modo na hora do link.** Cada `AnalysisMode*.c` define os mesmos símbolos (`analysis_init`, `map2check_malloc`, ...), e o frontend escolhe qual `.bc` ligar. Uma biblioteca Rust única precisa selecionar o modo em tempo de execução.
- **O canal de resultado é por arquivos, não JSON.** O frontend lê `map2check_property`, `map2check_property_{free,deref,assert,overflow,memtrack,memcleanup,unknown}`, `list_log.csv`, `klee_log.csv`, `track_bb_log.st` e `map2check_checked_error` (`tools.hpp:43-54`, `tools.cpp:114-204`, `caller.cpp:44`).
- **Gerador de fuzzing divergente:** a biblioteca Rust implementa o gerador para **LibFuzzer** (`LLVMFuzzerTestOneInput`, `rust/src/nondet/libfuzzer.rs`), mas `develop` usa **AFL++ em persistent mode**: `NonDetGeneratorAFL.c` define o `main`, lê os bytes de `__AFL_FUZZ_TESTCASE_BUF` e cancela entradas com `longjmp` em `nondet_assume`. Há dois caminhos: ligar o harness LibFuzzer da biblioteca ao driver libFuzzer do AFL++ (`afl-clang-fast -fsanitize=fuzzer`) ou portar o loop persistente para Rust. A escolha entra na D1.
- **Rust → C via FFI:** o único `extern "C"` importado é `__map2check_main__` (`rust/src/nondet/libfuzzer.rs:44`), o `main` renomeado do programa analisado. Não é código C legado, então **permanece por design**. Se o KLEE for adotado, entram também `klee_make_symbolic` e `klee_assume`, que são intrínsecos do KLEE e também permanecem. A libc chega via `std` (malloc, exit), e isso é aceitável. Não há C próprio chamado pelo Rust a eliminar.

## 1. Mapa de paridade

Status: **(a)** portado · **(b)** parcial · **(c)** não portado · **(d)** candidato a obsoleto (sujeito à decisão registrada). Esforço: **P** ≤ 1 dia · **M** 2–4 dias · **G** 1–2 semanas · **GG** > 2 semanas. Responsável: o repositório não registra equipe além do mantenedor (Herbert Rocha); a coluna "Ordem" dá a sequência e o mantenedor atribui pessoas ao aprovar o plano.

| # | Módulo C (Map2Check `modules/backend/library/lib/`) | Equivalente Rust | Status | Esforço | Depende de | Ordem (Task) |
|---|---|---|---|---|---|---|
| 1 | `Map2CheckFunctions.c`: init(isSvComp), passo, assume, `crab_assume`, `assume_loop`, `track_bb`, `__VERIFIER_error`, `target_function`, success/error/destroy/exit | `ffi.rs` (init, success, passo, assume, `__VERIFIER_error`) | b | M | 2.3 (modo), 3.2 (passes) | 2.3, 2.5, 3.2 |
| 2 | `AnalysisModeAssert.c` | `analysismode/assert.rs` | b (nomes/assinatura: muda o passe) | P | 3.2 | 3.2 |
| 3 | `AnalysisModeOverflow.c` (add/sub/mul/sdiv/**srem** int e uint) | `analysismode/overflow.rs` | b (nomes: muda o passe; `sdiv` → `div_int`; `srem` sem equivalente → export novo) | P–M | 2.5, 3.2 | 2.5, 3.2 |
| 4 | `AnalysisModeMemtrack.c` + `AllocationLog.c` + `ListLog.c` + `HeapLog.c` | `memtrack/`, `analysismode/memory.rs` | b (bugs #11, #36, #37, #38; CSVs) | G | 2.1 | 2.1, 2.4 |
| 5 | `AnalysisModeMemcleanup.c` | stub `map2check_set_memcleanup` | c (#10) | M | 2.1 | 2.2 |
| 6 | `AnalysisModeNone.c` (modos none e `COVER_BRANCHES_MODE`, `caller.cpp:604-609`) | — | c (trivial) | P | 2.3 | 2.3 |
| 7 | `ContainerRealloc.c` | `Vec<T>` em `AnalysisState` | a (por design) | P (verificar) | — | 4.2 |
| 8 | `ContainerBTree.c` + `BTree.c` (persistência em `*.map2check.bin`; opção `--btree`, marcada "experimental") | — | d? (decisão D3) | P se justificado; M se portado | 4.3 | 2.6 |
| 9 | `NonDetLog.c` → `klee_log.csv` | `nondet/mod.rs` (JSON) | b (formato) | M | 2.4 | 2.4 |
| 10 | `NonDetGeneratorNone.c` | `__VERIFIER_nondet_*` sem feature | b | P | 2.5, 3.2 | 2.5 |
| 11 | `NonDetGeneratorAFL.c` (AFL++ persistent mode: `main`, buffer de bytes, `longjmp` em `assume`) | `nondet/libfuzzer.rs` (LibFuzzer) | c (outro motor: decidir na D1 entre driver libFuzzer do AFL++ ou port do loop) | M–G | 1.1 (D1) | 2.5 |
| 12 | `NonDetGeneratorKlee.c` (`klee_make_symbolic`, `klee_assume`) | — (feature `klee` removida do `Cargo.toml`) | c (#20) | G–GG | **1.1 (bloqueante)** | 2.7 |
| 13 | `PropertyGenerator.c` → `map2check_property*` | `output/` (só JSON) | c (#19) | M | 2.3 | 2.4 |
| 14 | `TrackBBLog.c` → `track_bb_log.st` | `bbtrack/` | b (formato) | M | 2.4 | 2.4 |
| 15 | `WitnessGeneration.c` / `WitnessGenerationNone.c` → `map2check_checked_error` | — | c | M | 2.4 | 2.4 |
| 16 | `WasmRuntimeStubs.c` (`wasm_rt_*`) + `map2check_wasm_{malloc,free,check_access}` | — | c (decisão D2) | M | 1.1, 2.5 | 2.8 |
| 17 | `header/*.h` (13 headers) | `include/map2check.h` gerado | a (gerado) | P | 2.5 | 6.2 |
| 18 | `tests/unit/backend-library/*.cpp` (gtest: AllocationLog, BTree, Container, HeapLog, MemTrack) | `ffi_tests.rs` + testes de módulo | b (portar asserções) | P–M | 2.1, 2.6 | 5.2 |
| 20 | Passes LLVM: nomes e assinaturas das chamadas de runtime (`modules/backend/pass/*.cpp`) | — (C++, permanece) | c (emitem a ABI C) | G | 2.5 | 3.2 |
| 19 | `map2check_posix` (marcado `__attribute_deprecated__`, `AnalysisModeMemtrack.c:327`, mas ainda chamado por `MemoryTrackPass.cpp:120` para `posix_memalign`) | — (vira `map2check_map_posix_memalign`) | c (não é obsoleto: há chamador) | P | 2.5 | 2.5 |

Itens fora deste repositório que **continuam em C++** por decisão de escopo: os passes LLVM (`modules/backend/pass`) e o frontend (`modules/frontend`). Eles mudam no necessário para ligar o runtime Rust e para emitir a API núcleo (Tasks 3.2 e 3.3).

## 2. Decisões (as pendentes bloqueiam as tarefas indicadas)

| ID | Decisão | Opções | Recomendação | Bloqueia |
|---|---|---|---|---|
| D1 | Como o runtime Rust entra no pipeline LLVM 16 (e como o AFL++ dirige as entradas) | (A) emitir bitcode legível pelo LLVM 16; (B) ligar `libmap2check.a` nativo no passo final do `afl-clang-fast`, sem `llvm-link`; (C) migrar o Map2Check para LLVM 19. Para o AFL++: (B1) harness `LLVMFuzzerTestOneInput` da biblioteca + driver libFuzzer do AFL++; (B2) port do loop persistente (`__AFL_LOOP`) para Rust | **B** para None/AFL++, com B1 se o spike mostrar throughput ≥ 90% do C; para KLEE, só o spike decide (A ou C). B não depende da versão do LLVM, porque o objeto é nativo. | 1.2, 2.5, 2.7, 3.x |
| D2 | O modo `--wasm` entra no cutover? | portar os stubs para Rust; ou manter fora do escopo | Portar. O CI do Map2Check tem o job `e2e-wasm` ativo (`ci.yml:213`), então não há base para declará-lo obsoleto. | 2.8 |
| D3 | A opção `--btree` (disco) | portar; ou remover com justificativa | Medir antes (Task 4.3). Se o RSS do Rust nos casos grandes ficar ≤ o RSS do C com `--btree`, remover e registrar a justificativa. | 2.6 |
| D4 | Limite de memória (pico de RSS) | — | ≤ 1,25× o C na mediana. O TODO só fixa o limite de tempo; este valor precisa de aprovação. | 4.2 |
| D5 | A ABI final que os passes emitem | **Decidida em 2026-10-15: sem camada de compatibilidade.** Os passes migram diretamente para a API núcleo, sem ABI dupla (#23 entra no cutover); a #21 fecha como "won't do". | — | 0.3, 2.5, 3.2 |

## 3. Critérios de aceitação do cutover

Os critérios são medidos pelo gate da Task 4.2 sobre o corpus `tests/regression_test/test_cases/sv-benchmarks` (39 tarefas `.yml`), em cada combinação **propriedade × gerador** (`fuzzer`, `symex`), com 5 repetições, na mesma imagem `Dockerfile.dev` e na mesma máquina.

**Funcionais (qualquer violação bloqueia):**
1. O veredito (`SUCCEEDED`/`FAILED`/`UNKNOWN`) é igual ao do C em todas as tarefas, por moda das 5 repetições.
2. Para FAILED, a primeira linha de `map2check_property` (tag), `Line:` e `Function:` são iguais.
3. Onde o C gerou `map2check_checked_error` ou witness, o Rust também gera.
4. A contagem de tarefas com `expected_verdict` correto não diminui.
5. Qualquer divergência só passa se estiver listada em `docs/cutover/deltas-aceitos.tsv` com a referência de um item `SD-xx` em `docs/semantic-deltas.md` que a classifique como "bug do C corrigido", com caso reproduzível.

**Desempenho:**
6. A mediana, entre tarefas, da razão `wall_rust / wall_c` é ≤ 1,10. **Bloqueia.**
7. A contagem de TIMEOUT por gerador não aumenta. **Bloqueia.**
8. A mediana da razão de pico de RSS é ≤ 1,25 (D4). **Bloqueia** depois de aprovado; antes disso, só alerta.
9. Uma tarefa isolada com razão > 1,5 não bloqueia se os critérios 6 e 7 passarem, mas exige perfil registrado em `docs/cutover/perf.md`.

**Qualidade da biblioteca (já existentes; continuam obrigatórios):** `cargo test --all-features`, `cargo clippy -- -D warnings`, `cargo fmt --check`, `cargo deny check`, gate de cobertura e `tests/ffi_harness.c` sob ASan/UBSan sem achados.

**Prontidão (#24):** os critérios 1–8 passam em **duas** execuções completas consecutivas do gate, separadas por pelo menos um merge em `develop` do Map2Check, antes do merge da Task 5.1 e de novo antes da Fase 6.

## 4. Arquivos e diretórios

### A remover (só na Fase 6, no Map2Check)

| Caminho | Pré-condição |
|---|---|
| `modules/backend/library/lib/*.c`, `lib/BTree.h`, `lib/NOTE.txt`, `lib/CMakeLists.txt` | Task 5.1 concluída (um ciclo de release sem revert); o código já está fora do build desde a Task 3.1 |
| `modules/backend/library/header/*.h` | nenhum `#include` restante (`grep -r 'backend/library/header'`) |
| `modules/backend/library/CMakeLists.txt`, `NOTES.txt` | idem |
| `tests/unit/backend-library/` | asserções portadas (Task 5.2); já fora do `ctest` desde a Task 3.4 |
| referências restantes ao runtime C em configs de análise (`.cppcheck-suppressions.txt`, `.clang-tidy`) | Task 6.3 |

### A manter

| Caminho | Motivo |
|---|---|
| Neste repo: `rust/`, `tests/*.rs`, `build.rs`, `cbindgen.toml`, `include/map2check.h` | a implementação |
| Neste repo: `test/code{API,fuzz,klee}_by_caller_test.c`, `tests/ffi_harness.c` | testes de ABI do ponto de vista de um compilador C (decisão do usuário) |
| Neste repo: `audit/`, `docs/plano_map2check_library_rust.md` | histórico/evidência; atualizar links quebrados (Task 6.4) |
| Map2Check: `modules/backend/pass/`, `modules/frontend/` | fora do escopo (C++, não runtime) |
| Map2Check: `tests/regression_test/`, `tests/integration/` | corpus do gate diferencial |

## 5. Riscos e mitigações

| Risco | Evidência | Mitigação | Task |
|---|---|---|---|
| Bitcode LLVM 19 ilegível pelo `llvm-link-16` | `rustc -vV` → LLVM 19.1.1; Map2Check usa LLVM 16 | spike com 3 rotas e critério objetivo; o CMake verifica com `llvm-dis-16` | 1.1, 3.1 |
| KLEE não executa um runtime com `std` (TLS, `Mutex`, unwinding, alocador) | o runtime C atual é C puro, sem libc pesada | o spike mede uma variante `no_std + alloc` com panic=abort; sem ela, sem cutover do `symex` | 1.1, 2.7 |
| Sem KLEE, nenhuma tarefa TRUE é provada | `map2check.cpp:270-285` | o KLEE é condição de cutover, não opcional (Review Focus 1) | 4.2 |
| Typo implícito: o C grava `map2check_property__unknown` (dois `_`), mas o frontend lê `map2check_property_unknown` | `PropertyGenerator.c:16`, `tools.cpp:114` | reproduzir o comportamento observável (o frontend nunca vê UNKNOWN por esse arquivo) e registrar como SD; não "consertar" no cutover | 2.4 |
| Arquivos de propriedade antigos no diretório de trabalho mudam o veredito | o C só sobrescreve os que escreve | limpar no `init`; o caller usa um diretório por hash, mas o teste garante isso | 2.4 |
| O estado do C é por arquivo `.bc` (globais estáticos por modo); o Rust tem um estado único | `caller.cpp:254-312` | `map2check_set_mode()` antes de `map2check_init`; teste de exclusão mútua | 2.3 |
| `isSvComp` de `map2check_init(int)` mudaria o comportamento | `Map2CheckFunctions.c:29-36`: `sv_comp` é gravado e nunca lido em `library/lib` | argumento morto; o passe deixa de passá-lo; justificativa registrada em `abi-mapping.tsv` e em `docs/cutover/decisoes.md` | 0.3, 3.2 |
| A ordem de avaliação no `atexit` (memcleanup) difere | `AnalysisModeMemcleanup.c` | teste com `exit()` no meio do programa | 2.2 |
| Assinaturas divergentes entre as ABIs (`map2check_load(ptr, i64)` × `map2check_check_load(ptr, line, scope, size, fn)`, `map2check_nondet_<t>` × `map2check_save_nondet_log_<t>`, `map2check_check_deref`) | `MemoryTrackPass.cpp:739`, `NonDetFunctions.hpp:46`, TODO.md | o passe emite a assinatura núcleo; `verifyModule` + teste de IR por hook + teste de link; argumento errado no IR não dá erro de link, só comportamento errado, por isso o gate 4.2 é obrigatório | 3.2, 4.2 |
| Sem ABI dupla, não há rollback por flag: depois do merge, voltar ao C exige revert | migração direta | trabalho isolado em `feat/rust-runtime`; merge único com merge commit; gate 4.2 duas vezes antes do merge; revert ensaiado no PR (Task 5.1); a branch é rebaseada semanalmente para que o revert continue limpo | 3.x, 5.1 |
| Um passe chama função inexistente na biblioteca: o `clang` final só falha com `undefined reference` na hora da verificação | — | gate `symbol-matrix.sh` + `core_api_coverage` + teste de link ponta a ponta no CI do Map2Check | 0.3, 2.5, 3.2 |
| Símbolos duplicados se C e Rust forem ligados juntos | os dois definem `__VERIFIER_*` | o build deixa de compilar/instalar os `.bc` C; o teste da Task 3.1 falha se algum for instalado | 3.1 |
| Dependências externas: wabt 1.0.41 em `/opt`, klee-uclibc compilado com clang-16, AFL++ 4.40c, solvers z3/stp/btor/yices2 | `Dockerfile.dev`; a imagem local de julho não tem AFL++ nem `/usr/bin/time` | gate numa imagem reconstruída do `Dockerfile.dev` de `develop` (`map2check-dev:cutover-f01e8c3e`) + toolchain Rust instalada nela; versões fixadas | 0.2, 3.4 |
| O motor de fuzzing muda de semântica (LibFuzzer × AFL++: rejeição por `longjmp`, ciclo de bytes, `cmplog`) | `NonDetGeneratorAFL.c`, `caller.cpp:418-440` | o spike mede caminhos e throughput nas variantes B1/B2 antes de decidir; gate 4.2 por gerador `afl` | 1.1, 4.2 |
| Diferença de alocador/endereços muda contraexemplos textuais | endereços aparecem na saída | o gate compara campos normalizados, não o texto | 4.1 |
| Unwinding atravessando a FFI | #8 | `panic = "abort"` no perfil de runtime | 2.1 |

---

## Fase 0 — Preservação e linha de base (totalmente reversível)

### Task 0.1: Tags de preservação do legado

**Files:** nenhum arquivo; cria tags nos dois repositórios.

**Interfaces:**
- Produces: tags `legacy/c-library-final` (este repo) e `legacy/c-runtime-final` (Map2Check), mais a branch `legacy/c-runtime` (Map2Check), que são os pontos de rollback citados nas Fases 5 e 6.

- [ ] **Step 1: Confirmar o último commit com o C neste repositório**

Run: `git -C ~/Documents/Dev/map2check-library ls-tree -r --name-only f1cbcfe^ | grep -cE '^(src|include|lib|old_src)/'`
Expected: um número > 0. `f1cbcfe^` é `f4c43b5`.

- [ ] **Step 2: Criar e publicar a tag assinada aqui**

```bash
cd ~/Documents/Dev/map2check-library
git tag -s legacy/c-library-final f1cbcfe^ -m "Última revisão com a implementação C da map2check-library (antes de f1cbcfe)"
git push origin legacy/c-library-final
```

- [ ] **Step 3: Criar a tag e a branch no Map2Check, no topo de `develop`**

```bash
cd ~/Documents/Dev/Map2Check
git fetch origin
git tag -s legacy/c-runtime-final origin/develop -m "Última revisão com o runtime C em modules/backend/library"
git branch legacy/c-runtime origin/develop
git push origin legacy/c-runtime-final legacy/c-runtime
```

- [ ] **Step 4: Verificar**

Run: `git -C ~/Documents/Dev/Map2Check ls-remote --tags origin legacy/c-runtime-final && git -C ~/Documents/Dev/map2check-library tag -v legacy/c-library-final`
Expected: a tag aparece no remoto e `tag -v` mostra "Good signature".

**Critério de conclusão:** as duas tags assinadas e a branch existem no remoto. A tag do Map2Check será movida (`-f`) na Task 6.1 para o último commit antes da remoção, e esse movimento fica registrado no PR.

### Task 0.2: Runner de corpus e linha de base do C

**Files:**
- Create (Map2Check): `scripts/cutover/run-corpus.sh`
- Create (Map2Check): `scripts/cutover/test-run-corpus.sh`
- Create (Map2Check): `tests/cutover/baseline-c.tsv` (gerado)

**Interfaces:**
- Produces: `run-corpus.sh <map2check-release-dir> <out.tsv>`, com as variáveis `GENS` (padrão `"afl symex"`), `REPS` (padrão `5`) e `TIMEOUT` (padrão `45`). Gera um TSV com o cabeçalho exato `task	prp	gen	rep	verdict	tag	line	function	witness	wall_s	maxrss_kb`, consumido pela Task 4.1.

- [ ] **Step 1: Escrever o teste do runner com um `map2check` falso**

```bash
#!/usr/bin/env bash
# Testa run-corpus.sh com um binário falso e um corpus de uma tarefa.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/cases/x"
cat > "$T/bin/map2check" <<'EOF'
#!/usr/bin/env bash
printf 'FALSE-DEREF\nLine: 7\nFunction: main\n' > map2check_property
echo "VERIFICATION FAILED"
EOF
chmod +x "$T/bin/map2check"
printf 'int main(){}\n' > "$T/cases/x/a.c"
cat > "$T/cases/x/a.yml" <<'EOF'
format_version: '1.0'
input_files: 'a.c'
properties:
  - property_file: ../properties/valid-memsafety.prp
    expected_verdict: false
EOF
CASES="$T/cases" GENS=fuzzer REPS=1 "$HERE/run-corpus.sh" "$T/bin" "$T/out.tsv"
row="$(sed -n 2p "$T/out.tsv")"
IFS=$'\t' read -r task prp gen rep verdict tag line func witness wall rss <<<"$row"
[ "$task" = "x/a.yml" ] && [ "$prp" = "valid-memsafety" ] && [ "$gen" = fuzzer ] \
  && [ "$verdict" = FAILED ] && [ "$tag" = FALSE-DEREF ] && [ "$line" = 7 ] \
  && [ "$func" = main ] && [ "$witness" = 0 ] || { echo "linha inesperada: $row" >&2; exit 1; }
echo ok
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `bash scripts/cutover/test-run-corpus.sh`
Expected: FAIL com "No such file or directory" (o runner ainda não existe).

- [ ] **Step 3: Implementar o runner**

```bash
#!/usr/bin/env bash
# Executa o corpus de regressão e grava, por tarefa/propriedade/gerador/repetição,
# o veredito, a tag de map2check_property, linha, função, witness, tempo e RSS.
# Uso: run-corpus.sh <dir-com-map2check> <saida.tsv>
set -euo pipefail
BIN_DIR="$(cd "$1" && pwd)"; OUT="$2"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CASES="${CASES:-$ROOT/tests/regression_test/test_cases/sv-benchmarks}"
GENS="${GENS:-afl symex}"; REPS="${REPS:-5}"; TIMEOUT="${TIMEOUT:-45}"

flags_for() {
  case "$1" in
    valid-memsafety) echo "--memtrack" ;;
    valid-memcleanup) echo "--memtrack --memcleanup-property" ;;
    no-overflow) echo "--check-overflow" ;;
    unreach-call) echo "--target-function" ;;
    *) return 1 ;;
  esac
}

printf 'task\tprp\tgen\trep\tverdict\ttag\tline\tfunction\twitness\twall_s\tmaxrss_kb\n' > "$OUT"
while IFS= read -r yml; do
  dir="$(dirname "$yml")"
  input="$dir/$(sed -nE "s/^input_files: *'?([^' ]+)'?.*/\1/p" "$yml")"
  while IFS= read -r prp; do
    flags="$(flags_for "$prp")" || continue
    for gen in $GENS; do
      for rep in $(seq 1 "$REPS"); do
        work="$(mktemp -d)"
        # shellcheck disable=SC2086
        ( cd "$work" && /usr/bin/time -f '%e\t%M' -o time.txt \
            timeout "$TIMEOUT" "$BIN_DIR/map2check" --nondet-generator "$gen" $flags "$input" \
            > out.txt 2>&1 ) || true
        verdict=TIMEOUT
        grep -q 'VERIFICATION SUCCEEDED' "$work/out.txt" && verdict=SUCCEEDED
        grep -q 'VERIFICATION FAILED' "$work/out.txt" && verdict=FAILED
        grep -q 'VERIFICATION UNKNOWN' "$work/out.txt" && verdict=UNKNOWN
        tag=-; line=-; func=-
        if [ -f "$work/map2check_property" ]; then
          tag="$(sed -n 1p "$work/map2check_property")"
          line="$(sed -nE 's/^Line: *//p' "$work/map2check_property" | head -1)"; line="${line:--}"
          func="$(sed -nE 's/^Function: *//p' "$work/map2check_property" | head -1)"; func="${func:--}"
        fi
        witness=0; ls "$work"/*.graphml "$work"/map2check_checked_error >/dev/null 2>&1 && witness=1
        timing="$(tail -1 "$work/time.txt" 2>/dev/null || printf -- '-\t-')"
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
          "${yml#"$CASES"/}" "$prp" "$gen" "$rep" "$verdict" "$tag" "$line" "$func" "$witness" "$timing" >> "$OUT"
        rm -rf "$work"
      done
    done
  done < <(sed -nE 's#.*property_file: *.*/([a-z-]+)\.prp.*#\1#p' "$yml")
done < <(find "$CASES" -name '*.yml' | sort)
```

- [ ] **Step 4: Rodar o teste**

Run: `bash scripts/cutover/test-run-corpus.sh`
Expected: `ok`

- [ ] **Step 5: Gerar a linha de base do C na imagem `Dockerfile.dev`**

```bash
docker build -f Dockerfile.dev -t map2check-dev .
docker run --rm -v "$PWD":/src -w /src map2check-dev \
  bash -c 'cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j && cmake --install build --prefix release && scripts/cutover/run-corpus.sh release/bin tests/cutover/baseline-c.tsv'
```

Expected: `tests/cutover/baseline-c.tsv` com cabeçalho + (tarefas×propriedades suportadas×2×5) linhas. Anotar em `tests/cutover/README.md` o hash do commit do Map2Check, o `docker image inspect --format '{{.Id}}'` e a CPU da máquina.

- [ ] **Step 6: Commit (Map2Check)**

```bash
git add scripts/cutover tests/cutover
git commit -S -m "test: add regression corpus runner and C runtime baseline for Rust cutover"
```

**Critério de conclusão:** o teste do runner passa e a linha de base foi gerada e versionada, com zero linhas `TIMEOUT` sem explicação. Se houver timeouts, registrá-los no README como estado conhecido do C.

### Task 0.3: Mapeamento ABI C → API núcleo e matriz de símbolos

**Files:**
- Create (este repo): `docs/cutover/abi-mapping.tsv`
- Create (este repo): `scripts/symbol-matrix.sh`
- Create (este repo): `scripts/test-symbol-matrix.sh`
- Create (este repo): `docs/cutover/symbol-matrix.tsv` (gerado)

**Interfaces:**
- Consumes: os fontes dos passes do Map2Check (`modules/backend/pass/*.{cpp,hpp}`) e o header `include/map2check.h`.
- Produces:
  - `docs/cutover/abi-mapping.tsv`, com o cabeçalho exato `c_symbol	core_symbol	owner_task	notes`. É a especificação que a Task 2.5 (biblioteca) e a Task 3.2 (passes) implementam. `core_symbol` pode listar várias chamadas separadas por `+`, ou `-` quando o símbolo deixa de ser chamado (com a justificativa em `notes`).
  - `symbol-matrix.sh <map2check-dir> <abi-mapping.tsv>`, que imprime o TSV `symbol	core_symbol	in_rust_header`. Sai com status 1 se algum símbolo emitido pelos passes não tiver linha no mapeamento ou se algum `core_symbol` não estiver no header. As Tasks 2.5 e 3.2 usam esse status como gate.

- [ ] **Step 1: Escrever o mapeamento inicial**

Ponto de partida, levantado em 2026-10-15 contra `Map2Check@83471fba`. As assinaturas C vêm das chamadas `getOrInsertFunction` nos passes; as Rust, de `rust/src/ffi.rs`. As linhas com `owner_task` ≠ `-` exigem export novo na biblioteca.

```tsv
c_symbol	core_symbol	owner_task	notes
map2check_init	map2check_set_mode+map2check_init	2.3	o arg int isSvComp é morto: Map2CheckFunctions.c:35 grava sv_comp e nenhum arquivo o lê
map2check_success	map2check_success	-	
map2check_track_bb	map2check_save_basic_block_log	-	conferir a ordem dos args
map2check_target_function	map2check_reach_target	2.3	
map2check_assert	map2check_is_valid_assert	-	
map2check_assume	__VERIFIER_assume	-	
map2check_assume_loop	__VERIFIER_assume	-	o C faz cast de char para int; o passe emite zext
map2check_crab_assume	__VERIFIER_assume	-	idem
map2check_binop_add	map2check_binop_add_int	-	
map2check_binop_add_uint	map2check_binop_add_unsigned	-	
map2check_binop_sub	map2check_binop_sub_int	-	
map2check_binop_sub_uint	map2check_binop_sub_unsigned	-	
map2check_binop_mul	map2check_binop_mul_int	-	
map2check_binop_mul_uint	map2check_binop_mul_unsigned	-	
map2check_binop_sdiv	map2check_binop_div_int	-	
map2check_malloc	map2check_map_malloc	-	
map2check_calloc	map2check_map_calloc	-	
map2check_alloca	map2check_map_alloca	-	
map2check_non_static_alloca	map2check_map_non_static_alloca	-	SD-12 (#38): unidade de tamanho
map2check_function	map2check_map_funct_address	-	
map2check_add_store_pointer	map2check_map_store_pointer	-	
map2check_load	map2check_check_load	-	o C recebe (ptr, i64 size); o núcleo recebe linha, escopo e função: o passe passa DebugInfo
map2check_free	map2check_check_free+map2check_map_free	-	o C desreferencia ptr (AnalysisModeMemtrack.c:341); manter o mesmo nível de indireção
map2check_free_resolved_address	map2check_check_free_resolved_address	-	SD-06 (#37)
map2check_posix	map2check_map_posix_memalign	2.5	chamado em MemoryTrackPass.cpp:120 para posix_memalign; não é obsoleto
map2check_wasm_malloc	map2check_wasm_malloc	2.8	
map2check_wasm_free	map2check_wasm_free	2.8	
map2check_wasm_check_access	map2check_wasm_check_access	2.8	
__map2check_main__	__map2check_main__	-	definido pelo programa instrumentado, não pela biblioteca
__VERIFIER_assert	__VERIFIER_assert	-	
__VERIFIER_assume	__VERIFIER_assume	-	
__VERIFIER_error	__VERIFIER_error	-	
```

A expansão por tipo de `map2check_non_det_<t>` (→ `__VERIFIER_nondet_<t>`) e de `map2check_nondet_<t>` (→ `map2check_save_nondet_log_<t>`) deve ser acrescentada, uma linha por tipo, a partir das macros `INSTRUMENT_HEADER_HELPER`/`CALL_IF_HELPER` de `modules/backend/pass/NonDetPass.hpp`. Os tipos sem equivalente núcleo hoje (`loff_t`, `sector_t`, `pchar`, `unsigned`, `short`, `uchar`, `size_t` no log) recebem `owner_task` = `2.5` (#6). `map2check_pointer_cast` e `map2check_nondet_cast_<t>` **não** entram: são nomes de valores do IR (`OverflowPass.cpp:255`, `NonDetPass.cpp:167`), não chamadas.

- [ ] **Step 2: Teste do script com passes falsos**

```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/modules/backend/pass"
cat > "$T/modules/backend/pass/P.cpp" <<'CPP'
f("map2check_init"); f("map2check_alloca"); Twine b("map2check_pointer_cast"); f("map2check_unmapped");
CPP
printf 'c_symbol\tcore_symbol\towner_task\tnotes\nmap2check_init\tmap2check_init\t-\t\nmap2check_alloca\tmap2check_map_alloca\t-\t\n' > "$T/map.tsv"
out="$("$HERE/symbol-matrix.sh" "$T" "$T/map.tsv" || true)"
grep -qP '^map2check_init\tmap2check_init\t1$' <<<"$out"
grep -qP '^map2check_alloca\tmap2check_map_alloca\t1$' <<<"$out"
grep -qP '^map2check_unmapped\t-\t0$' <<<"$out"
! grep -q pointer_cast <<<"$out"
if "$HERE/symbol-matrix.sh" "$T" "$T/map.tsv" >/dev/null; then echo "deveria falhar" >&2; exit 1; fi
echo ok
```

- [ ] **Step 3: Rodar e ver falhar**

Run: `bash scripts/test-symbol-matrix.sh`
Expected: FAIL (o script não existe).

- [ ] **Step 4: Implementar**

```bash
#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Cruza os símbolos de runtime emitidos pelos passes do Map2Check, traduzidos
# por docs/cutover/abi-mapping.tsv, com os declarados em include/map2check.h.
# Sai com 1 se algum símbolo não tiver mapeamento ou se o alvo não existir.
# Uso: symbol-matrix.sh <dir-do-Map2Check> <abi-mapping.tsv>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
M2C="$1"; MAP="$2"
# Nomes de valores do IR (Twine de casts), não chamadas ao runtime.
IR_VALUE_NAMES='^(map2check_pointer_cast|map2check_nondet_cast_.*)$'
pass="$(grep -ohE '"(map2check_|__VERIFIER_|__map2check)[A-Za-z0-9_]*[A-Za-z0-9]"' \
  "$M2C"/modules/backend/pass/*.cpp "$M2C"/modules/backend/pass/*.hpp 2>/dev/null \
  | tr -d '"' | grep -vE "$IR_VALUE_NAMES" | sort -u)"
hdr="$(grep -oE '\b(map2check_[a-z0-9_]+|__VERIFIER_[a-z0-9_]+)\s*\(' \
  "$ROOT/include/map2check.h" | tr -d '( ' | sort -u)"
missing=0
printf 'symbol\tcore_symbol\tin_rust_header\n'
while IFS= read -r s; do
  [ -z "$s" ] && continue
  core="$(awk -F'\t' -v s="$s" 'NR>1 && $1==s {print $2}' "$MAP")"
  if [ -z "$core" ]; then printf '%s\t-\t0\n' "$s"; missing=1; continue; fi
  ok=1
  if [ "$core" != "-" ] && [ "$core" != "__map2check_main__" ]; then
    IFS='+' read -ra parts <<<"$core"
    for c in "${parts[@]}"; do grep -qxF "$c" <<<"$hdr" || ok=0; done
  fi
  [ "$ok" = 1 ] || missing=1
  printf '%s\t%s\t%s\n' "$s" "$core" "$ok"
done <<<"$pass"
exit "$missing"
```

`__map2check_main__` é definido pelo programa instrumentado, então não é procurado no header.

- [ ] **Step 5: Rodar o teste e gerar a matriz real**

Run: `bash scripts/test-symbol-matrix.sh && (scripts/symbol-matrix.sh ~/Documents/Dev/Map2Check docs/cutover/abi-mapping.tsv > docs/cutover/symbol-matrix.tsv || true) && awk -F'\t' '$3==0' docs/cutover/symbol-matrix.tsv`
Expected: `ok`, e só aparecem como `0` as linhas cujo `owner_task` ainda não foi feito (2.3, 2.5, 2.8). Se aparecer um símbolo com `core_symbol` = `-`, falta uma linha no mapeamento: completar o Step 1.

- [ ] **Step 6: Commit**

```bash
git add docs/cutover/abi-mapping.tsv scripts/symbol-matrix.sh scripts/test-symbol-matrix.sh docs/cutover/symbol-matrix.tsv
git commit -S -m "docs: map Map2Check pass ABI to the core Rust API and gate it with a symbol matrix"
```

**Critério de conclusão:** o mapeamento cobre todos os símbolos emitidos (nenhuma linha com `-` na matriz). O script ainda falha por causa dos exports pendentes, o que é esperado até as Tasks 2.3, 2.5 e 2.8.

---

## Fase 1 — Gate de toolchain (decisão D1)

### Task 1.1: Spike de ligação do runtime Rust no pipeline LLVM 16 e no KLEE

**Files:**
- Create (este repo): `docs/cutover/spike-llvm16.md`
- Create (este repo, descartável): `spikes/llvm16/` (não vai para `develop`; fica na branch `spike/llvm16`)

**Interfaces:**
- Produces: a decisão D1 registrada em `docs/cutover/decisoes.md`, com a rota escolhida por gerador (`none`, `afl`, `symex`) e os comandos exatos de build/link que a Task 3.1 implementa.

- [ ] **Step 1: Montar o programa de prova**

`spikes/llvm16/prog.c`:

```c
extern void map2check_init(void);
extern void map2check_success(void);
extern int __VERIFIER_nondet_int(void);
int main(void) {
  map2check_init();
  int x = __VERIFIER_nondet_int();
  if (x == 42) return 1;
  map2check_success();
  return 0;
}
```

- [ ] **Step 2: Rota A (bitcode Rust no `llvm-link-16`)**

```bash
cargo rustc --release --lib --crate-type staticlib -- --emit=llvm-bc -C panic=abort
llvm-dis-16 target/release/deps/map2check-*.bc -o /dev/null; echo "dis16=$?"
```

Expected (hipótese): `dis16≠0`, com o erro registrado. Registrar a mensagem exata.

- [ ] **Step 3: Rota B (staticlib nativo no passo final)**

```bash
cargo build --release --features libfuzzer
clang-16 -emit-llvm -c spikes/llvm16/prog.c -o prog.bc
clang-16 -fsanitize=fuzzer prog.bc target/release/libmap2check.a -ldl -lpthread -lm -o prog.fuzz
./prog.fuzz -runs=1000; echo "rc=$?"
```

Expected: liga e roda. Registrar se há colisão de `main`/`LLVMFuzzerTestOneInput` com a instrumentação do LibFuzzer.

Repetir com o AFL++ do `develop` (imagem `map2check-dev:cutover-f01e8c3e`), nas duas variantes da D1:
- **B1:** `afl-clang-fast -fsanitize=fuzzer prog.bc target/release/libmap2check.a -ldl -lpthread -lm -o prog.afl` (driver libFuzzer do AFL++ chamando o `LLVMFuzzerTestOneInput` da biblioteca), seguido de `afl-fuzz -i in -o out -V 30 -- ./prog.afl`.
- **B2:** o `NonDetGeneratorAFL.c` atual compilado com `afl-clang-fast`, como referência de throughput.

Registrar `execs_per_sec` e `saved_crashes` de `out/default/fuzzer_stats` para as duas, e se B1 encontra o `x == 42`.

- [ ] **Step 4: Rota B sob KLEE (`--load` da biblioteca nativa)**

```bash
cargo rustc --release --lib --crate-type cdylib -- -C panic=abort
klee --external-calls=all --load=target/release/libmap2check.so prog.bc; echo "rc=$?"
```

Registrar: o `__VERIFIER_nondet_int` nativo devolve um valor concreto, então o KLEE **não** explora `x == 42`. Esperado: a rota B não serve para `symex`. Confirmar com o número de caminhos (`klee-stats`).

- [ ] **Step 5: Rota A′ (`no_std` + bitcode com rustc de LLVM ≤ 16)**

Construir uma crate mínima `spikes/llvm16/klee-rt` com `#![no_std]`, `panic = "abort"`, um alocador global sobre `malloc`/`free` e `__VERIFIER_nondet_int`, que chama `klee_make_symbolic`. Compilar com `rustup run 1.72.1` (LLVM 16.0.x):

```bash
rustup toolchain install 1.72.1
cd spikes/llvm16/klee-rt && rustup run 1.72.1 cargo rustc --release -- --emit=llvm-bc
llvm-link-16 ../prog.bc target/release/deps/klee_rt-*.bc -o linked.bc && klee linked.bc
```

Expected: o KLEE encontra 2 caminhos. Registrar o resultado.

- [ ] **Step 6: Rota C (custo de levar o Map2Check para LLVM 19)**

Listar as APIs de LLVM usadas pelos passes (`grep -ohE 'llvm::[A-Za-z:]+' modules/backend/pass/*.cpp | sort -u | wc -l`) e verificar se a versão de KLEE disponível suporta LLVM 19 (documentação de release do KLEE). Registrar um sim/não e a estimativa.

- [ ] **Step 7: Registrar a decisão**

`docs/cutover/decisoes.md`, seção D1: rota por gerador, comandos e evidência (saídas dos Steps 2–6). **Parar aqui e pedir aprovação do mantenedor.** Se nenhuma rota servir para `symex`, o cutover completo fica bloqueado: pela restrição "não remover sem equivalente validado", o runtime C do KLEE não pode sair. O mantenedor então escolhe entre a Rota C ou adiar.

- [ ] **Step 8: Commit (só o relatório e a decisão)**

```bash
git add docs/cutover/spike-llvm16.md docs/cutover/decisoes.md
git commit -S -m "docs: record LLVM 16 linkage spike and runtime integration decision (D1)"
```

**Critério de conclusão:** D1 aprovada por escrito (comentário na issue #20), com uma rota viável para cada gerador ou com o bloqueio declarado.

### Task 1.2: Perfil de build do runtime conforme D1

**Files:**
- Modify: `Cargo.toml` (perfil `runtime`, feature `klee`)
- Modify: `rust-toolchain.toml` (só se D1 = A′ exigir um toolchain separado para a crate KLEE)
- Test: `tests/runtime_profile.rs`

**Interfaces:**
- Produces: `cargo build --profile runtime [--features libfuzzer|klee]` gera `target/runtime/libmap2check.a` com `panic=abort`. A Task 3.1 consome esse caminho.

- [ ] **Step 1: Teste que fixa `panic = abort` no artefato**

```rust
// SPDX-License-Identifier: GPL-3.0-only
// O runtime ligado ao programa analisado não pode desenrolar através da FFI (#8).
#[test]
fn runtime_profile_aborts_on_panic() {
    let manifest = std::fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/Cargo.toml")).unwrap();
    let table = manifest.split("[profile.runtime]").nth(1).expect("perfil runtime ausente");
    let table = table.split("\n[").next().unwrap();
    assert!(table.contains("inherits = \"release\""), "{table}");
    assert!(table.contains("panic = \"abort\""), "{table}");
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cargo test --test runtime_profile`
Expected: FAIL, "perfil runtime ausente".

- [ ] **Step 3: Adicionar o perfil e as features**

```toml
[features]
libfuzzer = []
klee = []

[profile.runtime]
inherits = "release"
panic = "abort"
```

- [ ] **Step 4: Rodar**

Run: `cargo test --test runtime_profile && cargo build --profile runtime --features libfuzzer`
Expected: PASS e o artefato em `target/runtime/libmap2check.a`.

- [ ] **Step 5: Commit**

```bash
git add Cargo.toml tests/runtime_profile.rs
git commit -S -m "build: add abort-on-panic runtime profile and klee feature"
```

**Critério de conclusão:** o perfil existe e está testado; o CI passa.

---

## Fase 2 — Paridade na biblioteca Rust (este repositório)

Cada task desta fase fecha uma ou mais issues já abertas, que funcionam como especificação detalhada. Para cada uma, o executor cria um plano TDD próprio em `docs/superpowers/plans/` (convenção já usada neste repo) **antes** de codar. Aqui ficam fixados os testes de aceitação que precisam existir ao final.

### Task 2.1: Correção do núcleo — #9, #8, #11, #36, #37, #38

**Files:**
- Modify: `rust/src/state.rs`, `rust/src/ffi.rs`, `rust/src/memtrack/mod.rs`, `rust/src/analysismode/memory.rs`, `rust/src/nondet/libfuzzer.rs`
- Test: `rust/src/ffi_tests.rs`, `tests/ffi_harness.c`

**Interfaces:**
- Produces: `map2check_init()` passa a zerar o estado (contadores, containers, resultado e flags) em toda chamada. As Tasks 2.2–2.5 dependem disso.

- [ ] **Step 1: Escrever os testes de aceitação (falham hoje)**

```rust
#[test]
fn second_init_starts_from_clean_state() {            // #9
    let _guard = fresh();
    map2check_init();
    unsafe { map2check_map_malloc(addr(0x1000), 8) };
    map2check_init();
    assert!(snapshot(|s| s.memtrack.is_empty()));
    assert_eq!(snapshot(|s| s.current_step()), 0);
}

#[test]
fn deref_after_free_is_invalid() {                   // #11
    let _guard = fresh();
    map2check_init();
    unsafe {
        map2check_map_malloc(addr(0x2000), 16);
        map2check_map_free(c"p".as_ptr(), addr(0x2000), 0, 9, c"main".as_ptr());
        map2check_check_deref(addr(0x2000), 0, 10, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 10, "main");
}
```

Para #36, #37 e #38, usar os casos reproduzíveis de `docs/semantic-deltas.md` (SD-03, SD-06, SD-12) como testes, um `#[test]` por SD, com o nome `sd03_safe_check_keeps_earlier_violation`, `sd06_untracked_free_is_invalid` e `sd12_vla_is_not_a_leak_and_size_is_elements`. Para o #8, mais um caso em `tests/ffi_harness.c` que chame cada export antes do `map2check_init`.

- [ ] **Step 2: Rodar e ver falhar**

Run: `cargo test --all-features second_init deref_after_free sd03 sd06 sd12`
Expected: 5 FAIL.

- [ ] **Step 3: Implementar seguindo o plano de cada issue**

- [ ] **Step 4: Rodar a suíte completa e o harness**

Run: `cargo test --all-features && cargo build --release --all-features && clang -fsanitize=address,undefined -fno-omit-frame-pointer tests/ffi_harness.c target/release/libmap2check.a -ldl -lpthread -lm -o target/ffi_harness && target/ffi_harness`
Expected: tudo verde e nenhum relatório do ASan/UBSan.

- [ ] **Step 5: Commit por issue** (`fix: ... (#N)`), um PR por issue contra `develop`.

**Critério de conclusão:** #8, #9, #11, #36, #37 e #38 fechadas por PRs mergeados, com os testes acima na suíte.

### Task 2.2: Semântica de memcleanup e null-is-valid — #10

**Files:**
- Modify: `rust/src/ffi.rs:230-260`, `rust/src/analysismode/memory.rs`, `rust/src/state.rs`
- Test: `rust/src/ffi_tests.rs`

**Interfaces:**
- Consumes: o reset de estado da Task 2.1.
- Produces: `AnalysisState::options { memcleanup: bool, null_is_valid: bool }`, lidas por `map2check_check_load` e `map2check_check_mem_endprog`.

- [ ] **Step 1: Testes**

```rust
#[test]
fn memcleanup_reports_leak_at_exit() {
    let _guard = fresh();
    map2check_init();
    map2check_set_memcleanup();
    unsafe { map2check_map_malloc(addr(0x3000), 32) };
    map2check_check_mem_endprog();
    assert_eq!(snapshot(|s| s.result.property), ViolatedProperty::MemsafetyMemcleanup);
}

#[test]
fn without_memcleanup_leak_is_memtrack() {
    let _guard = fresh();
    map2check_init();
    unsafe { map2check_map_malloc(addr(0x3000), 32) };
    map2check_check_mem_endprog();
    assert_eq!(snapshot(|s| s.result.property), ViolatedProperty::MemsafetyMemtrack);
}

#[test]
fn null_is_valid_accepts_null_load() {
    let _guard = fresh();
    map2check_init();
    map2check_set_null_is_valid();
    unsafe { map2check_check_load(std::ptr::null(), 3, 0, 4, c"main".as_ptr()) };
    assert_ok();
}
```

Antes de escrever o segundo teste, conferir em `AnalysisModeMemtrack.c` e `AnalysisModeMemcleanup.c` qual tag o C emite para um vazamento sem `--memcleanup-property` e ajustar a asserção ao C. Esse é o comportamento de referência.

- [ ] **Step 2–4:** ver falhar, implementar, `cargo test --all-features` verde.
- [ ] **Step 5: Commit** `fix: honour memcleanup and null-is-valid options in memory checks (#10)`

**Critério de conclusão:** #10 fechada; os três testes passam.

### Task 2.3: Seleção de modo em tempo de execução, alcance de alvo e modo None

**Files:**
- Create: `rust/src/analysismode/mode.rs`
- Modify: `rust/src/ffi.rs`, `rust/src/state.rs`, `rust/src/caller/mod.rs` (variantes `Unknown`, `Assert`, `TargetReached`)
- Test: `rust/src/ffi_tests.rs`

**Interfaces:**
- Assinaturas atuais usadas nos testes (`rust/src/ffi.rs`): `map2check_check_deref(ptr, scope: u32, line: u32, function_name)`, `map2check_check_load(ptr, line: i32, scope: u32, size: i32, function_name)`, `map2check_map_free(var_name, ptr, scope: u32, line: u32, function_name)`, `map2check_map_malloc(ptr, size: i32)`.
- Produces:
  - `#[repr(C)] pub enum AnalysisMode { None = 0, Memtrack = 1, Memcleanup = 2, Overflow = 3, Assert = 4, Target = 5 }`
  - `extern "C" fn map2check_set_mode(mode: AnalysisMode)`, emitida pelo passe `Map2CheckLibrary` antes do `map2check_init` (Task 3.2).
  - `pub(crate) fn mark_target_reached(func: *const c_char, scope: i32, line: i32)` (sem `exit`, testável) e `extern "C" fn map2check_reach_target(func: *const c_char, scope: i32, line: i32)`, com a mesma semântica de `map2check_target_function` no C: marca TARGET-REACHED e termina.
  - `ViolatedProperty` ganha `Unknown`, `Assert` e `TargetReached` (os nomes JSON ficam definidos na Task 2.4).

- [ ] **Step 1: Testes**

```rust
#[test]
fn mode_none_never_reports_memory_errors() {
    let _guard = fresh();
    map2check_set_mode(AnalysisMode::None);
    map2check_init();
    unsafe { map2check_check_deref(addr(0xdead), 0, 1, c"main".as_ptr()) };
    assert_ok();
}

#[test]
fn mode_memtrack_reports_invalid_deref() {
    let _guard = fresh();
    map2check_set_mode(AnalysisMode::Memtrack);
    map2check_init();
    unsafe { map2check_check_deref(addr(0xdead), 0, 1, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyDeref, 1, "main");
}

#[test]
fn reach_target_sets_target_reached() {
    let _guard = fresh();
    map2check_set_mode(AnalysisMode::Target);
    map2check_init();
    unsafe { mark_target_reached(c"reach_error".as_ptr(), 0, 12) }; // núcleo sem exit
    assert_violated(ViolatedProperty::TargetReached, 12, "reach_error");
}

#[test]
fn reset_keeps_selected_mode() {
    let _guard = fresh();
    map2check_set_mode(AnalysisMode::Overflow);
    map2check_init();
    map2check_reset();
    assert_eq!(snapshot(|s| s.mode), AnalysisMode::Overflow);
}
```

`mark_target_reached` é a função interna que não chama `exit`; `map2check_reach_target` = `mark_target_reached` + escrita do resultado + `exit`. Testar a versão com `exit` pelo mecanismo de processo filho já usado no #29 (`05b44c3`).

- [ ] **Step 2–4:** ver falhar, implementar, suíte verde. A lista completa de efeitos por modo vem de `AnalysisMode*.c` (`analysis_init`, `analysis_destroy`, `analysis_is_program_correct`). Cada função vira um `match` em `mode.rs`, com um teste por braço.
- [ ] **Step 5: Commit** `feat: select analysis mode at runtime and report target reachability`

**Critério de conclusão:** um teste por modo × função de ciclo de vida; o header regenerado traz `map2check_set_mode`, `map2check_reach_target` e `AnalysisMode`.

### Task 2.4: Canal de resultado legado em arquivos — #19, #14

**Files:**
- Create: `rust/src/output/legacy_files.rs`
- Modify: `rust/src/output/mod.rs`, `rust/src/ffi.rs` (init e fim de análise)
- Test: `rust/src/output/legacy_files.rs` (módulo `tests`), `tests/legacy_golden/` (golden files)

**Interfaces:**
- Consumes: `ViolatedProperty` com `Unknown`/`Assert`/`TargetReached` (Task 2.3).
- Produces: `pub fn write_property_files(dir: &Path, r: &AnalysisResult) -> io::Result<()>`, `pub fn write_list_log_csv`, `pub fn write_nondet_log_csv` (→ `klee_log.csv`), `pub fn write_trackbb_log` (→ `track_bb_log.st`), `pub fn write_checked_error` (→ `map2check_checked_error`) e `pub fn remove_stale_property_files(dir: &Path)`.

- [ ] **Step 1: Capturar os golden files do C**

Na imagem `Dockerfile.dev` com o runtime C, rodar o Map2Check em 1 tarefa por propriedade (FALSE-FREE, FALSE-DEREF, FALSE-MEMTRACK, FALSE-MEMCLEANUP, OVERFLOW, ASSERT, TARGET-REACHED, NONE) e copiar **todos** os arquivos de resultado do diretório de trabalho para `tests/legacy_golden/<tag>/`. Registrar o comando exato em `tests/legacy_golden/README.md`.

- [ ] **Step 2: Testes golden**

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use crate::caller::{AnalysisResult, ViolatedProperty};

    fn golden(tag: &str, file: &str) -> String {
        std::fs::read_to_string(format!(
            "{}/tests/legacy_golden/{tag}/{file}", env!("CARGO_MANIFEST_DIR"))).unwrap()
    }

    #[test]
    fn false_deref_matches_c_runtime() {
        let dir = tempfile::tempdir().unwrap();
        let r = AnalysisResult { ok: false, property: ViolatedProperty::MemsafetyDeref,
                                 line: 7, function_name: "main".into(), ..Default::default() };
        write_property_files(dir.path(), &r).unwrap();
        assert_eq!(std::fs::read_to_string(dir.path().join("map2check_property")).unwrap(),
                   golden("FALSE-DEREF", "map2check_property"));
        assert_eq!(std::fs::read_to_string(dir.path().join("map2check_property_deref")).unwrap(),
                   golden("FALSE-DEREF", "map2check_property_deref"));
    }

    #[test]
    fn unknown_uses_legacy_double_underscore_name() {   // PropertyGenerator.c:16, ver SD novo
        let dir = tempfile::tempdir().unwrap();
        let r = AnalysisResult { ok: false, property: ViolatedProperty::Unknown, ..Default::default() };
        write_property_files(dir.path(), &r).unwrap();
        assert!(dir.path().join("map2check_property__unknown").exists());
        assert!(!dir.path().join("map2check_property_unknown").exists());
    }

    #[test]
    fn stale_property_files_are_removed_on_init() {
        let dir = tempfile::tempdir().unwrap();
        std::fs::write(dir.path().join("map2check_property_free"), "FALSE-FREE\n").unwrap();
        remove_stale_property_files(dir.path());
        assert!(!dir.path().join("map2check_property_free").exists());
    }
}
```

Repetir `false_deref_matches_c_runtime` como teste parametrizado para cada uma das oito tags e para `list_log.csv`, `klee_log.csv`, `track_bb_log.st` e `map2check_checked_error`. Adicionar `tempfile` a `[dev-dependencies]`.

- [ ] **Step 3: Rodar e ver falhar.** Run: `cargo test --all-features legacy_files` → FAIL (módulo inexistente).
- [ ] **Step 4: Implementar** com escrita byte a byte igual ao golden, incluindo as quebras de linha finais. O JSON (`print_all_containers_as_json`) continua existindo; o #14 é fechado documentando em `docs/api-deltas.md` que **o canal suportado pelo Map2Check é o de arquivos** e que o JSON é um canal adicional com schema próprio, coberto por snapshot.
- [ ] **Step 5:** Registrar o SD novo em `docs/semantic-deltas.md` para o `__unknown`, com a classificação "comportamento do C preservado de propósito".
- [ ] **Step 6: Commit** `feat: write legacy property, log and witness files consumed by Map2Check frontend (#19, #14)`

**Critério de conclusão:** os golden tests das oito tags e dos quatro logs passam; #19 e #14 estão fechadas.

### Task 2.5: Completar a API núcleo para tudo que os passes chamam — #13, #6, #12, #7

Pela D5, **não há camada de compatibilidade**: nenhum nome ou assinatura do runtime C é exportado pela biblioteca. Esta task só adiciona à API núcleo, com nomes e assinaturas núcleo, as funcionalidades que ainda faltam (as linhas `owner_task` = `2.5` de `docs/cutover/abi-mapping.tsv`). A adaptação dos nomes é feita nos passes (Task 3.2). A issue #21 fecha como "won't do (D5)".

**Files:**
- Modify: `rust/src/ffi.rs`, `rust/src/nondet/mod.rs`, `rust/src/nondet/libfuzzer.rs`, `rust/src/memtrack/mod.rs`, `docs/api-deltas.md`, `docs/cutover/abi-mapping.tsv`
- Test: `rust/src/ffi_tests.rs`, `tests/core_api_coverage.rs`, `.github/workflows/CI.yml`

**Interfaces:**
- Consumes: `docs/cutover/abi-mapping.tsv` (Task 0.3), `map2check_set_mode`/`map2check_reach_target` (2.3), os writers (2.4) e o núcleo (2.1, 2.2).
- Produces:
  - `extern "C" fn map2check_map_posix_memalign(ptr_address: *const c_void, size: i32)`, com a semântica de `map2check_posix` (`AnalysisModeMemtrack.c:328`).
  - `__VERIFIER_nondet_{loff_t,sector_t,pchar}` e `map2check_save_nondet_log_<t>` para todo tipo listado no mapeamento (#6), com a representação C de cada tipo confirmada no `NonDetGenerator.h` do Map2Check.
  - A decisão do #13 registrada em `docs/api-deltas.md`: a assinatura de `map2check_save_nondet_log_*` continua a núcleo atual de `rust/src/ffi.rs` (`line: i32, scope: i32, type_var: i32, value: *mut T, function_name` → `*mut non_det_log_t`), e o passe se adapta (grava o valor num `alloca` e passa o ponteiro).
  - Ao final, todo `core_symbol` do mapeamento existe no header. A Task 3.2 depende de `scripts/symbol-matrix.sh` sair com 0.

- [ ] **Step 1: Teste que exige cada alvo do mapeamento no artefato**

```rust
// SPDX-License-Identifier: GPL-3.0-only
// Todo símbolo núcleo usado pelo mapeamento ABI C → núcleo precisa existir no staticlib.
// Não há camada de compatibilidade (D5): nomes do runtime C não podem aparecer no artefato.
fn defined_symbols() -> String {
    let root = env!("CARGO_MANIFEST_DIR");
    let status = std::process::Command::new("cargo")
        .args(["build", "--profile", "runtime", "--features", "libfuzzer"])
        .current_dir(root).status().unwrap();
    assert!(status.success());
    let nm = std::process::Command::new("nm")
        .args(["--defined-only", "-g", &format!("{root}/target/runtime/libmap2check.a")])
        .output().unwrap();
    String::from_utf8_lossy(&nm.stdout).into_owned()
}

fn mapping() -> Vec<(String, String)> {
    let root = env!("CARGO_MANIFEST_DIR");
    std::fs::read_to_string(format!("{root}/docs/cutover/abi-mapping.tsv")).unwrap()
        .lines().skip(1)
        .map(|l| { let mut c = l.split('\t'); (c.next().unwrap().into(), c.next().unwrap().into()) })
        .collect()
}

fn is_defined(defined: &str, sym: &str) -> bool {
    defined.lines().any(|d| d.ends_with(&format!(" T {sym}")))
}

#[test]
fn every_core_target_is_exported() {
    let defined = defined_symbols();
    let missing: Vec<_> = mapping().iter()
        .flat_map(|(_, core)| core.split('+').map(str::to_owned).collect::<Vec<_>>())
        .filter(|c| c != "-" && c != "__map2check_main__" && !is_defined(&defined, c))
        .collect();
    assert!(missing.is_empty(), "alvos núcleo ausentes: {missing:?}");
}

#[test]
fn no_legacy_c_name_is_exported() {
    let defined = defined_symbols();
    let leaked: Vec<_> = mapping().into_iter()
        .filter(|(c, core)| !core.split('+').any(|x| x == c) && is_defined(&defined, c))
        .map(|(c, _)| c)
        .collect();
    assert!(leaked.is_empty(), "nomes do runtime C exportados (D5 proíbe): {leaked:?}");
}
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `cargo test --test core_api_coverage` → FAIL em `every_core_target_is_exported`, listando os exports das linhas `owner_task` = `2.5`. O `no_legacy_c_name_is_exported` já deve passar.
- [ ] **Step 3: Implementar um export por commit pequeno**, cada um com um teste em `ffi_tests.rs` que o chame como o C faria e verifique o efeito no estado. Por exemplo:

```rust
#[test]
fn posix_memalign_is_tracked_like_malloc() {
    let _guard = fresh();
    map2check_init();
    unsafe { map2check_map_posix_memalign(addr(0x4000), 64) };
    assert!(snapshot(|s| !s.memtrack.is_empty()));
}
```

- [ ] **Step 4: Rodar.** Run: `cargo test --all-features && scripts/symbol-matrix.sh ~/Documents/Dev/Map2Check docs/cutover/abi-mapping.tsv >/dev/null; echo $?` → `0` (com 2.3 e 2.8 já feitas).
- [ ] **Step 5: Ligar os três programas C de `test/` e o harness à biblioteca** (#7), atualizando-os para a API núcleo onde ainda usarem nomes antigos. Adicionar os passos de compilação e execução ao `.github/workflows/CI.yml`.
- [ ] **Step 6: Commit/PR** `feat: complete the core C API for every Map2Check instrumentation point (#13, #6, #12, #7)`. Fechar a #21 com o comentário "won't do: D5, sem camada de compatibilidade; ver docs/cutover/decisoes.md".

**Critério de conclusão:** `core_api_coverage` (os dois testes) e `ffi_harness` passam no CI, e `symbol-matrix.sh` sai com 0 contra o `develop` atual do Map2Check.

### Task 2.6: Estrutura de dados `--btree` (decisão D3)

**Files:** `docs/cutover/decisoes.md` (D3); se a decisão for portar: `rust/src/state.rs` + backend de armazenamento.

- [ ] **Step 1:** Rodar a Task 4.3 (medição de memória) antes desta.
- [ ] **Step 2:** Se o pico de RSS do Rust em memória ficar ≤ o do C com `--btree` em todas as tarefas do corpus e nas 5 maiores do `MemSafety-Arrays.set`, registrar a justificativa em D3. A Task 3.3 então trata `--btree` como no-op com aviso (`Log::Warning("--btree is ignored by the Rust runtime")`), e um teste no frontend fixa o aviso.
- [ ] **Step 3:** Caso contrário, abrir um plano próprio para portar o armazenamento em disco e só seguir para a Fase 5 com ele pronto.

**Critério de conclusão:** D3 registrada com números, e a implementação ou o no-op testado.

### Task 2.7: Gerador KLEE — #20

**Files:** conforme D1. Na rota A′: `klee-rt/` (crate `no_std` separada no workspace) + `docs/klee-feasibility.md`.

**Interfaces:**
- Produces: um `.bc` legível por `llvm-dis-16` que exporta `__VERIFIER_nondet_*` / `map2check_non_det_*` via `klee_make_symbolic` e `map2check_assume` via `klee_assume`, mais as funções de estado necessárias ao modo, com a mesma semântica do núcleo.

- [ ] **Step 1:** Escrever o teste de integração `tests/klee_paths.sh`, que liga `spikes/llvm16/prog.c` ao `.bc` e espera `KLEE: done: completed paths = 2`.
- [ ] **Step 2:** Ver falhar. Implementar conforme D1.
- [ ] **Step 3:** Ver passar no container `Dockerfile.dev`.
- [ ] **Step 4:** Commit/PR `feat: add KLEE nondet runtime (#20)`.

**Critério de conclusão:** `tests/klee_paths.sh` passa no CI do Map2Check (Task 3.4), e #20 está fechada com `docs/klee-feasibility.md`.

### Task 2.8: Runtime wasm (decisão D2)

**Files:** `rust/src/wasm.rs` (feature `wasm`), testes em `rust/src/ffi_tests.rs`.

**Interfaces:**
- Produces: `wasm_rt_allocate_memory`, `wasm_rt_grow_memory`, `wasm_rt_free_memory`, `wasm_rt_allocate_funcref_table`, `wasm_rt_free_funcref_table`, `w2c_wasi__snapshot__preview1_proc_exit`, `wasm_rt_is_initialized`, `wasm_rt_init`, `wasm_rt_free`, `wasm_rt_trap`, `map2check_wasm_malloc`, `map2check_wasm_free` e `map2check_wasm_check_access`, com o layout de `wasm_rt_memory_t` do wabt 1.0.41 replicado via `#[repr(C)]` e conferido por um teste de `size_of`/`offset_of` contra o `wasm-rt.h` compilado em `build.rs` (apenas quando `WASM_RT_INCLUDE` estiver definido).

- [ ] **Step 1:** Escrever o teste de layout e um teste por função, espelhando `WasmRuntimeStubs.c:22-110`.
- [ ] **Step 2–4:** Ver falhar, implementar, ver passar.
- [ ] **Step 5:** Commit `feat: port wasm2c runtime stubs to Rust`.

**Critério de conclusão:** com o runtime Rust, `tests/integration/test_wasm_pipeline.sh` e `test_wasm_entrypoint.sh` do Map2Check passam (verificado na Task 4.2).

### Task 2.9: Release candidata da biblioteca

- [ ] **Step 1:** Subir a versão para `1.1.0-rc1` em `Cargo.toml` e atualizar o `CHANGELOG.md` com as seções das Tasks 2.1–2.8.
- [ ] **Step 2:** Run: `cargo test --all-features && cargo clippy --all-targets --all-features -- -D warnings && cargo fmt --check && cargo deny check && scripts/coverage.sh`. Expected: tudo verde.
- [ ] **Step 3:** Tag assinada `v1.1.0-rc1` em `main` (fluxo de [docs/release.md](../../release.md)).

**Critério de conclusão:** o artefato publicado inclui `libmap2check.a` (perfil `runtime`) e, se D1 exigir, o `.bc` KLEE.

---

## Fase 3 — Integração no Map2Check por migração direta, em branch (#22, #23)

**Migração direta (decidida em 2026-10-15):** os passes passam a emitir só a API núcleo, sem tabela de ABI dupla e sem opção de build para voltar ao C. Todo o trabalho desta fase vai para uma branch de longa duração, `feat/rust-runtime`, no Map2Check, criada a partir de `develop`, rebaseada semanalmente e mergeada **em um único merge commit** só depois do gate da Fase 4 (Task 5.1). Até lá, `develop` continua com o runtime C intacto. Depois do merge, o rollback é `git revert -m 1 <merge>` (Task 5.1), possível até a Fase 6.

### Task 3.1: CMake constrói e instala o runtime Rust

**Files:**
- Create (Map2Check): `cmake/Map2CheckRustRuntime.cmake`
- Modify (Map2Check): `CMakeLists.txt`, `modules/backend/CMakeLists.txt`
- Test (Map2Check): `tests/cutover/test_rust_runtime_cmake.sh`

**Interfaces:**
- Consumes: `v1.1.0-rc1` da biblioteca (Task 2.9).
- Produces: o build instala `${MAP2CHECK_PATH}/lib/libmap2check.a` (e `map2check-klee.bc`, conforme D1) e **não** compila nem instala os `.bc` de `modules/backend/library`. O diretório C continua no repositório (só sai na Fase 6), mas fora do build. Variáveis de cache: `MAP2CHECK_RUST_LIB_DIR` (biblioteca pré-compilada) e `MAP2CHECK_RUST_SRC` (checkout para compilar com cargo).

- [ ] **Step 1: Teste**

```bash
#!/usr/bin/env bash
# Configura, instala e verifica que só o runtime Rust é instalado.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
B="$(mktemp -d)"; P="$(mktemp -d)"; trap 'rm -rf "$B" "$P"' EXIT
cmake -S "$ROOT" -B "$B" -DMAP2CHECK_RUST_LIB_DIR="${MAP2CHECK_RUST_LIB_DIR:?}" >/dev/null
cmake --build "$B" -j >/dev/null && cmake --install "$B" --prefix "$P" >/dev/null
test -f "$P/lib/libmap2check.a"
if ls "$P"/lib/*.bc 2>/dev/null | grep -vE 'map2check-klee\.bc$'; then
  echo "runtime C ainda instalado" >&2; exit 1
fi
# Diretório sem a biblioteca: o configure tem que falhar alto.
E="$(mktemp -d)"
if cmake -S "$ROOT" -B "$B.bad" -DMAP2CHECK_RUST_LIB_DIR="$E" >/dev/null 2>&1; then
  echo "configure deveria falhar sem libmap2check.a" >&2; exit 1
fi
rm -rf "$E" "$B.bad"
echo ok
```

- [ ] **Step 2: Ver falhar.** Expected: FAIL em `test -f "$P/lib/libmap2check.a"`.
- [ ] **Step 3: Implementar `cmake/Map2CheckRustRuntime.cmake`**

```cmake
# Runtime do Map2Check: map2check-library (Rust). Substitui modules/backend/library.
set(MAP2CHECK_RUST_LIB_DIR "" CACHE PATH "Directory with a prebuilt libmap2check.a (empty = build from MAP2CHECK_RUST_SRC)")
set(MAP2CHECK_RUST_SRC "" CACHE PATH "map2check-library checkout used when MAP2CHECK_RUST_LIB_DIR is empty")

if(MAP2CHECK_RUST_LIB_DIR)
  set(_m2c_rust_lib "${MAP2CHECK_RUST_LIB_DIR}/libmap2check.a")
  if(NOT EXISTS "${_m2c_rust_lib}")
    message(FATAL_ERROR "libmap2check.a not found in ${MAP2CHECK_RUST_LIB_DIR}")
  endif()
elseif(MAP2CHECK_RUST_SRC)
  find_program(CARGO cargo REQUIRED)
  set(_m2c_rust_lib "${MAP2CHECK_RUST_SRC}/target/runtime/libmap2check.a")
  add_custom_command(OUTPUT "${_m2c_rust_lib}"
    COMMAND ${CARGO} build --profile runtime --features libfuzzer
    WORKING_DIRECTORY "${MAP2CHECK_RUST_SRC}")
  add_custom_target(Map2CheckRustRuntime ALL DEPENDS "${_m2c_rust_lib}")
else()
  message(FATAL_ERROR "Set MAP2CHECK_RUST_LIB_DIR or MAP2CHECK_RUST_SRC to provide the Rust runtime")
endif()
install(FILES "${_m2c_rust_lib}" DESTINATION lib)
```

Em `modules/backend/CMakeLists.txt`, remover `add_subdirectory(library)`. Se D1 incluir o `.bc` KLEE, adicionar a verificação `execute_process(COMMAND llvm-dis-16 <bc> -o /dev/null RESULT_VARIABLE r)` + `FATAL_ERROR` quando `r` ≠ 0 (Review Focus 5).

- [ ] **Step 4: Ver passar.** Run: `MAP2CHECK_RUST_LIB_DIR=~/Documents/Dev/map2check-library/target/runtime bash tests/cutover/test_rust_runtime_cmake.sh` → `ok`.
- [ ] **Step 5: Commit (na branch `feat/rust-runtime`)** `build: build and install the Rust runtime instead of the C bitcode library`

**Critério de conclusão:** o teste passa, e o configure falha com mensagem clara sem a biblioteca.

### Task 3.2: Passes LLVM emitem a API núcleo

Pela D5, a biblioteca não se adapta: os passes passam a emitir os nomes e assinaturas núcleo de `docs/cutover/abi-mapping.tsv`. Os nomes ficam centralizados em uma única tabela, para que exista um só lugar a revisar contra o mapeamento.

**Files:**
- Create (Map2Check): `modules/backend/pass/RuntimeABI.hpp`, `modules/backend/pass/RuntimeABI.cpp`
- Modify (Map2Check): `AssertPass.cpp`, `OverflowPass.cpp`, `MemoryTrackPass.cpp`, `NonDetPass.cpp`, `NonDetFunctions.hpp`, `TargetPass.cpp`, `TrackBasicBlockPass.cpp`, `LoopPredAssumePass.cpp`, `Map2CheckLibrary.cpp`, `LibraryFunctions.hpp`, `OperationsFunctions.hpp`
- Test (Map2Check): `tests/unit/pass/RuntimeABITest.cpp`, `tests/unit/pass/PassIRTest.cpp`, `tests/unit/pass/inputs/*.c`, `tests/unit/pass/CMakeLists.txt`

**Interfaces:**
- Consumes: `docs/cutover/abi-mapping.tsv` e a biblioteca com todos os alvos exportados (Task 2.5); `AnalysisMode` com os valores numéricos None=0, Memtrack=1, Memcleanup=2, Overflow=3, Assert=4, Target=5 (Task 2.3).
- Produces:

```cpp
// RuntimeABI.hpp
namespace Map2Check {
enum class RuntimeHook {
  SetMode, Init, Success, TrackBB, TargetReached, Assert, Assume,
  BinopAdd, BinopAddU, BinopSub, BinopSubU, BinopMul, BinopMulU, BinopSDiv,
  Malloc, Calloc, Alloca, NonStaticAlloca, FunctionAddr, StorePointer,
  Load, CheckFree, MapFree, FreeResolved, PosixMemalign,
  WasmMalloc, WasmFree, WasmCheckAccess
};
// Uma função de runtime da API núcleo: nome + tipo, para getOrInsertFunction.
struct RuntimeCall { const char* name; llvm::FunctionType* type; };
RuntimeCall runtimeCall(RuntimeHook hook, llvm::LLVMContext& ctx);
std::string nonDetGenerator(llvm::StringRef cType);   // __VERIFIER_nondet_<t>
std::string nonDetLogger(llvm::StringRef cType);      // map2check_save_nondet_log_<t>
}  // namespace Map2Check
```

  Cada passe troca `getOrInsertFunction("map2check_…", …)` por `runtimeCall(RuntimeHook::…, ctx)` e monta os argumentos na ordem núcleo, seguindo as notas do mapeamento (ex.: `Load` passa linha, escopo, tamanho e função; o `free` do C vira `CheckFree` + `MapFree`; `assume_loop`/`crab_assume` fazem `zext` para `i32` e chamam `Assume`; `init` deixa de passar o `isSvComp` morto). `Map2CheckLibrary.cpp` emite `SetMode(<modo>)` antes de `Init`.

- [ ] **Step 1: Teste da tabela contra o mapeamento**

```cpp
// Os nomes da tabela batem com docs/cutover/abi-mapping.tsv, e nenhum nome do runtime C sobrou.
TEST(RuntimeABI, NamesMatchMapping) {
  llvm::LLVMContext ctx;
  std::set<std::string> core = loadCoreSymbols(MAP2CHECK_ABI_MAPPING_TSV);  // coluna core_symbol, separada por '+'
  for (int h = 0; h <= static_cast<int>(RuntimeHook::WasmCheckAccess); ++h)
    EXPECT_TRUE(core.count(runtimeCall(static_cast<RuntimeHook>(h), ctx).name))
        << runtimeCall(static_cast<RuntimeHook>(h), ctx).name;
}

TEST(RuntimeABI, NoLegacyNameRemains) {
  std::set<std::string> legacy = loadLegacyOnlySymbols(MAP2CHECK_ABI_MAPPING_TSV);  // c_symbol que não é também core
  llvm::LLVMContext ctx;
  for (int h = 0; h <= static_cast<int>(RuntimeHook::WasmCheckAccess); ++h)
    EXPECT_FALSE(legacy.count(runtimeCall(static_cast<RuntimeHook>(h), ctx).name));
}
```

`MAP2CHECK_ABI_MAPPING_TSV` é uma definição do CMake de teste que aponta para uma cópia do `abi-mapping.tsv` baixada junto com o tarball da tag `v1.1.0-rc1` da biblioteca (Task 3.4).

- [ ] **Step 2: Teste de IR por hook.** Para cada hook, um programa C mínimo em `tests/unit/pass/inputs/` que exercita o ponto de instrumentação (ex.: `free.c` com `free(p)`). Compilar com `clang-16 -O0 -g -emit-llvm`, rodar o passe com `opt-16 -load-pass-plugin`, executar `llvm::verifyModule` e conferir os callees:

```cpp
TEST(PassIR, MemoryTrackFreeEmitsCoreCalls) {
  auto m = runPassOn("MemoryTrackPass", "free.c");
  ASSERT_FALSE(llvm::verifyModule(*m, &llvm::errs()));
  EXPECT_TRUE(calls(*m, "map2check_check_free"));
  EXPECT_TRUE(calls(*m, "map2check_map_free"));
  EXPECT_FALSE(calls(*m, "map2check_free"));
}

TEST(PassIR, LibraryEmitsSetModeBeforeInit) {
  auto m = runPassOn("Map2CheckLibrary", "main.c", /*mode=*/"memtrack");
  ASSERT_FALSE(llvm::verifyModule(*m, &llvm::errs()));
  EXPECT_LT(callIndex(*m, "map2check_set_mode"), callIndex(*m, "map2check_init"));
  EXPECT_EQ(firstArgConstant(*m, "map2check_set_mode"), 1);  // Memtrack
}
```

Escrever um teste por hook do enum (28), mais `nonDetGenerator`/`nonDetLogger` para cada tipo do mapeamento.

- [ ] **Step 3: Rodar e ver falhar.** Run: `cmake --build build && cd build && ctest -R 'RuntimeABI|PassIR' --output-on-failure` → falha de compilação (`RuntimeABI.hpp` inexistente).
- [ ] **Step 4: Implementar a tabela e migrar um passe por commit**, na ordem `TrackBasicBlockPass`, `AssertPass`, `TargetPass`, `LoopPredAssumePass`, `OverflowPass`, `NonDetPass`, `MemoryTrackPass`, `Map2CheckLibrary`. Cada commit deixa os testes `PassIR` do passe migrado verdes.
- [ ] **Step 5: Teste de link ponta a ponta.** Para cada input de `tests/unit/pass/inputs/`, instrumentar com todos os passes do modo, ligar a `libmap2check.a` com `clang-16` e garantir zero `undefined reference`.
- [ ] **Step 6: Commit (na branch)** `feat(pass): emit the core runtime API of map2check-library (#23)`

**Critério de conclusão:** `RuntimeABI*` e `PassIR*` passam; `grep -rnE '"map2check_(malloc|calloc|free|load|alloca|assert|track_bb|function|posix|binop_(add|sub|mul|sdiv)(_uint)?|non_det_[a-z_]+|nondet_[a-z_]+)"' modules/backend/pass` não retorna nada; o link ponta a ponta não tem símbolos indefinidos.

### Task 3.3: Link do runtime Rust em `Caller::linkLLVM`

**Files:**
- Modify (Map2Check): `modules/frontend/caller.cpp:226-312` e os pontos que geram os binários `-fuzzed.out` (`:121-133`) e o comando KLEE (`:384-420`)
- Test (Map2Check): `tests/unit/frontend/CallerLinkTest.cpp` (gtest; o diretório já tem a infraestrutura do `ctest`)

**Interfaces:**
- Consumes: os passes emitindo a API núcleo (Task 3.2) e o `libmap2check.a` instalado (Task 3.1).
- Produces: `linkLLVM()` não liga nenhum `.bc` de runtime; os comandos de `clang` final acrescentam `${MAP2CHECK_PATH}/lib/libmap2check.a -ldl -lpthread -lm`. No KLEE, segue a rota D1. As funções puras `std::string buildLinkCommand(const Caller::LinkInputs&)` e `std::string buildFuzzerCommand(const Caller::LinkInputs&)` ficam testáveis.

- [ ] **Step 1: Teste do comando gerado**

```cpp
TEST(CallerLink, LinksOnlyTheRustRuntime) {
  Caller::LinkInputs in{"h", Map2CheckMode::MEMTRACK_MODE, NonDetGenerator::AFLPlusPlus,
                        DataStructure::Array, /*wasm=*/false, /*witness=*/false};
  std::string link = buildLinkCommand(in);
  EXPECT_EQ(link.find("${MAP2CHECK_PATH}/lib/"), std::string::npos);
  EXPECT_NE(buildFuzzerCommand(in).find("libmap2check.a"), std::string::npos);
}

TEST(CallerLink, EveryModeAndGeneratorLinksRuntime) {
  for (auto mode : {Map2CheckMode::MEMTRACK_MODE, Map2CheckMode::MEMCLEANUP_MODE,
                    Map2CheckMode::OVERFLOW_MODE, Map2CheckMode::ASSERT_MODE,
                    Map2CheckMode::REACHABILITY_MODE})
    for (auto gen : {NonDetGenerator::AFLPlusPlus, NonDetGenerator::None}) {
      Caller::LinkInputs in{"h", mode, gen, DataStructure::Array, false, false};
      EXPECT_NE(buildFuzzerCommand(in).find("libmap2check.a"), std::string::npos);
    }
}
```

Os enumeradores seguem `modules/frontend/caller.hpp:21-45` de `develop`; incluir também `COVER_BRANCHES_MODE` no laço.

- [ ] **Step 2–4:** Ver falhar, extrair as funções e implementar, `ctest --output-on-failure` verde.
- [ ] **Step 4b:** Os binários de witness (`-witness-fuzzed.out` e o `-witness-result.bc` que vai ao KLEE) ligam também um objeto gerado pelo frontend com `__attribute__((constructor)) static void m2c_witness(void) { map2check_enable_witness(); }`, compilado com `clang-16 -c` (nativo) ou `-emit-llvm` (KLEE). Os binários de verificação não o ligam. Isso reproduz a escolha `WitnessGeneration.bc` × `WitnessGenerationNone.bc` de `caller.cpp:635-640` (ruling da Task 2.4). Teste em `CallerLink`: o comando de witness contém o objeto e o de verificação não.
- [ ] **Step 5:** Se D3 = remover, adicionar o aviso de `--btree` com o seu teste.
- [ ] **Step 6: Commit (na branch)** `feat: link map2check-library instead of the C bitcode runtime`

**Critério de conclusão:** na branch, `map2check --memtrack` sobre `release/test_heap_overflow.c` imprime `VERIFICATION FAILED` e grava `map2check_property` com `FALSE-DEREF`.

### Task 3.4: CI do Map2Check na branch

**Files:** Modify (Map2Check): `.github/workflows/ci.yml`, `Dockerfile.dev`

- [ ] **Step 1:** Em `Dockerfile.dev`, baixar o tarball do release `v1.1.0-rc1` da biblioteca (gerado por `scripts/package-release.sh`), com SHA-256 fixado, extrair em `/opt/map2check-library` e passar `-DMAP2CHECK_RUST_LIB_DIR=/opt/map2check-library/lib` ao CMake. Fazer o mesmo nos jobs de build, `ctest`, `e2e-wasm` e Valgrind do `ci.yml`.
- [ ] **Step 2:** Remover do CI, **nesta branch**, os passos que compilam ou analisam o runtime C (`cppcheck` do backend C, os `.bc` e `tests/unit/backend-library` do `ctest`), já que ele saiu do build. O código continua no repositório até a Fase 6.
- [ ] **Step 3:** Abrir o PR draft `feat/rust-runtime` → `develop` e confirmar os jobs verdes. O PR fica em draft até a Task 5.1.

**Critério de conclusão:** CI verde na branch com as mesmas dependências externas (wabt 1.0.41, klee-uclibc, z3/stp) de `develop`.

---

## Fase 4 — Validação diferencial (#15, #18)

### Task 4.1: Comparador de linhas de base

**Files:**
- Create (Map2Check): `scripts/cutover/compare.py`
- Create (Map2Check): `scripts/cutover/test_compare.py`
- Create (Map2Check): `tests/cutover/deltas-aceitos.tsv` (cabeçalho `task	prp	gen	field	c_value	rust_value	sd_ref`)

**Interfaces:**
- Consumes: dois TSVs no formato da Task 0.2.
- Produces: `compare.py <c.tsv> <rust.tsv> --accepted deltas-aceitos.tsv [--max-wall 1.10] [--max-rss 1.25]`, que sai com 0 quando os critérios 1–8 passam e com 1 caso contrário, e imprime um relatório em markdown no stdout.

- [ ] **Step 1: Testes**

```python
# Testes do comparador do gate de cutover.
import subprocess, sys, textwrap, pathlib, tempfile

HERE = pathlib.Path(__file__).parent
HDR = "task\tprp\tgen\trep\tverdict\ttag\tline\tfunction\twitness\twall_s\tmaxrss_kb\n"

def run(c_rows, r_rows, accepted=""):
    d = pathlib.Path(tempfile.mkdtemp())
    (d / "c.tsv").write_text(HDR + "".join(c_rows))
    (d / "r.tsv").write_text(HDR + "".join(r_rows))
    (d / "a.tsv").write_text("task\tprp\tgen\tfield\tc_value\trust_value\tsd_ref\n" + accepted)
    return subprocess.run([sys.executable, HERE / "compare.py", d / "c.tsv", d / "r.tsv",
                           "--accepted", d / "a.tsv"], capture_output=True, text=True)

ROW = "t.yml\tvalid-memsafety\tafl\t{rep}\t{v}\t{tag}\t7\tmain\t0\t{wall}\t1000\n"

def rows(v="FAILED", tag="FALSE-DEREF", wall=1.0):
    return [ROW.format(rep=i, v=v, tag=tag, wall=wall) for i in range(1, 6)]

def test_identical_passes():
    assert run(rows(), rows()).returncode == 0

def test_verdict_change_blocks():
    p = run(rows(), rows(v="UNKNOWN", tag="-"))
    assert p.returncode == 1 and "verdict" in p.stdout

def test_accepted_delta_passes():
    acc = "t.yml\tvalid-memsafety\tafl\ttag\tFALSE-DEREF\tFALSE-FREE\tSD-06\n"
    assert run(rows(), rows(tag="FALSE-FREE"), acc).returncode == 0

def test_slowdown_over_10_percent_blocks():
    p = run(rows(wall=1.0), rows(wall=1.2))
    assert p.returncode == 1 and "wall" in p.stdout

def test_new_timeout_blocks():
    p = run(rows(), rows(v="TIMEOUT", tag="-"))
    assert p.returncode == 1 and "TIMEOUT" in p.stdout
```

- [ ] **Step 2: Ver falhar.** Run: `python3 -m pytest scripts/cutover/test_compare.py -q` → 5 erros (o arquivo não existe).
- [ ] **Step 3: Implementar**

```python
#!/usr/bin/env python3
"""Gate diferencial do cutover: compara as linhas de base C e Rust (critérios 1-8)."""
import argparse, csv, statistics, sys
from collections import Counter, defaultdict

KEY = ("task", "prp", "gen")
FIELDS = ("verdict", "tag", "line", "function", "witness")


def load(path):
    groups = defaultdict(list)
    with open(path, newline="") as f:
        for row in csv.DictReader(f, delimiter="\t"):
            groups[tuple(row[k] for k in KEY)].append(row)
    return groups


def mode(rows, field):
    return Counter(r[field] for r in rows).most_common(1)[0][0]


def median_num(rows, field):
    vals = [float(r[field]) for r in rows if r[field] not in ("-", "")]
    return statistics.median(vals) if vals else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("c"); ap.add_argument("rust")
    ap.add_argument("--accepted", required=True)
    ap.add_argument("--max-wall", type=float, default=1.10)
    ap.add_argument("--max-rss", type=float, default=1.25)
    a = ap.parse_args()
    c, r = load(a.c), load(a.rust)
    accepted = set()
    with open(a.accepted, newline="") as f:
        for row in csv.DictReader(f, delimiter="\t"):
            accepted.add((row["task"], row["prp"], row["gen"], row["field"], row["c_value"], row["rust_value"]))

    failures, wall_ratios, rss_ratios = [], [], []
    timeouts = Counter()
    for key in sorted(set(c) | set(r)):
        if key not in r or key not in c:
            failures.append(f"| {' '.join(key)} | missing | {key in c} | {key in r} |")
            continue
        for field in FIELDS:
            cv, rv = mode(c[key], field), mode(r[key], field)
            if cv != rv and (*key, field, cv, rv) not in accepted:
                failures.append(f"| {' '.join(key)} | {field} | {cv} | {rv} |")
        for side, rows in (("c", c[key]), ("rust", r[key])):
            if mode(rows, "verdict") == "TIMEOUT":
                timeouts[(key[2], side)] += 1
        cw, rw = median_num(c[key], "wall_s"), median_num(r[key], "wall_s")
        if cw and rw:
            wall_ratios.append(rw / cw)
        cm, rm = median_num(c[key], "maxrss_kb"), median_num(r[key], "maxrss_kb")
        if cm and rm:
            rss_ratios.append(rm / cm)

    for gen in {k[2] for k in c}:
        if timeouts[(gen, "rust")] > timeouts[(gen, "c")]:
            failures.append(f"| gen={gen} | TIMEOUT count | {timeouts[(gen, 'c')]} | {timeouts[(gen, 'rust')]} |")
    wall = statistics.median(wall_ratios) if wall_ratios else 1.0
    rss = statistics.median(rss_ratios) if rss_ratios else 1.0
    if wall > a.max_wall:
        failures.append(f"| all | median wall ratio | <= {a.max_wall} | {wall:.3f} |")
    if rss > a.max_rss:
        failures.append(f"| all | median rss ratio | <= {a.max_rss} | {rss:.3f} |")

    print(f"median wall ratio: {wall:.3f}  median rss ratio: {rss:.3f}\n")
    if failures:
        print("| key | field | c | rust |\n|---|---|---|---|")
        print("\n".join(failures))
        return 1
    print("gate: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Ver passar.** Run: `python3 -m pytest scripts/cutover/test_compare.py -q` → `5 passed`.
- [ ] **Step 5: Commit** `test: add differential gate comparing C and Rust runtime baselines`

**Critério de conclusão:** os cinco testes passam e o relatório é legível no log de CI.

### Task 4.2: Gate diferencial completo

- [ ] **Step 1:** Gerar `tests/cutover/baseline-rust.tsv` a partir da branch `feat/rust-runtime` e regenerar `baseline-c.tsv` a partir do merge-base da branch com `develop`, na mesma imagem e máquina da Task 0.2. Assim os dois lados veem o mesmo frontend, a menos das mudanças da Fase 3.
- [ ] **Step 2:** Run: `python3 scripts/cutover/compare.py tests/cutover/baseline-c.tsv tests/cutover/baseline-rust.tsv --accepted tests/cutover/deltas-aceitos.tsv`.
- [ ] **Step 3:** Para cada linha de falha: (a) bug do Rust → issue + correção na Fase 2 + repetir; (b) bug do C → SD novo em `docs/semantic-deltas.md` com caso reproduzível + linha em `deltas-aceitos.tsv`, **aprovada pelo mantenedor no PR**. Nunca aceitar uma divergência sem um SD.
- [ ] **Step 4:** Rodar também `tests/integration/test_wasm_*.sh` com o runtime Rust (D2) e `ctest -T memcheck` (Valgrind) com o runtime Rust.
- [ ] **Step 5:** Adicionar um job agendado semanal (`schedule: cron`) que roda as Tasks 0.2 e 4.1 com `REPS=3` e publica o relatório como artefato do CI (#18).
- [ ] **Step 6:** Commit das linhas de base e dos deltas aceitos.

**Critério de conclusão:** `gate: PASS` em duas execuções consecutivas (critério de prontidão), registradas nos PRs com os links dos jobs.

### Task 4.3: Medição de memória para D3 e D4

- [ ] **Step 1:** Rodar `run-corpus.sh` com o runtime C e `--btree`. Para isso, acrescentar temporariamente `--btree` a `flags_for` via a variável `EXTRA_FLAGS`, adicionada ao script com o teste correspondente em `test-run-corpus.sh`. Usar o corpus regular e as 5 maiores tarefas (por linhas) de `MemSafety-Arrays.set`.
- [ ] **Step 2:** Comparar o pico de RSS: C+BTree × C+Array × Rust.
- [ ] **Step 3:** Registrar a tabela em `docs/cutover/perf.md` e as decisões D3/D4 em `docs/cutover/decisoes.md`, com aprovação do mantenedor.

**Critério de conclusão:** D3 e D4 têm números e aprovação.

---

## Fase 5 — Merge da migração (reversível por revert)

### Task 5.1: Mergear `feat/rust-runtime`

- [ ] **Step 1:** Rebasear a branch sobre `develop`, regenerar as duas linhas de base no mesmo commit-base (C a partir do merge-base, Rust a partir da branch; Task 4.2, Step 1) e confirmar `gate: PASS` pela segunda vez consecutiva (critério de prontidão).
- [ ] **Step 2:** Ensaiar o rollback antes do merge. Em um clone descartável, fazer o merge local, depois `git revert -m 1 HEAD`, build e `ctest`. Registrar no PR que o revert restaura o runtime C e passa.
- [ ] **Step 3:** README do Map2Check: na seção de build, documentar `MAP2CHECK_RUST_LIB_DIR`/`MAP2CHECK_RUST_SRC` e a versão mínima da biblioteca. CHANGELOG: entrada "Runtime replaced by map2check-library (Rust)".
- [ ] **Step 4:** Tirar o PR de draft e mergear com **merge commit** (não squash, não rebase), para que um único `git revert -m 1` desfaça tudo. Anotar o hash do merge no PR e em `docs/cutover/decisoes.md`.
- [ ] **Step 5:** Publicar uma release do Map2Check.
- [ ] **Step 6:** Período de observação de **um ciclo de release**. Toda regressão reportada é triada; se for de runtime e não tiver correção rápida, o rollback é `git revert -m 1 <merge>` em `develop` + issue + nova release.

**Critério de conclusão:** uma release publicada com o runtime Rust, nenhum revert acionado e o gate 4.2 verde de novo ao fim do ciclo.

### Task 5.2: Portar as asserções dos testes unitários C

**Files:** ler `Map2Check/tests/unit/backend-library/{AllocationLog,BTree,Container,HeapLog,MemTrack}Test.cpp`; criar o equivalente em `rust/src/ffi_tests.rs`.

- [ ] **Step 1:** Para cada `TEST(...)`/`EXPECT_*`, escrever um `#[test]` com o mesmo nome em snake_case e a mesma asserção sobre o export núcleo equivalente (segundo `docs/cutover/abi-mapping.tsv`). Os testes de `BTree` só migram se D3 = portar; se não, cada um é listado em `docs/cutover/decisoes.md` (D3) como coberto pela decisão.
- [ ] **Step 2:** Rodar `cargo test --all-features`.
- [ ] **Step 3:** Commit `test: port Map2Check C runtime unit assertions to Rust`.

**Critério de conclusão:** a tabela de correspondência `TEST C → #[test] Rust` está em `docs/cutover/decisoes.md` e todos passam.

---

## Fase 6 — Remoção do C (contém o PONTO DE NÃO-RETORNO)

**Ponto de não-retorno:** o merge, em `develop` do Map2Check, do PR da Task 6.2. Antes dele, o runtime C ainda está no repositório (fora do build) e o merge da Task 5.1 pode ser revertido com `git revert -m 1`. Depois dele, voltar ao C exige reverter também a remoção ou partir de `legacy/c-runtime-final`; o plano trata isso como fora do caminho normal.

**Pré-condições (todas obrigatórias, conferidas no PR):**
- [ ] Task 5.1 concluída (um ciclo de release sem revert).
- [ ] Gate 4.2 com `gate: PASS` sobre o commit-base do PR.
- [ ] D1–D4 registradas e aprovadas.
- [ ] Nenhuma issue aberta com o label `area:memtrack`/`kind:bug` sem triagem.

### Task 6.1: Atualizar a tag de preservação

- [ ] **Step 1:** `git tag -s -f legacy/c-runtime-final origin/develop -m "Último commit com o runtime C (antes da remoção)" && git push -f origin legacy/c-runtime-final`, e anotar o hash no PR da Task 6.2.
- [ ] **Step 2:** Ensaiar a recuperação: em um clone descartável, `git checkout legacy/c-runtime-final`, build e `ctest`. Como a tag aponta para o commit antes da remoção (e depois do merge da 5.1), o ensaio também roda `git revert -m 1 <merge da 5.1>` e confirma que o runtime C volta a compilar e passar no `ctest`.

**Critério de conclusão:** o rollback foi ensaiado com sucesso e registrado no PR.

### Task 6.2: Remover o runtime C, do menos ao mais acoplado

Um PR, um commit por grupo, e **cada commit** mantém o build + `ctest` + `run-corpus.sh` (com `REPS=1`, como verificação rápida) verdes. Desde a Task 3.1 o runtime C está fora do build, então os commits só apagam código morto; a ordem, das folhas que nenhum outro `.c` usa até o núcleo, mantém cada commit revisável e revertível isoladamente.

- [ ] **Commit 1:** `WitnessGenerationNone.c`, `AnalysisModeNone.c`, `NonDetGeneratorNone.c` (variantes vazias; nenhum outro arquivo depende delas).
- [ ] **Commit 2:** `ContainerRealloc.c`, `ContainerBTree.c`, `BTree.c`, `BTree.h` (containers; só os logs dependem deles, e os logs já não são ligados).
- [ ] **Commit 3:** `TrackBBLog.c`, `NonDetLog.c`.
- [ ] **Commit 4:** `PropertyGenerator.c`, `WitnessGeneration.c` (canal de resultado; Rust coberto pela Task 2.4).
- [ ] **Commit 5:** `AnalysisModeAssert.c`, `AnalysisModeOverflow.c`.
- [ ] **Commit 6:** `AllocationLog.c`, `ListLog.c`, `HeapLog.c`, `AnalysisModeMemtrack.c`, `AnalysisModeMemcleanup.c`.
- [ ] **Commit 7:** `NonDetGeneratorAFL.c`, `NonDetGeneratorKlee.c`.
- [ ] **Commit 8:** `WasmRuntimeStubs.c`.
- [ ] **Commit 9:** `Map2CheckFunctions.c` (núcleo; todos dependem dele), `header/*.h`, `lib/CMakeLists.txt`, `lib/NOTE.txt`, `CMakeLists.txt`, `NOTES.txt` e o diretório `modules/backend/library/`.
- [ ] **Commit 10:** `tests/unit/backend-library/` (as asserções já estão em Rust, Task 5.2) e a sua entrada em `tests/CMakeLists.txt`.
- [ ] **Commit 11:** remover os resíduos do runtime C no frontend: constantes e comentários de `caller.cpp`/`caller.hpp` que citam os `.bc` C (o ramo de link já foi trocado na Task 3.3), e qualquer `#include` de `modules/backend/library/header`.
- [ ] **Commit 12:** em `modules/backend/library/NOTES.txt` não há mais nada a migrar (o conteúdo foi para `integration-guide.md` na Task 6.4); confirmar com `git grep -n 'backend/library'` que só restam notas históricas.
- [ ] **Verificação final:** `grep -rnE 'backend/library|\.bc"' modules/frontend | grep -v -- '-output.bc\|-result.bc\|-compiled.bc'` não retorna nada.

**Critério de conclusão:** o PR foi mergeado; o CI do Map2Check passa sem a coluna `c`; a busca acima retorna vazio.

### Task 6.3: CI e ferramentas de análise

- [ ] **Step 1:** Conferir que o `ci.yml` já não tem passos do runtime C (removidos na Task 3.4) e atualizar `.cppcheck-suppressions.txt` e `.clang-tidy` se ainda citarem `modules/backend/library`.
- [ ] **Step 2:** Adicionar ao Map2Check uma versão de `scripts/check-no-c-era-artifacts.sh` (copiada deste repo) com o padrão `^modules/backend/library/` e o seu teste.

**Critério de conclusão:** a guarda falha se alguém reintroduzir o diretório; o CI passa.

### Task 6.4: Documentação

- [ ] **Map2Check `README.md`:** a seção de arquitetura passa a dizer que o runtime é `map2check-library` (Rust), com a versão mínima, o link e como fixar uma versão.
- [ ] **Map2Check `CLAUDE.md`, `docs/`, `modules/backend/pass/NOTES.txt`:** trocar referências a `modules/backend/library` pelos fontes Rust. As instruções de "como adicionar um tipo nondet" (`modules/backend/library/NOTES.txt`) migram para `map2check-library/docs/integration-guide.md`.
- [ ] **Este repo `README.md` e `CLAUDE.md`:** declarar que esta biblioteca é **o** runtime do Map2Check e citar `legacy/c-library-final` e `legacy/c-runtime-final` como referências históricas.
- [ ] **Este repo `TODO.md`:** marcar os itens concluídos e mover a seção "Dependente do repositório externo" para "Concluído", com os links dos PRs.
- [ ] **Este repo `docs/plano_map2check_library_rust.md` e `audit/`:** acrescentar uma nota no topo dizendo que o documento é histórico e apontando para este plano. Não reescrever evidência.
- [ ] **CHANGELOGs dos dois repositórios:** uma entrada de remoção, com o hash da tag de preservação.

**Critério de conclusão:** `grep -rn 'backend/library' README.md CLAUDE.md docs/` no Map2Check só aponta para notas históricas.

---

## Fase 7 — (removida)

A migração dos passes para a API núcleo, antes prevista aqui, virou a Task 3.2 por causa da D5. Não há camada de compatibilidade a aposentar depois do cutover.

---

## Execution order (resumo)

0.1 → 0.2 → 0.3 → **1.1 (D1, aprovação)** → 1.2 → 2.1 → 2.2 → 2.3 → 2.4 → 2.5 → (2.6 depois de 4.3) → 2.7 → 2.8 → 2.9 → 3.1 → 3.2 → 3.3 → 3.4 → 4.1 → 4.3 → 4.2 → 5.1 → 5.2 → 6.1 → **6.2 (não-retorno)** → 6.3 → 6.4.
