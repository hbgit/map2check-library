# TODO — paridade da implementação Rust

Comparação feita entre `master` (`05b232a02a69d2a14114df9b34172e56f6365a7c`)
e `feature/rust` (`417441b081c46815b42371a14af0ee5daccc08a4`), antes deste
relatório. O escopo é a paridade da biblioteca neste repositório; a integração
com os passes e o frontend do projeto Map2Check não foi validada aqui.

Os módulos centrais de assert, overflow, memória, rastreamento de blocos,
nondeterminismo e JSON já existem em Rust. As tarefas abaixo registram lacunas
de ABI, comportamento e validação encontradas na comparação.

## Prioridade alta — compatibilidade e correção

- [ ] **Alinhar a ABI C com a biblioteca Rust.** Exportar ou justificar a
  remoção dos pontos de entrada existentes em `master`, incluindo
  `get_next_step`, `map2check_map_non_static_alloca`,
  `map2check_map_funct_address` e
  `map2check_check_free_resolved_address`. Alinhar também as assinaturas de
  `map2check_save_nondet_log_*`: em C elas recebem tipo e ponteiro para o
  valor e retornam um registro; em Rust recebem o valor diretamente e retornam
  `void`. Documentar explicitamente qualquer mudança intencional de contrato
  e regenerar/verificar [include/map2check.h](include/map2check.h) a partir da
  ABI efetiva. Referências: [ffi.rs](rust/src/ffi.rs#L143) e as declarações C
  em `master:include/nondet/nondetlog.h`,
  `master:include/caller/caller_lib_result.h` e
  `master:include/memtrack/container_memtracklog.h`.

- [ ] **Implementar a semântica das opções de segurança de memória.**
  `map2check_set_memcleanup()` e `map2check_set_null_is_valid()` são stubs
  vazios, e `map2check_check_load()` sempre passa `is_null_valid: false`.
  Armazenar essas opções no estado da análise e aplicá-las nos checks; preservar
  também o comportamento de `map2check_check_mem_endprog()` para os modos com
  e sem verificação de cleanup. Referências:
  [ffi.rs](rust/src/ffi.rs#L150),
  [memory.rs](rust/src/analysismode/memory.rs#L15) e
  `master:src/analysismode/analysis_memory.c`.

- [ ] **Corrigir a validação de endereços após `free`.** `is_invalid_address()`
  aceita um endereço se encontrar qualquer registro histórico não liberado.
  Como o registro de `free` é acrescentado sem remover o da alocação, um
  acesso posterior pode continuar sendo tratado como válido. Fazer a decisão
  considerar o evento mais recente aplicável à alocação e cobrir uso após
  liberação, realocação e limites de faixa com testes. Referências:
  [memtrack/mod.rs](rust/src/memtrack/mod.rs#L126) e
  [ffi.rs](rust/src/ffi.rs#L334).

- [ ] **Restaurar ou substituir explicitamente a API de geração LibFuzzer.**
  A implementação Rust exporta `__VERIFIER_nondet_*`, enquanto a biblioteca C
  ativa expõe `map2check_gen_data_fuzzer_*` e
  `map2check_fuzzer_assume`. Implementar os símbolos ainda consumidos ou
  migrar/documentar os consumidores para a nova API; verificar a tabela de
  símbolos e executar um programa C linkado contra a biblioteca Rust.
  Referências: [libfuzzer.rs](rust/src/nondet/libfuzzer.rs#L21) e
  `master:include/nondet/nondet_gen_libfuzzer.h`.

- [ ] **Manter o formato JSON compatível com o consumidor existente.** Os
  nomes dos containers divergem (`container_trackbb_log`,
  `container_nondet_log`, `container_memtrack_log` em C; `Container_BasicBlockLog`,
  `Container_NonDetLog`, `Container_AllocationLog` em Rust). Também divergem os
  campos dos registros: C usa `var_mem_address` e `mem_address_points_to`,
  Rust usa `var_addr` e `points_to`; o registro C nondet usa `type` numérico e
  `value` escalar, Rust serializa `value` como enum marcado. Rust ainda emite
  `function_name` no nível do resultado, ausente no JSON C. Definir o schema
  suportado e cobri-lo com snapshots/testes de compatibilidade. A formatação
  compacta versus indentada, isoladamente, não altera o significado JSON.
  Referências:
  [output/mod.rs](rust/src/output/mod.rs#L17),
  [memtrack/mod.rs](rust/src/memtrack/mod.rs#L9) e
  [nondet/mod.rs](rust/src/nondet/mod.rs#L9).

## Prioridade média — estado e integração

- [ ] **Resetar o estado entre análises e iterações de fuzzing.**
  `map2check_init()` chama `OnceLock::get_or_init()` e, portanto, não limpa
  contadores nem containers em chamadas subsequentes. Aplicar o reset do estado
  nos limites de ciclo de vida apropriados e testar duas inicializações e duas
  iterações LibFuzzer consecutivas, garantindo resultados independentes.
  Referências: [ffi.rs](rust/src/ffi.rs#L77),
  [state.rs](rust/src/state.rs#L24) e
  [libfuzzer.rs](rust/src/nondet/libfuzzer.rs#L21).

- [ ] **Validar os fluxos de build e testes C/KLEE/LibFuzzer.** A feature Cargo
  `klee` não tem implementação específica (`Cargo.toml` a declara, mas não há
  uso correspondente em `rust/src`); o Dockerfile tolera falhas ao emitir/linkar
  bitcode (`|| true`), e os scripts de integração ainda pressupõem o layout C
  em `build/`. Decidir e registrar se KLEE terá suporte Rust ou uma contingência
  C; em ambos os casos, fazer os builds falharem quando o artefato esperado
  estiver ausente e adicionar testes de link/execução C ao CI. Referências:
  [Cargo.toml](Cargo.toml#L25), [Dockerfile](Dockerfile#L30),
  [CI.yml](.github/workflows/CI.yml#L1),
  [run_klee_test.sh](run_klee_test.sh#L1) e
  [run_libfuzzer_test.sh](run_libfuzzer_test.sh#L1).

- [ ] **Adicionar testes diferenciais contra a implementação C.** Comparar,
  para programas de referência, ABI/símbolos, veredito, propriedade, linha e
  schema JSON entre `master` e Rust. Classificar divergências intencionais e
  executar os casos no CI; os testes unitários existentes não demonstram essa
  paridade ponta a ponta.
