# TODO — paridade da implementação Rust

Comparação feita entre `master` (`05b232a02a69d2a14114df9b34172e56f6365a7c`)
e `feature/rust` (`417441b081c46815b42371a14af0ee5daccc08a4`), antes deste
relatório. O escopo é a paridade da biblioteca neste repositório; a integração
com os passes e o frontend do projeto Map2Check não foi validada aqui.

Os módulos centrais de assert, overflow, memória, rastreamento de blocos,
nondeterminismo e JSON já existem em Rust. As tarefas abaixo registram lacunas
de ABI, comportamento e validação encontradas na comparação.
As atividades adicionais abaixo foram extraídas de
[docs/plano_map2check_library_rust.md](docs/plano_map2check_library_rust.md)
e não repetem as tarefas já listadas.

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

## Outras atividades do plano

### Prioridade alta — robustez e cobertura do contrato

- [ ] **Impedir que falhas atravessem a fronteira FFI sem tratamento.**
  Definir o comportamento de panic por perfil de compilação e proteger exports
  `extern "C"` contra unwinding quando o perfil permitir recuperação; no perfil
  `panic = "abort"`, documentar que não há recuperação. Adicionar um harness C
  que exercite exports antes da inicialização e entradas válidas de borda, e
  executar verificações com ASan/UBSan. Não passar ponteiros inválidos
  arbitrários: eles podem causar comportamento indefinido antes de qualquer
  validação Rust.

- [ ] **Completar ou descontinuar explicitamente os símbolos nondet restantes.**
  Decidir o contrato para `__VERIFIER_nondet_pointer`,
  `__VERIFIER_assume`, `__VERIFIER_assert`, `__VERIFIER_error`,
  `map2check_fuzzer_assume` e os geradores `pchar`, `loff_t` e `sector_t`;
  implementar os que têm consumidores e registrar a remoção dos demais.
  Verificar as assinaturas/representações C e incluir testes de link e execução.

- [ ] **Cobrir a API C com programas de integração.** Compilar, linkar e
  executar `test/codeAPI_by_caller_test.c`,
  `test/codefuzz_by_caller_test.c` e `test/codeklee_by_caller_test.c` contra a
  biblioteca gerada; manter esses casos como testes de CI, além dos testes
  unitários Rust.

### Prioridade média — build, KLEE, desempenho e documentação

- [ ] **Corrigir e tornar estritos os builds de release e CI.** Corrigir os
  caminhos/estágios do Dockerfile para os diretórios Rust e testes atuais;
  alinhar a versão Rust entre Dockerfile, `rust-toolchain.toml` e README; validar
  que geração do header, lint, formato, auditoria de dependências e cobertura
  executem no CI; remover artefatos de build legados que não sejam mais usados.
  Falhas na geração ou no link de bitcode não devem ser mascaradas por `|| true`.

- [ ] **Executar o gate de viabilidade de KLEE e registrar a decisão.**
  Prototipar a feature `klee` com nondeterminismo via `klee_make_symbolic`,
  estado compatível com execução simbólica e emissão/link de bitcode; testar o
  programa KLEE de referência com uma versão LLVM compatível. Registrar
  evidências, limitações e a decisão go/no-go em
  `docs/klee-feasibility.md`; se Rust não for viável, formalizar a contingência
  de manter a biblioteca C nesse fluxo.

- [ ] **Medir e controlar a regressão de desempenho.** Criar benchmarks
  reproduzíveis contra a biblioteca C, usando programas de referência e corpus
  fixo para LibFuzzer; registrar medições e perfis quando o overhead exceder
  10%. Adicionar execução periódica no CI e definir a regressão máxima aceitável
  como 10% na mediana.

- [ ] **Documentar desvios, compatibilidade e release.** Manter uma matriz de
  símbolos/assinaturas com os desvios deliberados (`docs/api-deltas.md`),
  classificar diferenças semânticas com casos reproduzíveis
  (`docs/semantic-deltas.md`), atualizar o changelog e publicar o header C e
  guia de integração junto à versão liberada.

### Dependente do repositório externo `hbgit/Map2Check`

- [ ] **Adicionar uma camada de compatibilidade para os passes atuais.**
  Em `map2check-library`, implementar uma feature isolada que exporte os nomes
  e assinaturas usados pelos passes de `Map2Check@develop`, delegando à API
  núcleo; incluir a matriz completa de símbolos e resolver/documentar a colisão
  de assinatura de `map2check_check_deref`. Excluir explicitamente símbolos
  wasm se permanecerem fora do escopo.

- [ ] **Compatibilizar o canal de resultado legado.** Além do JSON, implementar
  a escrita dos arquivos-sentinela `map2check_property_*` nos nomes e formatos
  aceitos pelo parser atual do Map2Check. Adicionar golden tests para arquivos
  e JSON e validar propriedade, linha e função contra saídas da biblioteca C
  embutida.

- [ ] **Integrar Rust ao CMake do Map2Check sob uma opção opt-in.** No
  repositório `hbgit/Map2Check`, adicionar `MAP2CHECK_RUST_RUNTIME` inicialmente
  desligada, compilar/linkar `libmap2check.a` nos fluxos nativos e aplicar a
  decisão de KLEE registrada acima. Impedir link simultâneo de runtimes com
  símbolos duplicados e testar a opção com uma regressão pequena.

- [ ] **Migrar consumidores e aposentar a compatibilidade somente após paridade.**
  Após um ciclo de regressão sem diferenças não adjudicadas, migrar os passes
  para a API núcleo e o frontend para o JSON; então remover a camada compatível
  e o runtime C embutido apenas quando não houver símbolos ou consumidores
  órfãos. Manter a opção de retorno ao runtime antigo durante a transição.

- [ ] **Aplicar critérios de prontidão antes de promover a integração.**
  Exigir cobertura dos símbolos necessários, regressões sem divergências não
  adjudicadas, overhead dentro do limite acordado, fluxos None/LibFuzzer e a
  decisão KLEE verificados, além da documentação e release versionada. Adiar a
  promoção para default se qualquer gate estiver pendente.
