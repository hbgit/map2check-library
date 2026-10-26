# D7: layout dos 21 módulos `.bc` do runtime drop-in (spike da Task 1.1)

Data: 2026-10-26. Alvo: Map2Check `develop` `3e914528ec57` (cópia em `vendor/map2check/`), imagem `map2check-dev:develop-3e914528ec57` (clang/LLVM 16.0.6, KLEE 3.1, AFL++ 4.40c). Rust: rustc 1.72.1 (LLVM 16.0.5), rota A′ da D1 (fat LTO, `panic = "abort"`, `--emit=llvm-bc`, `opt-16 --strip-debug`).

Protótipo: `spikes/d7-layout/` (fora do build da crate). Matriz: `scripts/it/check-link-matrix.sh`.

**Status: aprovada pelo usuário em 2026-10-26: layout A-fwd com exceção à restrição de IR (item 1a), símbolos internos do C não exportados com delta `SD-22` (item 2) e itens 3–6 fixos.**

## Pergunta

O frontend (`Caller::linkLLVM`) liga, com `llvm-link`, o `<hash>-output.bc` do programa a um conjunto fixo de módulos por combinação: os 4 sempre presentes (`Map2CheckFunctions`, `TrackBBLog`, `NonDetLog`, `PropertyGenerator`), 1 ou 2 de container, 1 a 4 de modo, 1 de gerador, opcionalmente `WasmRuntimeStubs`, e `WitnessGeneration` (o `-witness-result.bc`) ou `WitnessGenerationNone` (o `-result.bc`). São 2 × 5 × 3 × 2 × 2 = 120 combinações. O runtime Rust precisa caber nesses 21 nomes de arquivo sem mudar o frontend. Em particular:

- o Rust compila uma crate para **um** módulo (com `std` dentro, por LTO fat). Dois módulos com `std` cada um dariam símbolos duplicados;
- `main` é definido pelo gerador. O do AFL++ precisa de `setjmp`/`longjmp`, que o Rust não expressa;
- os intrínsecos `klee_*` e `__afl_*` só existem sob KLEE e no link do `afl-clang-fast`. Um módulo que os referencia em toda combinação deixa símbolos indefinidos nas outras.

## Estratégias medidas

| Id | Descrição | Protótipo |
|---|---|---|
| **A-lit** | A do plano ao pé da letra: `Map2CheckFunctions.bc` = runtime Rust inteiro, inclusive a lógica dos geradores; os módulos de gerador são `.ll` que definem `main` e um global forte `__m2c_sel_generator` sobre o padrão fraco do núcleo; `klee_make_symbolic` e o gancho de rejeição do AFL++ viram `extern_weak` no pós-processamento. `main` + `setjmp` do AFL++ em `.ll` (obrigatório: o Rust não tem `setjmp`). | `build.sh alit`, feature `a_literal` de `core/` |
| **A-fwd** | A refinada: `Map2CheckFunctions.bc` = núcleo Rust (estado e lógica) + um trecho `.ll` com `map2check_assume`/`crab_assume`/`assume_loop`. Cada um dos outros 20 módulos é `.ll` que define **exatamente as funções externas que o módulo C homônimo define**, como encaminhadores para pontos de entrada `__m2c_rt_*` do núcleo. Os intrínsecos ficam só nos `.ll` de gerador (`klee_*` no Klee, `__afl_*` e `setjmp`/`longjmp` no AFL). Sem globais de seleção, sem `extern_weak`. | `build.sh fwd` |
| **B** | Geradores como crates Rust `no_std` próprias (`staticlib`, fat LTO, `--emit=llvm-bc`), ligadas ao núcleo. O AFL++ ainda precisa de `main` + `setjmp`/`longjmp` + `nondet_assume` em `.ll`, ligado dentro do `NonDetGeneratorAFL.bc`. Demais módulos como em A-fwd. | `build.sh b`, `gen-b/{none,klee,afl}` |
| **B-loop** | B com o laço persistente do AFL++ em Rust e **sem `longjmp`**: um `assume` falso encerra o processo (`_exit(0)`), e o afl-fuzz recomeça pelo fork server. | `build.sh b-loop`, `gen-b/afl-loop` |

