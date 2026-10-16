# Viabilidade do KLEE com o runtime Rust (issue #20, Task 2.7)

Data: 2026-10-16. Decisão de origem: D1, rota A′ (`docs/cutover/decisoes.md`), com a evidência do spike em `docs/cutover/spike-llvm16.md`.

**Decisão: GO.** O gerador `symex` do Map2Check usa o runtime Rust: as fontes de `rust/src`, compiladas por rustc 1.72.1 (LLVM 16.0.5) como um módulo de bitcode, ligado ao programa analisado com `llvm-link-16` e executado no KLEE 3.1. Nos seis programas de `tests/klee/`, o runtime Rust explora o mesmo número de caminhos que o runtime C de `develop`, ou menos, e chega aos mesmos veredictos. O vetor do KLEE, convertido em semente como o frontend faz, leva o leitor AFL++/libFuzzer do Rust ao mesmo ramo.

## O produto

| Peça | Arquivo |
|---|---|
| Segundo manifesto, com `build = false`, sem dev-dependencies, `rust-version = "1.72"`, `[features] klee = []`, tetos de dependência e `[workspace]` próprio | `klee/Cargo.toml` |
| Lockfile v3 próprio, gerado pelo resolvedor com fallback de MSRV (comando no cabeçalho do manifesto): serde 1.0.229, serde_json 1.0.154, thiserror 2.0.20 | `klee/Cargo.lock` |
| Gerador KLEE: `__VERIFIER_nondet_<t>` → `klee_make_symbolic`, `__VERIFIER_assume` → `klee_assume`, `main` → `__map2check_main__`, concretização antes da saída | `rust/src/nondet/klee.rs` |
| Build exato: rustc 1.72.1, `--emit=llvm-bc`, `panic = "abort"`, LTO fat, `codegen-units = 1`, `opt-16 --strip-debug`, troca dos intrínsecos vetoriais, leitura de volta com `llvm-dis-16` | `scripts/build-klee-runtime.sh`, `scripts/klee-lower-intrinsics.py` |
| Teste de integração em Docker | `tests/klee_paths.sh`, `tests/klee/` (programas, `Dockerfile`, conversor ktest → semente) |
| Job de CI em rustc 1.72.1 | `.github/workflows/CI.yml`, job `klee_runtime` |

**Por que um diretório próprio, e não um membro de workspace.** Um workspace compartilha um único `Cargo.lock`. O lockfile do build principal é v4, que o cargo 1.72 não lê. O manifesto principal também traz `build.rs`/cbindgen e `mockall`, cujo grafo exige edition 2024. Um membro de workspace herdaria os dois problemas. `klee/Cargo.toml` declara `[workspace]` vazio e é a raiz do próprio grafo.

**A feature `klee` saiu do manifesto principal.** Ela era um marcador vazio. Mantida lá, `cargo test --all-features` ligaria `libfuzzer.rs` e `klee.rs` juntos: os dois definem `__VERIFIER_nondet_*`, e os intrínsecos do KLEE não existem num binário nativo. O manifesto principal declara o valor em `[lints.rust] unexpected_cfgs`, para que `#[cfg(feature = "klee")]` passe no clippy em 1.82. O módulo `klee` fica fora do header (`cbindgen:ignore`), e `include/map2check.h` sai byte a byte igual ao de antes.

### Como construir e ligar

```bash
scripts/build-klee-runtime.sh out/map2check-klee.bc   # precisa de rustup 1.72.1 e das ferramentas LLVM 16
clang-16 -g -emit-llvm -c programa-instrumentado.c -o prog.bc
llvm-link-16 prog.bc out/map2check-klee.bc -o linked.bc
klee --external-calls=all --optimize --use-cex-cache --solver-backend=z3 --libc=uclibc linked.bc
```

