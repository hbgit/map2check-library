# D7: layout dos 21 módulos `.bc` do runtime drop-in (spike da Task 1.1)

Data: 2026-10-26. Alvo: Map2Check `develop` `3e914528ec57` (cópia em `vendor/map2check/`), imagem `map2check-dev:develop-3e914528ec57` (clang/LLVM 16.0.6, KLEE 3.1, AFL++ 4.40c). Rust: rustc 1.72.1 (LLVM 16.0.5), rota A′ da D1 (fat LTO, `panic = "abort"`, `--emit=llvm-bc`, `opt-16 --strip-debug`).

Protótipo: `spikes/d7-layout/` (fora do build da crate). Matriz: `scripts/it/check-link-matrix.sh`.

**Status: proposta, aguardando aprovação do usuário (Step 6). As Fases 2 e 3 dependem dela.**

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

## Matriz de link (`scripts/it/check-link-matrix.sh`)

Programa de fumaça: `scripts/it/smoke/link-smoke.c` (seguro: `malloc` de tamanho fixo, soma num laço limitado por um nondet, verificação com `reach_error`), instrumentado pelo próprio Map2Check instalado (`target/map2check-it/c`), uma vez por modo, guardando o `<hash>-output.bc` (ruling R2). Modos: `--memtrack`, `--memcleanup-property`, `--check-overflow`, `--check-asserts`, `--target-function --target-function-name reach_error` (o modo `none`, que liga `AnalysisModeNone.bc`).

Critérios por combinação: `llvm-link-16` sem erro; `llvm-nm-16 --undefined-only` (fortes e weak) contido em libc/libm da imagem + `__dso_handle`, mais `klee_*` (symex), `__afl_*` (afl), `wasm_rt_*` (wasm); link nativo `clang-16` (gerador none) e `afl-clang-fast -g -O2 ... -lm` (afl).

`__dso_handle` entrou na lista: o `std` o referencia como weak (destrutores de `thread_local`) e ele é definido pelo `crtbegin.o` de todo executável. É um desvio do texto "libc/libm" do plano.

| Biblioteca | Resultado | Falhas |
|---|---|---|
| C (`target/map2check-it/c/lib`) | **120/120 PASS** | — |
| A-lit | **0/120 PASS, matrix: FAIL** | gen none: `__m2c_afl_reject klee_make_symbolic` indefinidos (weak); gen symex: `__m2c_afl_reject`; gen afl: `klee_make_symbolic` (40 cada) |
| A-fwd | **120/120 PASS** | — |
| B | **120/120 PASS** | — |
| B-loop | **120/120 PASS** | — |

O link nativo de A-lit com gerador none funciona (weak indefinido vira nulo; `./a.out` termina com `NONE` no arquivo de propriedade), mas a regra de símbolos permitidos da matriz reprova a estratégia, como previsto: referências `extern_weak` a intrínsecos aparecem em combinações onde o gerador não é aquele.

## KLEE (`spikes/d7-layout/measure-klee.sh`)

`map2check --debug --nondet-generator symex --timeout 30 <modo> link-smoke.c` com a instalação do C e com cópias dela em que só `lib/*.bc` foi trocado (`cp -a` da instalação + os 21 `.bc` da estratégia). `SUCCEEDED` significa que `kleeDroppedPaths()` do frontend devolveu vazio (TRUE exige exploração exaustiva).

| Instalação | memtrack | memcleanup | overflow | assert | none |
|---|---|---|---|---|---|
| C | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED |
| A-fwd | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED |
| A-lit | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED |
| B | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED | SUCCEEDED |

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

Faixas: `link-smoke` C 38 134–52 962, A-fwd 39 991–50 772. `assume` C 108 930–116 354, A-fwd 100 567–111 795. Operador do crash (`op:`): C its×3, havoc×2; A-fwd its×3, havoc×2; B its×4; B-loop its×5.

**Decisão do AFL++:** `main` + `setjmp` em IR, com `nondet_assume` → `longjmp` também em IR (A-fwd e B). O laço sem `longjmp` (B-loop) perde 93% do throughput quando o programa rejeita entradas, porque cada rejeição encerra o processo e custa um fork. No A-fwd o `longjmp` nunca atravessa um frame Rust: `map2check_assume` é IR (trecho `.ll` do `Map2CheckFunctions.bc`) e chama o `nondet_assume` do gerador direto do frame do programa; o núcleo não segura nenhum lock nesse caminho.

## Recomendação: A-fwd

A-fwd atende os três critérios do Step 4: matriz 120/120 PASS; KLEE sem caminho descartado nos 5 modos; AFL++ com 102% e 95% do throughput do C (critério ≥ 90%) e crash do valor mágico em 233 ms contra 434 ms do C.

Por que A-fwd e não B, que também passa:

- **Um só módulo Rust.** B põe duas crates Rust na mesma ligação. Isso só funciona porque o `internalize` esconde os símbolos do `core`. Sem ele, os dois módulos exportariam as mesmas funções mangled do `core` (mesmo toolchain, mesmo hash) e o `llvm-link` falharia ao usar `core::fmt` nos dois. B também quadruplica as crates presas ao rustc 1.72 (núcleo + 3 geradores, com manifestos e lockfiles v3 próprios; custo (a)–(b) da D1).
- **B não elimina o IR.** O gerador AFL++ de B ainda precisa de `main`, `setjmp`/`longjmp`, `nondet_assume` e dos globais `__afl_*` em `.ll`. A diferença para A-fwd é só onde ficam o leitor de bytes, o `pchar`/`memory` e a concretização do KLEE: IR gerado em A-fwd (os três `.ll` de gerador somam 756 linhas, a maior parte as 21 funções por tipo, de 5 linhas cada) contra Rust `no_std` em B.
- **O grafo de módulos do C é preservado.** Em A-fwd cada `.bc` define as mesmas funções externas que o `.c` homônimo, e o núcleo chama os outros módulos pelos mesmos símbolos que o C cruza (`analysis_*`, `nondet_*`, `generate_aux_files`, `generate_confirmation_file`). Uma combinação tem o mesmo conjunto de definições externas que no C. Isso importa porque um programa que define `__VERIFIER_assert`, como muitos do SV-COMP, falha o link com `AnalysisModeAssert.bc` no C e liga nos outros modos. Um núcleo que exportasse `__VERIFIER_assert` sempre (A-lit) quebraria os outros modos.

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
5. **Triple:** o núcleo sai com `x86_64-unknown-linux-gnu`, o C e o IR com `x86_64-pc-linux-gnu`; o `llvm-link` só avisa. Na Fase 3, o IR deve usar a triple do núcleo, ou o build deve fixar uma só.
6. **Variáveis C sem consumidor externo** (`trackbb_log`, `nondet_log`, `gotError`, `Map2CheckCurrentStep`, nomes de arquivo `violated_property_file*`) não são exportadas; o `generate_aux_files` do witness recebe um ponteiro nulo no lugar de `&trackbb_log` e lê o estado do núcleo.

## Alternativas

- **B** (geradores em crates Rust `no_std`): passa nos mesmos critérios (matriz 120/120, KLEE 5/5, AFL++ 101% e 95%). Custa 3 crates a mais presas ao rustc 1.72, depende do `internalize` para não colidir no `llvm-link` e ainda precisa de IR para o `main`/`setjmp` do AFL++. Vale se o usuário preferir lógica de gerador em Rust a IR gerado.
- **A-lit** (A literal do plano): reprovada pela matriz (0/120). As referências `extern_weak` a `klee_*` e ao gancho do AFL++ ficam indefinidas nas combinações dos outros geradores. Além disso, o `nondet_assume` do AFL++ faz `longjmp` de dentro de um frame Rust, e um núcleo que define os símbolos de modo sempre quebra a paridade do conjunto de símbolos por combinação.
- **B-loop** (AFL++ sem `longjmp`): reprovado pelo critério de throughput no programa com `assume` (6,6% do C).

## O que a aprovação decide

Aprovar a D7 como proposta fixa, para as Fases 2 e 3:

1. **Layout A-fwd**: o núcleo Rust é o `Map2CheckFunctions.bc`; os outros 20 módulos são LLVM IR textual gerado (`gen_ll.py` promovido a `scripts/`), com o mapa acima; os intrínsecos KLEE/AFL++, `main` e `setjmp`/`longjmp` ficam só no IR dos geradores.
2. **Símbolos exportados por módulo**: cada `.bc` define as funções externas que o `.c` homônimo define **e que têm consumidor fora do módulo** (`referenced_by` ≠ `-` no inventário). As auxiliares internas do C (container, logs, `B_TREE_*`, `write_property_*` só usados pelo runtime) **não** são exportadas. Consequência observável: um programa que define, por exemplo, `append_element` liga com o runtime Rust e falha com o C. Se o usuário quiser paridade total de nomes, a alternativa é exportá-las também como encaminhadores, ao custo de reproduzir em IR as structs C passadas por valor (`MAP2CHECK_CONTAINER`). A recomendação é não exportar e registrar a diferença como `SD-xx`.
3. **Pós-processamento obrigatório do núcleo**: strip-debug, symbolizer, `rust_eh_personality` → `abort`, intrínsecos rebaixados, `internalize` com a lista do inventário.
4. **`__dso_handle` na lista permitida da matriz**, além de libc/libm.
5. **O AFL++ continua com `setjmp`/`longjmp` em IR**, como o C; não há laço Rust sem `longjmp`.

Fica para a Fase 2 o que o protótipo deixou como stub: memtrack, memcleanup e wasm reais, e os atributos `signext`/`zeroext` dos encaminhadores.

## Reproduzir

```sh
scripts/it/test-check-link-matrix.sh                      # teste do script da matriz
scripts/it/check-link-matrix.sh target/map2check-it/c/lib # C: matrix: PASS
for s in fwd alit b b-loop; do
  spikes/d7-layout/build.sh $s target/map2check-it/d7/$s
  scripts/it/check-link-matrix.sh target/map2check-it/d7/$s
  rm -rf target/map2check-it/d7/inst-$s
  cp -a target/map2check-it/c target/map2check-it/d7/inst-$s
  cp target/map2check-it/d7/$s/*.bc target/map2check-it/d7/inst-$s/lib/
done
spikes/d7-layout/measure-klee.sh target/map2check-it/d7/inst-fwd fwd
spikes/d7-layout/measure-afl.sh target/map2check-it/d7/inst-fwd fwd scripts/it/smoke/link-smoke.c 20 5
spikes/d7-layout/measure-afl.sh target/map2check-it/d7/inst-fwd fwd spikes/d7-layout/progs/assume.c 20 5
spikes/d7-layout/measure-afl.sh target/map2check-it/d7/inst-fwd fwd spikes/d7-layout/progs/magic.c 30 5
```