Escopo do protótipo (ruling da Task 1.1): cobre o que o programa de fumaça alcança (núcleo, rastreio de blocos, log de nondet, arquivo de propriedade, assert, overflow, arquivos do witness, os três geradores completos). As entradas de memtrack/memcleanup/wasm são stubs gerados de `inventory.tsv`.

### Pós-processamento do núcleo (todas as estratégias)

`spikes/d7-layout/build.sh`, dentro da imagem:

1. `opt-16 --strip-debug` (condição 6 da D1);
2. `scripts/klee-stub-symbolizer.py` e `opt-16 -passes=globaldce` (o mesmo de `scripts/build-klee-runtime.sh`);
3. **novo:** `spikes/d7-layout/scripts/stub_personality.py`: o corpo de `rust_eh_personality` vira `abort()`. O `std` pré-compilado é `panic = unwind`; sem isso o personality fica e puxa o unwinder (`_Unwind_*`, de `libgcc_s`) para **todas** as 120 combinações. Com `panic = "abort"` nada desenrola, então o corpo é morto;
4. `scripts/klee-lower-intrinsics.py` (intrínsecos vetoriais que o KLEE 3.1 não executa);
5. **novo:** `opt-16 -passes=internalize,globaldce` com a lista pública = os 192 símbolos de `docs/runtime-abi/inventory.tsv` + `__m2c_*`. Sem isso o núcleo exportava ~180 símbolos do `std`/`core` com nome mangled (`_ZN4core3fmt5write...`, `rust_panic`, `rust_begin_unwind`), que podem colidir com o programa e, em B, com outra crate Rust do mesmo toolchain (mesmo hash de mangling). Depois do passo, o núcleo de A-fwd exporta só `map2check_*`, `__VERIFIER_error`, `nondet_log_{init,destroy}`, `write_property` e `__m2c_rt_*`.
6. **novo (fix round 1):** a triple do núcleo (e das crates de B) passa de `x86_64-unknown-linux-gnu` para `x86_64-pc-linux-gnu`, a do clang-16 que compila o programa e o runtime C, e o module flag `"Dwarf Version"` (4 no rustc 1.72, 5 no clang-16) é removido (`scripts/drop_dwarf_flag.py`). O frontend não redireciona o stderr do `llvm-link`, então sem isso cada execução imprimia avisos de triple e de flag. Medido: `llvm-link-16` de uma combinação memtrack+btree+wasm+witness com os três geradores, em A-fwd, B e B-loop, tem stderr vazio.

## Matriz de link (`scripts/it/check-link-matrix.sh`)

Programa de fumaça: `scripts/it/smoke/link-smoke.c` (seguro: `malloc` de tamanho fixo, soma num laço limitado por um nondet, verificação com `reach_error`), instrumentado pelo próprio Map2Check instalado (`target/map2check-it/c`), uma vez por modo, guardando o `<hash>-output.bc` (ruling R2). Modos: `--memtrack`, `--memcleanup-property`, `--check-overflow`, `--check-asserts`, `--target-function --target-function-name reach_error` (o modo `none`, que liga `AnalysisModeNone.bc`).

Critérios por combinação: `llvm-link-16` sem erro; `llvm-nm-16 --undefined-only` (fortes e weak) contido em libc/libm da imagem, mais `klee_*` (symex), `__afl_*` (afl), `wasm_rt_*` (wasm); link nativo `clang-16` (gerador none) e `afl-clang-fast -g -O2 ... -lm` (afl). Opcional, com `--ref <lib do C>`: paridade dos símbolos externos definidos (seção abaixo).

Exceção: `__dso_handle` é aceito **só como referência weak** (`w` no `llvm-nm`). O `std` o referencia assim (destrutores de `thread_local`), e o `crtbegin.o` de todo executável o define. Uma referência forte a ele reprova a combinação (fixture `dso` do teste). É um desvio do texto "libc/libm" do plano.