O programa já vem dos passes com o `main` renomeado para `__map2check_main__`. O `main` que o KLEE executa é o do runtime, como em `NonDetGeneratorKlee.c:16`. A primeira chamada do programa é `map2check_set_mode(m)`, depois `map2check_init()`. Para o binário de witness, o frontend também chama `map2check_enable_witness()`.

## Semântica do gerador

| Aspecto | `develop` (`NonDetGeneratorKlee.c`) | Rust (`nondet/klee.rs`) |
|---|---|---|
| Valor | `klee_make_symbolic(&v, sizeof v, "non_det_" #type)` | o mesmo, objeto de `size_of::<T>()` bytes |
| Nome do objeto | `non_det_<t>` | `non_det_<t>`. `__VERIFIER_nondet_uint` cobre `map2check_non_det_uint` e `_unsigned` (`symbol-matrix.tsv`) e se chama `non_det_uint`; o frontend lê os dois nomes como unsigned de 4 bytes |
| `bool` | `int`, 4 bytes | 4 bytes (`non_det_bool`), devolvido como `int != 0`, igual ao leitor AFL++ |
| `float` | não existe | 4 bytes, `non_det_float`. O frontend não conhece o nome e o decodifica como int com sinal |
| `pchar` | comprimento `non_det_unsigned` sem limite, depois `length - 1` × `non_det_char` | o mesmo, **com teto de 4096** no comprimento, como o leitor AFL++, para que o vetor do KLEE gere a mesma string no replay (condição 9) |
| assume | `klee_assume(expr)` | `klee_assume(cond != 0)`. Um assume comprovadamente falso é erro de usuário do KLEE nos dois |
| `__VERIFIER_error` / `_assert` | `__VERIFIER_error` vazio. O alvo vira `map2check_target_function` | registra `Reachability` e aborta, como no gerador libFuzzer (corpo compartilhado em `nondet/mod.rs`) |
| Violação | `map2check_exit` → `abort()` | `output/termination.rs` → `std::process::abort()` → `abort` da uClibc. O KLEE registra `.abort.err` nos dois |
| Saída | `fprintf` da uClibc com o valor simbólico | `output::prepare_for_output` → `klee::concretize` antes de formatar (condição 7) |

**Concretização.** Antes de escrever os logs de witness ou o relatório JSON, cada valor nondet e cada endereço ou tamanho dos registros de memória é trocado por `klee_get_value_i32/i64(v)`. Logo depois vem `klee_assume(v == valor)`. O assume torna os valores conjuntamente consistentes: o segundo valor concretizado respeita o primeiro, como acontece quando o KLEE concretiza os argumentos de uma chamada externa. Valores `float`/`double` são concretizados pelos bits, porque o KLEE não tem aritmética de ponto flutuante simbólica.

## Evidência

Os comandos rodaram na imagem `map2check-dev:cutover-klee-rust`, construída de `tests/klee/Dockerfile` (`map2check-dev:cutover-f01e8c3e` + rustup 1.82.0 e 1.72.1). A referência C é `Map2Check-cutover`, HEAD `b3c10cb7`.

```bash
DEVELOP_SRC=../Map2Check-cutover tests/klee_paths.sh
```

Resultado: 16 PASS, 0 FAIL (`all KLEE checks passed`).

| Programa | O que verifica | Rust: completos + parciais | `develop` C: completos + parciais |
|---|---|---|---|
| `prog.c` | o `prog.c` do spike, do jeito que os passes o deixam: os dois lados de `x == 42` | **2 + 0** (`completed paths = 2`; ktest com `non_det_int 4 2a000000`) | 2 + 0 |
| `reach.c` | `x == 42` atinge o erro: abort com ktest 42, `TARGET-REACHED`, `klee_log.csv` com 42 | 1 + 1 | 1 + 1 |
| `range.c` | `x > 1000` atinge o erro. O log formata um valor com muitos dígitos possíveis | **1 + 1** | **1 + 7** |
| `json.c` | sem modo, o relatório JSON de um `x` sem restrição (o caso 2 → 22 do spike) | 1 + 0 | não se aplica (o C não tem JSON) |
| `deref.c` | leitura fora do bloco com `i == 4`: abort, `FALSE-DEREF`, ktest com `i = 4` | 3 + 1 | 3 + 1 |
| `layout.c` | oito tipos. O ktest do erro vira semente e passa pelo leitor libFuzzer do Rust | 8 + 1 | 8 + 1 |

