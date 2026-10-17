# Decisões do cutover do runtime C do Map2Check

Registro das decisões D1–D5 do plano `docs/superpowers/plans/2026-10-15-cutover-runtime-c-map2check.md`. Uma decisão só vale depois de aprovada pelo mantenedor (comentário na issue #20).

## D1

**Pergunta:** como o runtime Rust entra no pipeline LLVM 16 do Map2Check (`develop`: clang/LLVM 16.0.6, AFL++ 4.40c, KLEE 3.1), e como o AFL++ dirige as entradas.

**Status: APROVADA pelo mantenedor em 2026-10-15** (aprovação dada na sessão de execução do plano; as condições abaixo continuam obrigatórias para as tasks que as possuem)

Evidência: `docs/cutover/spike-llvm16.md` (Task 1.1). Código na branch local `spike/llvm16` (commit `d13045b`).

### Proposta por gerador

| Gerador | Rota proposta | Evidência principal |
|---|---|---|
| `none` | **B**: `libmap2check.a` nativo (rustc do repo, 1.82), ligado no passo final, sem `llvm-link` | A rota B liga e roda com clang-16 (`rc=0`). O frontend de `develop` não executa `none` como gerador. `Caller::executeAnalysis` registra "This mode is not supported", e `map2check.cpp:977-1008` troca `None` por AFL++ → KLEE (→ AFL++ de novo com `--seed-exchange`). Na prática, `none` é a combinação de `afl` e `symex`, e herda as condições das duas, inclusive a 9. |
| `afl` | **B + B1**: `libmap2check.a` nativo + driver libFuzzer do AFL++ (`afl-clang-fast -fsanitize=fuzzer`), chamando o `LLVMFuzzerTestOneInput` da biblioteca | Os dois fuzzers acharam `x == 42` em 30 s, com 1 `saved_crashes` cada. Throughput: B1 97 474 exec/s, contra 42 919 do `NonDetGeneratorAFL.c` (B2), ou 227% (229% com CmpLog). **O critério da D1 (≥ 90% do C) está atendido provisoriamente.** A comparação não é igual por igual (condição 3). Com CmpLog, que é como o frontend sempre roda, o B1 levou **3 037 ms / 280 900 execs** até o crash, contra **252 ms / 2 748 execs** do B2 (condição 4). O B2, port do `__AFL_LOOP` para Rust, continua como alternativa nomeada se as condições 3 ou 4 falharem. Remedição da Task 2.5b: 3 e 4 não atendidas; o mantenedor decidiu mitigar em Rust (2026-10-16): a 3 passa a ser julgada pelo gate 4.2 e a 4 é mitigada pela semente de ≥ 8 bytes (condições 3, 4 e 11). |
| `symex` | **A′**: runtime compilado para bitcode por um rustc com LLVM 16 (1.72.1, LLVM 16.0.5), com manifesto e lockfile próprios, LTO fat e `opt-16 --strip-debug` só no runtime, depois `llvm-link-16` com o bitcode do programa | A rota A falha: `llvm-dis-16: error: Unknown attribute kind (91) (Producer: 'LLVM19.1.1-rust-1.82.0-stable' Reader: 'LLVM 16.0.6')`. A rota B sob KLEE dá 1 caminho e não explora `x == 42`. A A′ dá 2 caminhos (ktests 42 e 0) com a crate `no_std` do brief. A **biblioteca real** (`std`, `serde_json`, `Mutex`) roda no KLEE 3.1 com um subconjunto das flags do `caller.cpp`: 22 caminhos completos, `x == 42` encontrado. |

A rota C (Map2Check em LLVM 19 + KLEE 3.3) fica como **saída futura do pin do rustc 1.72.1**, não como caminho do cutover (ver "Custo do pin e saída").

O `symex` **não está bloqueado**, porque existe uma rota medida que funciona. A consequência que o brief previa para o caso de nenhuma rota servir não se aplica. O texto era: "o cutover completo fica bloqueado: pela restrição 'não remover sem equivalente validado', o runtime C do KLEE não pode sair".

### Comandos de build e ligação

#### `none` e `afl`

O passe já renomeia `main` para `__map2check_main__`.

```bash
# biblioteca (rustc do repo, 1.82)
cargo build --release --features libfuzzer          # -> target/release/libmap2check.a
# programa: o -result.bc sai do llvm-link SEM os .bc do runtime C
afl-clang-fast -g -O2 -fsanitize=fuzzer <hash>-result.bc libmap2check.a -ldl -lpthread -lm -o <hash>-fuzzed.out
AFL_LLVM_CMPLOG=1 afl-clang-fast -g -O2 -fsanitize=fuzzer <hash>-result.bc libmap2check.a -ldl -lpthread -lm -o <hash>-cmplog.out
afl-fuzz -i afl-in -o afl-out -c ./<hash>-cmplog.out -- ./<hash>-fuzzed.out
# replay: o crash vai como ARGUMENTO, não pela stdin (condição 2)
./<hash>-witness-fuzzed.out <crash-file>
```

#### `symex`

Estes são os comandos que produziram os 22 caminhos. Rodaram em `spikes/llvm16/full172/` na branch `spike/llvm16`, na imagem `map2check-dev:cutover-rust`. **Não funcionam no manifesto principal do repo.** Lá o cargo 1.72 falha com `error: failed to parse lock file at: /src/Cargo.lock` (lockfile v4). Sem esse lockfile, ele falha com `failed to parse the 'edition' key`, porque `mockall` e `cbindgen` puxam crates com `edition = "2024"`.

```bash
cd spikes/llvm16/full172
# Manifesto do build KLEE: cópia do Cargo.toml com `build = false` (sem cbindgen),
# sem [dev-dependencies] (sem mockall), `rust-version = "1.72"`, `[features] klee = []`
# e `[workspace]` próprio. Fontes: cópia de rust/ + nondet/klee.rs.

# 1. lockfile próprio, resolvido por MSRV (cargo >= 1.84 para o resolvedor com fallback)
rustup toolchain install 1.86.0 --profile minimal
CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=fallback RUSTUP_TOOLCHAIN=1.86.0 cargo generate-lockfile
sed -i 's/^version = 4/version = 3/' Cargo.lock     # cargo 1.72 só lê v3
#    resultado: serde 1.0.229, serde_json 1.0.154, thiserror 2.0.20

# 2. runtime em bitcode LLVM 16; release com panic = "abort", lto = "fat", codegen-units = 1
RUSTUP_TOOLCHAIN=1.72.1 CARGO_TARGET_DIR=/src/spikes/llvm16/target-172c \
  cargo rustc --release --features klee --lib --crate-type staticlib -- --emit=llvm-bc -C panic=abort
opt-16 --strip-debug /src/spikes/llvm16/target-172c/release/deps/map2check-*.bc -o rt-nodbg.bc

# 3. ligação e execução (o programa mantém -g)
clang-16 -g -emit-llvm -c ../prog.c -o prog-g.bc
llvm-link-16 prog-g.bc rt-nodbg.bc -o linked5.bc
klee --external-calls=all --optimize --use-cex-cache --libc=uclibc linked5.bc
```

O frontend passa ainda `--solver-backend`, uma política de parada e de busca e a flag de sementes (`caller.cpp:815-822`). Essas flags não foram usadas no spike.

**A Task 2.7 precisa transformar isso em produto.** Peças concretas (feitas em 2026-10-16, ver `docs/klee-feasibility.md`; o build ganhou uma sexta peça, a troca dos intrínsecos vetoriais):

1. **Segundo manifesto** para o build KLEE, como membro de workspace ou diretório próprio (por exemplo `klee/Cargo.toml`). Ele aponta para as mesmas fontes de `rust/src`, com `build = false`, sem dev-dependencies e com `rust-version = "1.72"`.
2. **`Cargo.lock` v3 próprio** para esse manifesto, gerado com o comando acima e versionado. Ele é separado do lockfile v4 do build principal.
3. **Teto de dependências.** Só servem versões que resolvem e compilam em 1.72: hoje `serde_json ≤ 1.0.154` e `thiserror ≤ 2.0.20`. O `thiserror 2.0.21` já exige Rust 1.77.
4. **Feature `klee`**: código novo, inexistente no repo. A referência é `full172/rust/src/nondet/klee.rs`, com `__VERIFIER_nondet_int` → `klee_make_symbolic`. A Task 2.7 precisa escrever os demais tipos, `klee_assume` e a concretização da condição 7.
5. **LTO fat e `--strip-debug`** do bitcode do runtime. Sem LTO: `KLEE: ERROR: Unable to load symbol(__rust_no_alloc_shim_is_unstable)`. Com o debug info do `std`: `LLVM ERROR: Broken module found`.

### Custo do pin do rustc 1.72.1 e saída

Os 6 ajustes de fonte que o 1.72.1 exigiu, e o que cada um faz no build normal (rustc 1.82, `panic = unwind`, `ffi_guard` → `catch_unwind` em `rust/src/ffi.rs:100-107`):

| Ajuste | Efeito no build normal |
|---|---|
| `unsafe extern "C"` → `extern "C"` (1 erro) | Nenhum: compila igual em 1.82 / edition 2021. |
| `LazyLock` → `OnceLock::get_or_init` (4 erros) | Nenhum: `OnceLock` existe desde 1.70, e a semântica de inicialização preguiçosa é a mesma. |
| Remover `state.clear_poison()` (1 erro) | **Muda comportamento.** Depois de um pânico capturado por `ffi_guard`, o mutex fica envenenado. `reset()` ainda recupera o guard com `into_inner`, mas não limpa o veneno. Todo `with_state` seguinte (`state.lock()?`) devolve `LockPoisoned`, até o fim de um processo persistente do AFL++. |

**Para evitar a regressão,** o `clear_poison` continua no build normal e só sai do build `symex`:

```rust
#[cfg(not(feature = "klee"))]
state.clear_poison();
```

Sob `symex` isso é seguro, porque o perfil é `panic = "abort"` e não há pânico capturado que envenene o mutex. Há uma alternativa compatível com 1.72 sem `cfg`. É tornar `with_state` tolerante a veneno (`lock().unwrap_or_else(PoisonError::into_inner)`), como `state.rs:101` já faz nos testes. Ela muda o contrato de erro de `with_state`, então precisa de decisão própria.

**Custos contínuos, aceitos junto com a A′ sobre a biblioteca real:**

- (a) **O código que o build `symex` compila fica preso ao rustc 1.72 para sempre.** Ficam proibidos `LazyLock`, `unsafe extern`, edition 2024 e qualquer API de `std` posterior a 1.72. Isso precisa de um job de CI em 1.72.1, porque o `clippy` em 1.82 não detecta essas violações.
- (b) **Teto de dependências e dois lockfiles.** O v3 do `symex` e o v4 principal já divergem: `serde_json` 1.0.154 contra 1.0.150, `thiserror` 2.0.20 contra 2.0.18. O `cargo deny check` só cobre o lockfile principal, então o segundo precisa de passo próprio. Atualizar uma dependência passa a ser testado nos dois toolchains.
- (c) **O grafo do 1.72 não pode incluir `build.rs`/cbindgen nem `mockall`.** O header continua gerado só pelo build principal.

**Alternativa que reduz o custo:** um crate `no_std` separado só para o KLEE, a A′ do brief, comprovada com 2 caminhos. Com ela, o crate principal fica livre em 1.82, e só um crate pequeno fica preso a 1.72. O preço é duplicar a lógica de estado e de saída que o KLEE precisa (log de nondet, resultado e relatório). Também perde-se a garantia de que KLEE e fuzzer rodam o mesmo código. A escolha entre "biblioteca real com MSRV 1.72 no que o `symex` compila" e "crate KLEE separado" fica com o mantenedor, como parte da aprovação desta D1. Esta proposta recomenda a biblioteca real com o `cfg` acima, porque um só código é o que torna o cutover verificável.

**A saída do pin é a rota C** (LLVM 19 + KLEE 3.3, <https://github.com/klee/klee/releases/tag/v3.3>). Vale a pena quando ocorrer o primeiro destes eventos:

- o build principal precisar de algo que o 1.72 não compila e que o `cfg` não isola;
- o Map2Check decidir mudar de LLVM por outro motivo;
- o KLEE 3.3 (ou posterior) passar pelo corpus de baseline com resultados iguais aos do 3.1.

Estimativa: G (1 a 2 semanas), com detalhes em `spike-llvm16.md`.

### Condições da proposta

A aprovação aceita a proposta junto com estas condições.

1. **O `main` renomeado é obrigatório.** Com o `prog.c` cru, a ligação falha: `multiple definition of 'main'` no LibFuzzer, e `undefined reference to '__map2check_main__'` no LibFuzzer e no AFL++. O passe atual já renomeia o `main`, e isso não pode regredir.
2. **O replay pela stdin não funciona com B1.** `./b1.afl < crash` não termina (`rc=124` após 5 s), enquanto `./b1.afl crash` aborta (`rc=134`). O frontend (`caller.cpp:957`) hoje redireciona o arquivo para a stdin e precisa passar a usar argumento. Responsável: Task 3.x (frontend).
3. **Remedir o throughput de B1 contra B2, em condições iguais.** Responsável: Task 2.5, depois da Task 2.4. A comparação do spike não é igual por igual, por quatro motivos:
   - o B2 grava arquivos a cada execução (`write_property` e `generate_aux_files` em `map2check_success`), e o B1 só imprime JSON na stdout;
   - a instrumentação difere: o runtime C entra no `afl-clang-fast` como bitcode e é instrumentado; o `libmap2check.a` é objeto nativo e não é instrumentado;
   - foi uma única rodada (n = 1);
   - B1 e B2 rodaram ao mesmo tempo, na mesma máquina (`--cpus 4`).

   A remedição exige a saída em arquivo do Rust (Task 2.4), um `__VERIFIER_assume` que não encerre o processo persistente e programas com muitos `assume`. O Rust faz `exit(0)` (`libfuzzer.rs:197-206`); o C faz `longjmp` e segue para a próxima entrada. As campanhas devem rodar em sequência, com as mesmas flags e pelo menos 5 repetições. Abaixo de 90% do C, o `afl` passa para B2 (port do `__AFL_LOOP`).

   **Status: NÃO ATENDIDA — substituída pelo gate 4.2 por decisão do mantenedor em 2026-10-16.** Medição da Task 2.5b (2026-10-15): Remedido em sequência, 5 repetições, `--cpus 4`, B2 compilado das fontes de `develop` e gravando arquivos, `assume` que abandona a entrada sem encerrar o processo (`spike-llvm16.md`, “Remedição (Task 2.5b)”). Medianas de exec/s, B1/B2: `prog42` 116 390 / 98 060 (**119%**) sem CmpLog e 115 510 / 97 434 (119%) com CmpLog; programa com `assume` 64 018 / 115 493 (**55%**) sem CmpLog e 75 394 / 107 069 (**70%**) com CmpLog. A perda vem do desenrolar de pilha que rejeita cada entrada (o B2 usa `longjmp`). A rota não foi alterada.

   **Decisão do mantenedor (2026-10-16): “Mitigar em Rust”, sem trecho C.** O throughput sintético deixa de bloquear sozinho. Ele é substituído pelos critérios do gate 4.2 no corpus real: razão mediana de tempo de parede (B1 ÷ C) **≤ 1,10** e **nenhum timeout novo**. Os números acima ficam registrados como medidos.
4. **O tempo até o primeiro crash com CmpLog é critério de aceitação da D1.** Ele será remedido no corpus no gate 4.2. O frontend sempre roda o afl-fuzz com `-c <cmplog>`, então para guardas de valor mágico o que conta é o tempo até o crash, não exec/s. No spike, com CmpLog, o B1 levou cerca de 100× mais execuções que o B2 (280 900 contra 2 748), e o B2 achou o crash pela etapa de input-to-state (`op:its`).

   **Hipótese principal,** tirada do código e não medida (o spike não foi refeito): a diferença está em entradas mais curtas que o valor lido. O `read_bytes` do Rust (`libfuzzer.rs:54-71`) devolve `None` se faltarem bytes, e `read_u32` vira **0**. O C (`get_next_input_from_afl`) **volta ao início do buffer**. Com a semente `A` (1 byte), o C lê `x = 0x41414141`, que aparece na entrada. O CmpLog vê `0x41414141 == 42`, acha os bytes e os troca por `2a 00 00 00`. No Rust, `x = 0` não vem de nenhum byte da entrada, e o input-to-state não tem o que substituir. Só a mutação havoc, depois de crescer a entrada para 4 bytes, chega a `x = 42`.

   Hipótese secundária, do revisor: a leitura passa por código Rust não instrumentado. A correção provável da principal é a Task 2.5 alinhar a semântica de entrada curta à do C. Isso também é exigido pela condição 9.

   **Status: NÃO ATENDIDA na medição da Task 2.5b (2026-10-15); mitigada por decisão do mantenedor em 2026-10-16.** Com o leitor já igual ao do C, mediana de 5 campanhas `prog42` com CmpLog: B1 **822 ms** (86 511 execs, sempre `op:havoc`), B2 **190 ms** (544 execs, sempre `op:its`), ou 4,33× (o limite é 2×). Antes da correção do leitor (`0d5b1f6`), o B1 tinha mediana de 749 ms: a hipótese principal não explica a diferença. Vale a secundária: o runtime C instrumentado gera arestas (o ramo de volta ao início do buffer) que põem entradas de 4 bytes no corpus, onde o input-to-state troca o operando; o leitor Rust não é instrumentado e o corpus do B1 fica só com a semente `A`, de 1 byte. Com a semente `AAAA`, B1 e B2 acham o crash por `op:its` em cerca de 175 ms. No programa com `assume`, com CmpLog, a condição é atendida (B1 145 ms, B2 298 ms). A rota não foi alterada.

   **Mitigação (decisão do mantenedor, 2026-10-16, “Mitigar em Rust”):** o frontend dá ao AFL++ uma semente inicial de **pelo menos 8 bytes**, o tamanho do maior valor lido (`long`, `double`, ponteiros). Com isso o input-to-state tem o operando inteiro na entrada desde a primeira execução, sem depender de o corpus crescer por arestas do runtime. Responsável: Task 3.3, onde o frontend cria o diretório `-i` do afl-fuzz (`caller.cpp` ~893-905 em `develop`), com teste em `CallerLink` de que o arquivo de semente tem ≥ 8 bytes. Remedido no gate 4.2, no corpus real.
5. **MSRV 1.72 no que o build `symex` compila,** com os custos (a)–(c) acima e o `clear_poison` sob `#[cfg(not(feature = "klee"))]`. Responsável: Task 2.7, com o job de CI em 1.72.1.

   **Status: ATENDIDA (Task 2.7, 2026-10-16).** `klee/Cargo.toml` (diretório próprio com `[workspace]` vazio, `build = false`, sem dev-dependencies, `rust-version = "1.72"`) e `klee/Cargo.lock` v3 (serde 1.0.229, serde_json 1.0.154, thiserror 2.0.20) compilam `rust/src` com rustc 1.72.1 e `--locked`. Ajustes de fonte: `LazyLock` → `OnceLock`, `is_none_or` → `map_or(true, ..)` e `clear_poison` sob `#[cfg(not(feature = "klee"))]`; o build normal mantém o `clear_poison`, e o teste `reset_recovers_from_poisoned_lock` continua passando. O job `klee_runtime` do CI compila em 1.72.1 e roda `cargo-deny` no segundo lockfile. Evidência em `docs/klee-feasibility.md`.
6. **LTO fat e `--strip-debug` do runtime `symex` são obrigatórios.** O `-g` do programa analisado é preservado. Responsável: Task 2.7.

   **Status: ATENDIDA (Task 2.7, 2026-10-16).** `scripts/build-klee-runtime.sh` exige, na linha de comando do rustc, `-C panic=abort`, `-C lto` (fat), `-C codegen-units=1` e `--emit=llvm-bc`, além de LLVM 16. Em seguida roda `opt-16 --strip-debug` e lê o resultado de volta com `llvm-dis-16`. Os programas de `tests/klee_paths.sh` são compilados com `-g`. Achado: o KLEE 3.1 não executa os intrínsecos vetoriais do `std` pré-compilado (`llvm.vector.reduce.*`, `llvm.x86.sse2.pmulhu.w`), e o build passou a trocá-los por funções escalares (`scripts/klee-lower-intrinsics.py`).
7. **Concretizar antes de serializar no `symex`.** O `serde_json` formatando valores simbólicos levou o `prog.c` de 2 para 22 caminhos. O gerador KLEE do Rust precisa concretizar (`klee_get_value_*`) o que vai para o log e para o relatório, como o C faz ao escrever por chamada externa. Responsável: Task 2.7.

   **Status: ATENDIDA (Task 2.7, 2026-10-16).** `output::prepare_for_output` chama `nondet::klee::concretize` (`klee_get_value_i32/i64` seguido de `klee_assume(v == valor)`) antes dos logs de witness e do relatório JSON. Medido em `tests/klee_paths.sh`: `json.c` (relatório JSON de `x` sem restrição) dá 1 caminho, contra 21 sem a concretização; `range.c` (log de witness com `x > 1000`) dá 1 + 1, contra 1 + 7 sem ela e 1 + 7 no runtime C de `develop`, que bifurca dentro do `vfprintf` da uClibc. Correção da premissa: o C de `develop` não concretiza por chamada externa, porque o `fprintf` é o da uClibc, executado pelo KLEE.
8. **A rota B sob KLEE não é usada.** Além de não explorar símbolos, o KLEE 3.1 não tem `--load` (`Unknown command line argument '--load=...'`), e a `.so` só carrega com `LD_PRELOAD` e `-Wl,-z,lazy`.
9. **O layout do vetor tem de ser o mesmo entre KLEE e AFL++.** No modo padrão (`none` → AFL++ → KLEE → AFL++ com `--seed-exchange`), os vetores do KLEE viram sementes do AFL++ (`Caller::exportKleeVectorsAsSeeds`). O gerador AFL do Rust tem de consumir a semente exatamente como o KLEE a produz: `sizeof(tipo)` bytes por valor, em ordem, little-endian. É o que `read_u32` faz hoje para `int`, mas falta verificar os demais tipos. A semântica de entrada curta precisa estar alinhada com a do C (condição 4). Responsável: Tasks 2.5 e 2.7, com teste cruzado ktest → semente → replay.

   **Status, lado KLEE: ATENDIDA (Task 2.7, 2026-10-16).** O gerador KLEE do Rust nomeia os objetos `non_det_<t>`, como `develop`, com `sizeof(tipo)` bytes. Em `layout.c` (`char`, `short`, `ushort`, `int`, `uint`, `long`, `ulong`, `uchar`), o ktest do caminho de erro tem os oito objetos em ordem e little-endian. Convertido em semente como `ktestToFuzzerBytes` faz (30 bytes concatenados) e rodado como argumento pelo leitor libFuzzer do Rust (`--features libfuzzer`, perfil `runtime`), ele chega ao mesmo erro (`TARGET-REACHED`). Uma semente de zeros do mesmo tamanho não chega. O `pchar` do KLEE passou a limitar o comprimento a 4096, como o leitor AFL++, para que o replay gere a mesma string.
10. **O rustc 1.72.1 (2023) fica preso ao LLVM 16.** Quando o Map2Check migrar de LLVM, o toolchain do `symex` precisa acompanhar ou ser removido pela rota C.
11. **O programa analisado é compilado com `-fexceptions`.** Responsável: Task 3.2. Um `__VERIFIER_assume` falso dentro de uma iteração do fuzzer desenrola a pilha (`resume_unwind`) através dos frames C do programa até o `LLVMFuzzerTestOneInput`. Sem `-fexceptions`, o clang marca toda função C como `nounwind`, e desenrolar a partir de uma função `nounwind` é comportamento indefinido no IR do LLVM. Hoje funciona só porque o x86-64 Linux emite `.eh_frame` por padrão. Com `-fno-asynchronous-unwind-tables -fno-unwind-tables` o processo aborta (“failed to initiate panic, error 5”), e o AFL++ contaria isso como crash: um falso positivo. O passo que gera o bitcode do programa (`clang -emit-llvm`) tem de passar `-fexceptions`, porque os atributos viajam no bitcode que o `afl-clang-fast` recebe. Nenhuma etapa pode acrescentar `-fno-unwind-tables` ou `-fno-asynchronous-unwind-tables`. Unwind tables sozinhas (`-funwind-tables`) não bastam: fazem o desenrolar funcionar, mas o IR continua `nounwind`. Evidência: `tests/ffi_harness.c` em `-O2` com clang-16 e afl-clang-fast (`scripts/cutover/d1-remeasure/results/flags16.txt`, tabela em `docs/api-deltas.md`, “`__VERIFIER_assume` under a fuzzer”). O CI roda o harness em `-O2` com e sem `-fexceptions`.

## D2

**Pergunta:** o modo `--wasm` entra no cutover?

**Status: APROVADA em 2026-10-16** pelo mantenedor, depois de executada nas Tasks 2.8, 2.8b e 3.3 a partir da recomendação do plano ("Portar").

**Decisão (texto do plano):** portar os stubs do wasm2c para Rust, e não deixar `--wasm` fora do escopo.

**Justificativa (texto do plano):** o CI do Map2Check tem o job `e2e-wasm` ativo (`ci.yml:213`). Não há base, portanto, para declarar o modo obsoleto.

**Execução:**
- Task 2.8: `rust/src/wasm.rs` (feature `wasm`), com a semântica do develop registrada no SD-19.
- Task 2.8b: o runtime KLEE (`map2check-klee.bc`) também é construído com a feature `wasm`.
- Task 3.3: o frontend deixa de ligar `WasmRuntimeStubs.bc`. Os testes `test_wasm_*.sh` passam com o runtime Rust, nos geradores `afl` e `symex`.

## D3

**Pergunta:** a opção `--btree` (armazenamento em disco do runtime C) é portada para o runtime Rust, ou removida com justificativa.

**Status: APROVADA pelo mantenedor em 2026-10-16** (Task 4.3, gate 4.2 execução 1; `Map2Check-rust/tests/cutover/gate-report.md`)

**Decisão:** `--btree` **não é portada**. Continua um no-op com aviso (comportamento atual do frontend Rust).

**Justificativa:**
- O `--btree` do C não é referência válida. Sob `symex`, dá SUCCEEDED errado em 3 tarefas cujo veredito esperado é falso: `lis_unsafe`, `memleaks_test1-1` e `memleaks_test17_2-1`. Também perde `list-ext` (FAILED → UNKNOWN, nos dois geradores).
- Números de pico de RSS (mediana, 30 tarefas `valid-memsafety`): symex C-btree 136,3 MB contra Rust 221,2 MB; afl C-btree 94,3 MB contra Rust 92,3 MB. O maior pico do Rust é 472 MB.

**Desvio da condição literal da Task 2.6:** a condição (RSS do Rust ≤ o do C com `--btree` em todas as tarefas) **não** é atendida: sob `symex` o Rust fica acima em 30 de 30 tarefas, por um excesso fixo de cerca de 80 MB. O mantenedor aprovou explicitamente se afastar dela, pelo motivo acima.

## D4

**Pergunta:** limite do pico de RSS do runtime Rust em relação ao C.

**Status: APROVADA pelo mantenedor em 2026-10-16**

**Decisão:** aceitar a razão mediana medida. O limite do critério 8 passa de 1,25 para **1,36** (medido 1,360; afl 0,99, symex 1,58). `compare.py` usa `--max-rss` 1.36 por padrão.

**Causa:** o excesso sob `symex` é quase constante (cerca de +80 MB). A hipótese é que o KLEE carrega e otimiza um `map2check-klee.bc` de 2,2 MB, contra 0,13 MB dos `.bc` do runtime C. **Hipótese não perfilada.**

**Perfil posterior (critério 9, 2026-10-16):** a hipótese foi medida em byte_add_bug, com KLEE rodando sozinho no `-witness-result.bc` mantido.
- **Pico de RSS do KLEE:** C 127 MB, Rust 221 MB.
- **Sem o simbolizador de backtrace da std:** 161 MB. Os corpos de gimli, addr2line, miniz_oxide, rustc_demangle e backtrace_rs foram removidos com `llvm-extract --delete`.
- **Conclusão:** cerca de 60 dos 94 MB de excesso vêm desse código, que nunca roda.
- **Detalhes:** `Map2Check-rust/tests/cutover/gate-report.md`, "Critério 9 — perfis".

## D5

**Pergunta:** que ABI os passes do Map2Check emitem depois do cutover.

**Status: DECIDIDA pelo usuário em 2026-10-15**, na sessão que pediu o plano. O plano a registra como decidida (seção 2 e "Global Constraints").

**Decisão:** sem camada de compatibilidade.
- A biblioteca Rust não exporta os nomes nem as assinaturas do runtime C. Não há feature `compat`, módulo `compat.rs` nem aliases.
- Os passes LLVM migram diretamente para a API núcleo, sem ABI dupla. A #23 entra no cutover (Task 3.2).
- A #21 fecha como "won't do (D5)".

**Consequências:**
- A diferença de nomes entre o runtime C e o header Rust se resolve no que os passes emitem, com o mapeamento de `docs/cutover/abi-mapping.tsv` (Tasks 0.3 e 3.2), e não na biblioteca.
- A Task 2.5 só acrescenta à API núcleo, com nomes núcleo, o que ainda faltava. Um teste falha se um nome do runtime C aparecer no artefato.
- A antiga Fase 7 (aposentar a camada de compatibilidade) foi removida do plano.

## Task 5.2 — C unit test assertions ported to Rust

The C tests drove internal containers with no Rust export, so each assertion goes through the export that feeds the same record. 24 ported, 4 covered by D3 (`--btree` is not ported).

| C TEST | Rust `#[test]` (`rust/src/ffi_tests.rs`) | Note |
|---|---|---|
| ContainerTest.IsEmptyInitially | container_is_empty_initially | via `map2check_init` |
| ContainerTest.AddItemShouldIncreaseSize | container_add_item_increases_size | via `map2check_map_malloc` |
| ContainerTest.AddedItemShouldBeSetted | container_added_item_is_set | |
| ContainerTest.MultipleItemsAddedShouldNotBreak | container_multiple_items_added_do_not_break | 10000 items, order kept |
| AllocationLogTest.MarkAllocShouldIncreaseSize | allocation_log_mark_alloc_increases_size | |
| AllocationLogTest.MarkDeallocShouldIncreaseSize | allocation_log_mark_dealloc_increases_size | via `map2check_map_free` |
| AllocationLogTest.MemoryAddressStatusCaseDynamic | allocation_log_address_status_dynamic | status observed as free validity |
| AllocationLogTest.MemoryAddressStatusCaseFree | allocation_log_address_status_free | invalid free |
| AllocationLogTest.MemoryAddressStatusCaseEmpty | allocation_log_address_status_empty_is_static | sem export para o enum de status; o STATIC é observado pelo veredito de free inválido do SD-06 |
| AllocationLogTest.MemoryAddressStatusCaseStatic | allocation_log_address_status_static_when_another_address_is_tracked | sem export para o enum de status; o STATIC é observado pelo veredito de free inválido do SD-06 |
| AllocationLogTest.IfAddressIsReleasedThenAllocationLogIsValid | allocation_log_released_address_leaves_no_leak | via `map2check_check_mem_endprog` |
| AllocationLogTest.IfAddressIsNotReleasedThenAllocationLogIsInvalid | allocation_log_unreleased_address_is_a_leak | |
| AllocationLogTest.AddressIsInAllocationLog | allocation_log_address_is_in_allocation_log | via `map2check_check_load` |
| AllocationLogTest.AddressIsNotInAllocationLog | allocation_log_address_is_not_in_allocation_log | |
| HeapLogTest.MarkHeapShouldIncreaseSize | heap_log_mark_heap_increases_size | via `map2check_map_alloca` |
| HeapLogTest.ValidPrimitive | heap_log_valid_primitive | |
| HeapLogTest.InvalidPrimitive | heap_log_invalid_primitive | |
| HeapLogTest.ValidArray | heap_log_valid_array | |
| HeapLogTest.InvalidArray | heap_log_invalid_array | |
| MemoryTrackTest.DefaultIsOk | memtrack_default_program_is_correct | memtrack mode |
| MemoryTrackTest.MallocShouldGenerateMemleak | memtrack_malloc_generates_memleak | |
| MemoryTrackTest.CallocShouldGenerateMemleak | memtrack_calloc_generates_memleak | |
| MemoryTrackTest.AfterReleaseMalloc | memtrack_release_after_malloc_leaves_no_leak | |
| MemoryTrackTest.AfterReleaseCalloc | memtrack_release_after_calloc_leaves_no_leak | |
| BTreeTest.ConstructorShouldBeSettedRight | not ported | D3 |
| BTreeTest.AddItem | not ported | D3 |
| BTreeTest.AddItemShouldSetValue | not ported | D3 |
| BTreeTest.AddMultipleItems | not ported | D3 |