| Biblioteca | Resultado | Falhas |
|---|---|---|
| C (`target/map2check-it/c/lib`) | **120/120 PASS** | — |
| A-lit | **0/120 PASS, matrix: FAIL** | gen none: `__m2c_afl_reject klee_make_symbolic` indefinidos (weak); gen symex: `__m2c_afl_reject`; gen afl: `klee_make_symbolic` (40 cada) |
| A-fwd | **120/120 PASS** | — |
| B | **120/120 PASS** | — |
| B-loop | **120/120 PASS** | — |

O link nativo de A-lit com gerador none funciona (weak indefinido vira nulo; `./a.out` termina com `NONE` no arquivo de propriedade), mas a regra de símbolos permitidos da matriz reprova a estratégia, como previsto: referências `extern_weak` a intrínsecos aparecem em combinações onde o gerador não é aquele.

## Paridade de símbolos definidos (`check-link-matrix.sh --ref`, fix round 1)

Para cada combinação, `--ref target/map2check-it/c/lib` liga também a combinação do C sobre o mesmo programa de fumaça e compara os símbolos externos definidos (`llvm-nm-16 --defined-only --extern-only`). Toda diferença precisa estar em `docs/runtime-abi/export-policy.tsv`. A política lista 76 nomes `c-only` e o glob `__m2c_rt_*` `rust-only`:

- os 76 `c-only` são as funções e globais do C que **só o próprio runtime C usa** (`referenced_by` = `-` ou `runtime` no inventário; nenhum tem consumidor `pass`, `frontend` ou `external`);
- o `rust-only` são os pontos de entrada que o IR chama no núcleo.

| Biblioteca | `--ref` com a política | Diferenças fora da política |
|---|---|---|
| A-fwd | **120/120 PASS** | nenhuma |
| B | **80/120, matrix: FAIL** | as 40 combinações afl: `extra map2check_afl_index` (estático no C; em B é um `static` Rust exportado porque o `main` em IR o escreve) |

Sem política, A-fwd difere do C exatamente nos 76 nomes. Todo símbolo de `pass`, `frontend` ou `external` que o C define numa combinação, A-fwd também define nela.
Depois da correção do `gen_ll.py` isso inclui `wasm_rt_trap(enum wasm_rt_trap_t)`: o `WasmRuntimeStubs.bc` de A-fwd define as 10 funções do C, contra 9 antes. A primeira versão descartava em silêncio as assinaturas com `enum`. Agora `enum` vira `i32`, e uma assinatura que o script não sabe traduzir é erro, salvo as 9 auxiliares `runtime` com struct por valor da lista `STRUCT_BY_VALUE_EXEMPT`.

## KLEE (`spikes/d7-layout/measure-klee.sh`)

`map2check --debug --nondet-generator symex --timeout 30 <modo> link-smoke.c` com a instalação do C e com cópias dela em que só `lib/*.bc` foi trocado (`cp -a` da instalação + os 21 `.bc` da estratégia). `SUCCEEDED` significa que `kleeDroppedPaths()` do frontend devolveu vazio (TRUE exige exploração exaustiva).

| Instalação | memtrack | memcleanup | overflow | assert | none |
|---|---|---|---|---|---|
| C | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED |
| A-fwd¹ | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED |
| A-lit | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED |
| B | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED |

¹ No protótipo, memtrack e memcleanup de A-fwd, A-lit e B são stubs: `analysis_is_program_correct` devolve 1 e as entradas de memória não fazem nada. Nesses dois modos a tabela mostra só que o núcleo, o rastreio e o gerador KLEE não descartam caminhos; ela não mostra que a análise de memória é exaustiva sob KLEE. Depois do fix round 1 (triple, flag DWARF, `wasm_rt_trap`), A-fwd e B foram remedidos com o mesmo resultado nos 5 modos.

Em todas as 20 execuções: 11 caminhos completos, 0 parciais, 11 testes, nenhum `.err`/`.early`, nenhum "silently concretizing", "skipping fork" ou "over memory cap". Instruções executadas no modo none: C 104 383, A-fwd 62 072.