"Parciais" são os caminhos encerrados por erro, aqui o abort da violação. Exploração completa, sem `--exit-on-error-type`. Os veredictos foram conferidos numa segunda execução com `--exit-on-error-type=Abort`, como o frontend roda os modos de propriedade.

**Explosão de caminhos frente ao `develop`: nenhuma.** O único desvio vai no sentido contrário. Em `range.c`, o C formata o valor simbólico dentro do `vfprintf` da uClibc, e cada dígito bifurca. Lá aparecem 7 caminhos de erro, com um só `.abort.err` gravado, porque o KLEE ignora os erros repetidos no mesmo ponto. O Rust concretiza antes e fica com 1. O total de instruções também é menor no Rust em `deref.c` (163 908 contra 704 223) e em `layout.c` (138 383 contra 471 846). Em `prog.c` é maior (43 655 contra 28 049), pela inicialização do `std`.

**Condição 7, prova pela falha.** Com `prepare_for_output` desligado (experimento, não versionado), `range.c` deu 1 + 7 caminhos e `json.c` deu 21 + 0. Com a concretização, 1 + 1 e 1 + 0.

**Condição 9, teste cruzado.** O ktest do caminho de erro de `layout.c` traz os objetos abaixo, nesta ordem (`tests/klee/ktest_to_seed.py`, que reproduz `readKtestFile` + `ktestToFuzzerBytes`):

```
non_det_char 1 41
non_det_short 2 feff
non_det_ushort 2 efbe
non_det_int 4 2a000000
non_det_uint 4 efbeadde
non_det_long 8 fbffffffffffffff
non_det_ulong 8 efcdab8967452301
non_det_uchar 1 7f
```

A semente tem esses 30 bytes concatenados. O mesmo `layout.c` foi ligado a `libmap2check.a` (`cargo build --profile runtime --features libfuzzer`, rustc 1.82) com `clang-16 -fsanitize=fuzzer` e rodado com a semente como argumento. Ele chegou ao erro: `rc=77` e `map2check_property` com `TARGET-REACHED`. Como controle, uma semente de 30 zeros termina com `rc=0` e `NONE`.

**Condições 5 e 6 no build.** `scripts/build-klee-runtime.sh` confere, na linha de comando do rustc para o crate, que estão presentes `-C panic=abort`, `-C lto`, `-C codegen-units=1` e `--emit=llvm-bc`, e que a versão do LLVM é 16. Depois passa o módulo por `opt-16 --strip-debug` e lê o resultado de volta com `llvm-dis-16`. Também confere que o módulo define `main`, `__VERIFIER_nondet_*`, `__VERIFIER_assume`, `map2check_init`, `map2check_set_mode` e `map2check_success`, e que importa `klee_make_symbolic`, `klee_assume` e `__map2check_main__`. Os mesmos passos rodaram num `ubuntu:24.04` limpo, com `apt-get install llvm-16` e `rustup toolchain install 1.72.1`, que é o que o job de CI faz. O bitcode saiu com 7,5 MB.

## Achados e limitações