Sanidade (modo none, symex, sem `--debug`): `progs/magic.c` (`x == 0x13572468 && y > 7`) dá `VERIFICATION FAILED`, "FALSE: Target Reached", linha 11, em C, A-fwd, A-lit e B; `progs/assume.c` (`__VERIFIER_assume(0 <= n <= 8)`) dá `VERIFICATION SUCCEEDED` nas quatro.

## AFL++ (`spikes/d7-layout/measure-afl.sh`)

O frontend compila os binários (`map2check --debug --nondet-generator afl`, ou seja `afl-clang-fast -g -O2` e o companheiro `AFL_LLVM_CMPLOG=1`). Depois o afl-fuzz roda 5 vezes **em sequência**, com o ambiente e os flags de `Caller::executeAnalysis`: `AFL_NO_UI=1 AFL_NO_AFFINITY=1 AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_CRASHING_SEEDS_AS_NEW_CRASH=1 AFL_BENCH_UNTIL_CRASH=1 timeout <s> afl-fuzz -i <semente "A"> -o afl-out -c <cmplog> -- <fuzzed>`. Modo none (`--target-function --target-function-name reach_error`), em que o trabalho por execução é o mesmo nos dois runtimes (init, rastreio de blocos, log de nondet, gravação de `map2check_property`). Seguros: 20 s; `magic`: até o crash, limite 30 s. Medianas de 5:

| Programa | C | A-fwd | B | B-loop |
|---|---|---|---|---|
| `link-smoke` exec/s | 49 296 | 50 352 (**102%**) | 49 722 (101%) | 50 238 (102%) |
| `assume` exec/s (rejeita ~todas as entradas) | 110 395 | 104 981 (**95,1%**) | 105 272 (95,4%) | 7 247 (**6,6%**) |
| `magic` (CmpLog): ms até o 1º crash | 434 | **233** | 219 | 223 |
| `magic`: execs até o 1º crash | 12 986 | 1 855 | 1 226 | 946 |
| `magic`: crashes em 5 campanhas | 5/5 | 5/5 | 5/5 | 5/5 |

As medianas são da build anterior ao fix round 1. A build nova muda a triple, o flag DWARF e o stub `wasm_rt_trap`, nada que o AFL++ execute. Conferência de 1 rodada na build nova: `assume` 106 575 exec/s (10 s), `magic` com crash em 235 ms.

Faixas: `link-smoke` C 38 134–52 962, A-fwd 39 991–50 772. `assume` C 108 930–116 354, A-fwd 100 567–111 795. Operador do crash (`op:`): C its×3, havoc×2; A-fwd its×3, havoc×2; B its×4; B-loop its×5.

**Decisão do AFL++:** `main` + `setjmp` em IR, com `nondet_assume` → `longjmp` também em IR (A-fwd e B). O laço sem `longjmp` (B-loop) perde 93% do throughput quando o programa rejeita entradas, porque cada rejeição encerra o processo e custa um fork. No A-fwd o `longjmp` nunca atravessa um frame Rust: `map2check_assume` é IR (trecho `.ll` do `Map2CheckFunctions.bc`) e chama o `nondet_assume` do gerador direto do frame do programa; o núcleo não segura nenhum lock nesse caminho.

## Recomendação: A-fwd

A-fwd atende os três critérios do Step 4: matriz 120/120 PASS; KLEE sem caminho descartado nos 5 modos; AFL++ com 102% e 95% do throughput do C (critério ≥ 90%) e crash do valor mágico em 233 ms contra 434 ms do C.

Por que A-fwd e não B, que também passa:

- **Um só módulo Rust.** B põe duas crates Rust na mesma ligação. Isso só funciona porque o `internalize` esconde os símbolos do `core`. Sem ele, os dois módulos exportariam as mesmas funções mangled do `core` (mesmo toolchain, mesmo hash) e o `llvm-link` falharia ao usar `core::fmt` nos dois. B também quadruplica as crates presas ao rustc 1.72 (núcleo + 3 geradores, com manifestos e lockfiles v3 próprios; custo (a)–(b) da D1).
- **B não elimina o IR.** O gerador AFL++ de B ainda precisa de `main`, `setjmp`/`longjmp`, `nondet_assume` e dos globais `__afl_*` em `.ll`. A diferença para A-fwd é onde fica a lógica dos geradores (próximo item).
- **O grafo de módulos do C é preservado.** Em A-fwd cada `.bc` define as funções externas com consumidor fora do módulo que o `.c` homônimo define, e o núcleo chama os outros módulos pelos mesmos símbolos que o C cruza (`analysis_*`, `nondet_*`, `generate_aux_files`, `generate_confirmation_file`). Medido com `--ref` (seção de paridade): cada combinação de A-fwd define os mesmos símbolos externos que a do C, **menos as 76 funções e globais internos do C** da política e **mais os `__m2c_rt_*`**. Não é o mesmo conjunto de definições externas. A paridade de nomes vale para tudo que passes, frontend, AFL++/KLEE ou wasm2c consomem. Isso importa porque um programa que define `__VERIFIER_assert`, como muitos do SV-COMP, falha o link com `AnalysisModeAssert.bc` no C e liga nos outros modos. Um núcleo que exportasse `__VERIFIER_assert` sempre (A-lit) quebraria os outros modos.

### A-fwd põe lógica de gerador em IR: conflito com a restrição global

As restrições globais do plano dizem: "Sem código C novo na biblioteca. Módulos de seleção ou de cola, se a D7 os exigir, são LLVM IR textual". **A-fwd não respeita essa restrição como está escrita.** O IR dos geradores não é só seleção ou cola. Ele contém lógica real de gerador, gerada por `gen_ll.py`:

- o leitor de bytes do AFL++: `get_next_input_from_afl` e o laço `m2c_afl_get_bytes`;
- `map2check_non_det_pchar`: tamanho limitado a 4096, `malloc` e o laço de caracteres;
- `map2check_non_det_memory`, com o laço que registra byte a byte;
- o laço de concretização do KLEE em `nondet_generate_aux_witness_files`: `klee_get_value_i64`, `klee_assume` e o limite de 1024 linhas.

Os três `.ll` de gerador somam **756 linhas** (AFL 348, Klee 318, None 90). A maior parte são as 21 funções por tipo, de 5 linhas cada. O `main` com `setjmp` do AFL++ e as chamadas a intrínsecos são cola de verdade, e B também precisa delas.

B cumpre a restrição: a lógica dos geradores fica em Rust `no_std`, e o IR de B é só o `main`/`setjmp`/`longjmp`/`nondet_assume` e os globais do AFL++. A escolha é do usuário (item 1 de "O que a aprovação decide"):

- **(a) A-fwd com exceção à restrição:** aceitar IR gerado com lógica de gerador (leitor, `pchar`, `memory`, concretização), testado como código (Task 2.7/2.8), em troca de um só módulo Rust;
- **(b) B, que cumpre a restrição:** 3 crates `no_std` a mais presas ao rustc 1.72 e a paridade de `map2check_afl_index` a corrigir (renomear para `__m2c_*`, ou listar na política).

Uma variante de A-fwd que cumpra a restrição também é possível. Nela a lógica iria para `__m2c_rt_*` no núcleo, e o IR passaria a esse núcleo um ponteiro para a primitiva do gerador (`klee_make_symbolic`, leitor). Não foi medida.

## Mapa módulo `.bc` → conteúdo (A-fwd)

O mapa descreve o layout proposto. No protótipo, os encaminhadores de memtrack, memcleanup e wasm ainda são stubs; os de assert, overflow e witness já chamam o núcleo (`IMPLEMENTED` em `gen_ll.py`).