1. **Intrínsecos vetoriais do `std` pré-compilado.** O `std` do 1.72.1 vem vetorizado, e o LTO fat leva esse código para o módulo. O KLEE 3.1 não executa `llvm.vector.reduce.add/or` nem `llvm.x86.sse2.pmulhu.w`. O caminho de `deref.c` morria com `unimplemented intrinsic` em `core::fmt::Formatter::pad_integral`, ao formatar o log de heap em hexadecimal com largura. Desligar a vetorização no LTO (`-C no-vectorize-loops -C no-vectorize-slp`) não resolve, porque o código já vem vetorizado no bitcode do `std`. `scripts/klee-lower-intrinsics.py` troca cada intrínseco por uma função interna escalar (`extractelement`/`insertelement` e aritmética). A equivalência é conferida com `lli-16` em `tests/klee/lower-intrinsics.ll`. Um intrínseco vetorial ou x86 desconhecido faz o build falhar. Isto é uma sexta peça do produto, além das cinco da D1.
2. **`RandomState` do `HashSet`.** O `RandomState::new()` busca a semente do SO por um símbolo fraco (`getrandom`). Sob o KLEE, isso vira `invalid function pointer`, e o caminho morre ao gravar os logs de witness. Os três `HashSet` do crate passaram a usar `memtrack::FixedHashSet`, com chaves SipHash fixas. Eles só respondem pertinência, então o resultado não muda em nenhum build.
3. **`llvm.bitreverse` (miniz_oxide).** Só a impressão de backtrace do `std` chega a ele, e com `panic = "abort"` ela não é executada. O KLEE avisa `unsupported intrinsic` no carregamento. Não dá para trocá-lo: o `--optimize` do KLEE refaz o intrínseco a partir da versão escalar.
4. **Chamadas externas.** O `std` grava os arquivos por `open64`/`write`/`close`/`unlink` externos, como o `fopen`/`fprintf` do C. O KLEE avisa, por exemplo, `undefined reference to function: statx`, `pthread_key_create` e `_Unwind_*`. Nenhum desses símbolos é executado nos caminhos testados.
5. **`--external-calls=all` e o `std`.** O que usa símbolos fracos via `dlsym` ou `syscall!` (entropia, `statx`, TLS com destrutor) é inseguro sob o KLEE. Hoje o crate não usa nada disso no estado, mas qualquer código novo que entre no build `symex` precisa passar por `tests/klee_paths.sh`.
6. **Escopo dos testes.** Os programas imitam a instrumentação dos passes à mão (`tests/klee/m2c.h`). O pipeline real com os passes do Map2Check é a Task 3.x, e o `tests/klee_paths.sh` no CI do Map2Check é a Task 3.4. Overflow, memcleanup, `pchar` e `double` simbólicos não têm programa próprio. `layout.c` cobre os oito tipos inteiros.
7. **CI.** O job `klee_runtime` compila o bitcode em 1.72.1 com `--locked`, confere que ele existe e que o `llvm-dis-16` o lê, roda o `cargo-deny` sobre `klee/Cargo.lock` e publica o `.bc` como artefato. O KLEE não roda no CI desta biblioteca, porque a imagem com o KLEE 3.1 é a de desenvolvimento do Map2Check e não está num registro público. `tests/klee_paths.sh` roda localmente e entra no CI do Map2Check na Task 3.4.

## Custos aceitos (D1, "Custo do pin do rustc 1.72.1")

- O que o build `symex` compila (todo o `rust/src` fora dos testes) fica preso ao rustc 1.72. Os ajustes desta task foram: `LazyLock` → `OnceLock` em `state.rs`; `Option::is_none_or` (1.82) → `map_or(true, ..)` em `memtrack/mod.rs`; e `Mutex::clear_poison` sob `#[cfg(not(feature = "klee"))]`, que continua ativo no build normal. O spike também trocou `unsafe extern` por `extern`. Aqui não precisou, porque o único `unsafe extern` fica em `libfuzzer.rs`, que o build `symex` não compila. O job `klee_runtime` falha se algo posterior a 1.72 entrar.
- Dois lockfiles. `cargo deny check` roda no principal (job `build_and_test`) e no de `klee/` (job `klee_runtime`).
- Saída do pin: a rota C (LLVM 19 + KLEE 3.3), nos gatilhos listados na D1.