| Módulo | Conteúdo |
|---|---|
| `Map2CheckFunctions.bc` | Núcleo Rust (rustc 1.72.1, fat LTO, pós-processado como acima): estado, rastreio de blocos, log de nondet, arquivos de propriedade, lógica dos modos (assert, overflow, memtrack, memcleanup), container (D3), witness e wasm. Exporta os símbolos C de `Map2CheckFunctions`, `TrackBBLog`, `NonDetLog` e `PropertyGenerator` que têm consumidor fora do módulo, mais os pontos de entrada `__m2c_rt_*`. Mais o trecho IR `map2check_assume`/`map2check_crab_assume`/`map2check_assume_loop` → `nondet_assume`. |
| `TrackBBLog.bc`, `NonDetLog.bc`, `PropertyGenerator.bc` | IR vazio: os quatro módulos do núcleo são sempre ligados juntos, e o núcleo já define os símbolos deles. |
| `ContainerRealloc.bc`, `ContainerBTree.bc`, `BTree.bc` | IR vazio: um só container Rust (D3); as funções C desses módulos são auxiliares internas do runtime (ver ponto de decisão 2). |
| `AllocationLog.bc`, `ListLog.bc`, `HeapLog.bc` | IR vazio: a lógica fica no memtrack do núcleo. |
| `AnalysisModeMemtrack.bc` | IR: `analysis_{init,destroy,is_program_correct,generate_aux_witness_files}`, os 12 `map2check_*` de memória dos passes e `map2check_wasm_{malloc,free,check_access}` → `__m2c_rt_memtrack_*`. |
| `AnalysisModeMemcleanup.bc` | IR: `analysis_*` e os 12 `map2check_*` de memória → `__m2c_rt_memcleanup_*`. |
| `AnalysisModeOverflow.bc` | IR: `analysis_*`, `map2check_binop_{add,sub,mul}[_uint]`, `map2check_binop_{sdiv,srem}`, `overflowError` → `__m2c_rt_overflow_*`. |
| `AnalysisModeAssert.bc` | IR: `analysis_*`, `map2check_assert` → `__m2c_rt_assert_*`, `__VERIFIER_assert` vazio (como no C). |
| `AnalysisModeNone.bc` | IR: `analysis_*` (constantes, `is_program_correct` = 1). |
| `NonDetGeneratorNone.bc` | IR: `main` → `__map2check_main__`; os 14 `map2check_non_det_<t>` do C devolvem 0; `map2check_non_det_memory` = memset 0; `nondet_*` vazios. |
| `NonDetGeneratorKlee.bc` | IR: `main`; os 21 `map2check_non_det_<t>` com `klee_make_symbolic` (nome `non_det_<t>`); `pchar`, `memory`; `nondet_assume` (objeto `map2check_pruned` + `_exit(0)`); `nondet_init/destroy` → log do núcleo; `nondet_generate_aux_witness_files`: concretiza as linhas do log com `klee_get_value_i64`/`klee_assume` (até 1024) e chama `__m2c_rt_nondet_log_to_file`. |
| `NonDetGeneratorAFL.bc` | IR: expansões de `__AFL_FUZZ_INIT`/`__AFL_LOOP` (globais `__afl_sharedmem_fuzzing`, `__afl_fuzz_alt[_ptr]`, marcador `##SIG_AFL_PERSISTENT##`), `main` com `__afl_persistent_loop` + `_setjmp`, leitor `get_next_input_from_afl` (zero após o fim), os 21 `map2check_non_det_<t>`, `pchar`, `memory`, `nondet_assume`/`nondet_cancel` → `longjmp`, `nondet_*`. |
| `WasmRuntimeStubs.bc` | IR: os `wasm_rt_*` e `w2c_wasi__snapshot__preview1_proc_exit` → `__m2c_rt_wasm_*` (stubs no protótipo; D2). |
| `WitnessGeneration.bc` | IR: `generate_aux_files`, `generate_confirmation_file` → `__m2c_rt_witness_*`. |
| `WitnessGenerationNone.bc` | IR: os dois vazios. |

Gerador do IR: `spikes/d7-layout/scripts/gen_ll.py`, que lê os símbolos e assinaturas de `docs/runtime-abi/inventory.tsv`.

## Achados que a Fase 2/3 herda

1. **Uma só `Map2CheckFunctions.bc` serve KLEE e AFL++.** O pós-processamento feito para o KLEE (strip-debug, symbolizer, intrínsecos rebaixados para escalar) vale também para o binário do AFL++, que o `afl-clang-fast` recompila e instrumenta inteiro, inclusive o `std`. As medidas acima já incluem esse custo.
2. **`rust_eh_personality` precisa virar `abort()`** (ou o `std` ser compilado com `panic=abort`, o que exige `-Zbuild-std`). Sem isso, toda combinação depende de `libgcc_s`.
3. **`internalize` com a lista do inventário** é obrigatório para não vazar símbolos do `std`.
4. **Atributos de ABI nos encaminhadores.** O IR gerado não põe `signext`/`zeroext` nos parâmetros e retornos `char`/`short` (`analysis_is_program_correct`, `map2check_free_resolved_address`, `map2check_crab_assume`, `generate_aux_files`). Na Fase 2 o `gen_ll.py` precisa copiar os atributos que o clang-16 emite para a assinatura C, e `tests/abi/check-signatures.sh` (Task 2.0) precisa cobrir os encaminhadores.
5. **Uma só triple, obrigatória:** todo `.bc` entregue usa `x86_64-pc-linux-gnu` (a do clang-16), e o núcleo Rust é reescrito para ela no pós-processamento, sem o module flag `"Dwarf Version"`. O frontend não redireciona o stderr do `llvm-link`, então qualquer diferença aparece como aviso em toda execução. Feito no protótipo (passo 6 do pós-processamento). A Fase 3 deve ter um teste de que o `llvm-link` de toda combinação tem stderr vazio.
6. **Variáveis C sem consumidor externo** não são exportadas (lista completa no item 2 da aprovação). O `generate_aux_files` do witness recebe um ponteiro nulo no lugar de `&trackbb_log` e lê o estado do núcleo.

## Alternativas

- **B** (geradores em crates Rust `no_std`): passa nos mesmos critérios (matriz 120/120, KLEE 5/5, AFL++ 101% e 95%) e **cumpre a restrição global de IR só para seleção/cola**. Na paridade `--ref` dá 80/120 (`map2check_afl_index` exportado nas combinações afl, corrigível). Custa 3 crates a mais presas ao rustc 1.72, depende do `internalize` para não colidir no `llvm-link` e ainda precisa de IR para o `main`/`setjmp` do AFL++. Vale se o usuário preferir lógica de gerador em Rust a IR gerado.
- **A-lit** (A literal do plano): reprovada pela matriz (0/120). As referências `extern_weak` a `klee_*` e ao gancho do AFL++ ficam indefinidas nas combinações dos outros geradores. Além disso, o `nondet_assume` do AFL++ faz `longjmp` de dentro de um frame Rust, e um núcleo que define os símbolos de modo sempre quebra a paridade do conjunto de símbolos por combinação.
- **B-loop** (AFL++ sem `longjmp`): reprovado pelo critério de throughput no programa com `assume` (6,6% do C).

## O que a aprovação decide

Aprovar a D7 como proposta fixa, para as Fases 2 e 3:

1. **Layout e a restrição de IR (decisão explícita):** escolher entre
   - **(a) A-fwd com exceção à restrição global** "IR só para módulos de seleção ou de cola": o núcleo Rust é o `Map2CheckFunctions.bc`, os outros 20 módulos são LLVM IR textual gerado (`gen_ll.py` promovido a `scripts/`), com o mapa acima, e o IR dos geradores contém lógica de gerador (leitor do AFL++, `pchar`, `non_det_memory`, concretização do KLEE; 756 linhas geradas). Essa é a recomendação;
   - **(b) B**, que cumpre a restrição, com geradores em crates Rust `no_std` e IR só para o `main`/`setjmp`/`longjmp` do AFL++.
2. **Símbolos exportados por combinação** (`docs/runtime-abi/export-policy.tsv`, conferido por `check-link-matrix.sh --ref`): cada `.bc` define as funções externas que o `.c` homônimo define **e que têm consumidor fora do runtime C** (`referenced_by` contém `pass`, `frontend` ou `external`). **Não** são exportados, por serem usados só pelo próprio runtime C:
   - **globais:** `sv_comp`, `gotError`, `Map2CheckCurrentStep`, `trackbb_log`, `nondet_log`, `allocation_log`, `heap_log`, `list_log`, `ERROR_DEREF`, `klee_log_file`, `trackbb_log_file`, `heap_log_file`, `list_log_file`, `violated_property_file`, `violated_property_file_{unknown,memtrack,memcleanup,deref,free,overflow,assert}`;
   - **funções:**
     - núcleo e logs: `is_in_tracked`, `trackbb_new_row`, `trackbb_log_to_file`, `helper_map2check_nondet_append_element`, `new_nondet_call`, `map2check_nondet_get_log`, `nondet_log_to_file`, `write_property_{unknown,memtrack,memcleanup,deref,free,overflow,assert}`;
     - container: `new_container`, `append_element`, `get_element_at`, `free_container`;
     - BTree: `B_TREE_{CREATE,FREE,INSERT,INSERT_NONFULL,PAGE_CREATE,SEARCH,SPLIT_CHILD}`, `CHECK_AND_RELEASE_PAGES`, `DISK_{READ,WRITE}`, `DumpTree*`;
     - logs de memória: os auxiliares de `AllocationLog`/`ListLog`/`HeapLog`;
     - overflow: `divisionByZeroError`, `unknown_not_supported`.

     São 76 nomes ao todo, um por linha na política.
   - **novos, só no Rust:** os pontos de entrada `__m2c_rt_*` do núcleo, que o IR chama.

   Consequência observável: um programa que define, por exemplo, `append_element` ou `gotError` liga com o runtime Rust e falha com o C. Se o usuário quiser paridade total de nomes, a alternativa é exportá-las também como encaminhadores, ao custo de reproduzir em IR as structs C passadas por valor (`MAP2CHECK_CONTAINER`). A recomendação é não exportar e registrar a diferença como `SD-xx`.
3. **Pós-processamento obrigatório do núcleo**: strip-debug, symbolizer, `rust_eh_personality` → `abort`, intrínsecos rebaixados, `internalize` com a lista do inventário.
4. **`__dso_handle` aceito na matriz só como referência weak**, além de libc/libm.
5. **O AFL++ continua com `setjmp`/`longjmp` em IR**, como o C; não há laço Rust sem `longjmp`.
6. **Uma só triple para todos os `.bc` entregues** (`x86_64-pc-linux-gnu`), sem o module flag `"Dwarf Version"` no código Rust, para que o `llvm-link` do frontend não imprima avisos.

Fica para a Fase 2 o que o protótipo deixou como stub: memtrack, memcleanup e wasm reais, e os atributos `signext`/`zeroext` dos encaminhadores.

## Reproduzir

```sh
scripts/it/test-check-link-matrix.sh                      # teste do script da matriz
scripts/it/check-link-matrix.sh target/map2check-it/c/lib # C: matrix: PASS
for s in fwd alit b b-loop; do
  spikes/d7-layout/build.sh $s target/map2check-it/d7/$s
  scripts/it/check-link-matrix.sh target/map2check-it/d7/$s
  scripts/it/check-link-matrix.sh --ref target/map2check-it/c/lib target/map2check-it/d7/$s
  rm -rf target/map2check-it/d7/inst-$s
  cp -a target/map2check-it/c target/map2check-it/d7/inst-$s
  cp target/map2check-it/d7/$s/*.bc target/map2check-it/d7/inst-$s/lib/
done
spikes/d7-layout/measure-klee.sh target/map2check-it/d7/inst-fwd fwd
spikes/d7-layout/measure-afl.sh target/map2check-it/d7/inst-fwd fwd scripts/it/smoke/link-smoke.c 20 5
spikes/d7-layout/measure-afl.sh target/map2check-it/d7/inst-fwd fwd spikes/d7-layout/progs/assume.c 20 5
spikes/d7-layout/measure-afl.sh target/map2check-it/d7/inst-fwd fwd spikes/d7-layout/progs/magic.c 30 5
```
