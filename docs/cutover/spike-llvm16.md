# Spike LLVM 16: como o runtime Rust entra no pipeline do Map2Check (Task 1.1)

Data: 2026-10-15. Alvo: Map2Check `develop` (worktree `Map2Check-cutover`, HEAD `33b41e81`).
Código do spike: branch local `spike/llvm16` (commit `d13045b`), diretório `spikes/llvm16/`. Ela não vai para `develop`.

## Ambiente

| Item | Versão observada |
|---|---|
| Imagem base | `map2check-dev:cutover-f01e8c3e` (Ubuntu jammy, usuário `map2check`, uid 1000) |
| clang / llvm-link / llvm-dis / opt | 16.0.6 (`clang-16`, `llvm-link-16`, `llvm-dis-16`, `opt-16`) |
| KLEE | 3.1 (`/opt/klee/bin/klee`, build Release+Asserts, rev `fe22b907`) |
| AFL++ | 4.40c (`/usr/local/bin/afl-fuzz`, `afl-clang-fast`) |
| rustc do repo | 1.82.0, **LLVM 19.1.1** |
| rustc da Rota A′ | 1.72.1, **LLVM 16.0.5** |

Imagem derivada `map2check-dev:cutover-rust` (`spikes/llvm16/Dockerfile.rust`):

```dockerfile
FROM map2check-dev:cutover-f01e8c3e
USER root
ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo PATH=/opt/cargo/bin:$PATH
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.82.0 --profile minimal \
 && rustup toolchain install 1.72.1 --profile minimal \
 && chmod -R a+rwX /opt/rustup /opt/cargo
USER map2check
```

Todos os comandos rodaram assim (o `release-afl/lib` do Map2Check entra só para leitura):

```bash
docker run --rm --cpus 4 -v $PWD:/src -w /src \
  -v /home/rock/Documents/Dev/Map2Check-cutover/release-afl/lib:/mc:ro \
  -e CARGO_TARGET_DIR=/src/spikes/llvm16/target-docker -e RUSTUP_TOOLCHAIN=1.82.0 \
  map2check-dev:cutover-rust bash -c '<comando>'
```

Programas de prova (`spikes/llvm16/`):

- `prog.c`: o programa do brief, sem alteração.
- `prog42.c`: igual ao `prog.c`, mas com `abort()` em `x == 42`. Com `return 1` o fuzzer não registra nada, porque retorno não é crash. Para contar `saved_crashes` era preciso um sinal.
- `prog42_c.c`: o `prog42.c` como os passes do Map2Check o entregam ao runtime C (`main` → `__map2check_main__`, `__VERIFIER_nondet_int` → `map2check_non_det_int`, `map2check_init(0)`). É a referência B2.

## Resumo

| Rota | Esperado (brief) | Observado | Resultado |
|---|---|---|---|
| A: bitcode do rustc 1.82 no `llvm-link-16` | `dis16≠0` | `dis16=1`, `Unknown attribute kind (91)` | **falha (como esperado)** |
| B: `libmap2check.a` nativo + `clang-16 -fsanitize=fuzzer` | liga e roda | com o `prog.c` cru, **não liga** (`main` duplicado + `__map2check_main__` indefinido); com `main` renomeado, liga e roda (`rc=0`) | **passa, desde que o passe renomeie `main`** |
| B1: staticlib + driver libFuzzer do AFL++ | throughput ≥ 90% do C | 97 474 exec/s, 1 crash (`x == 42`) em 0,39 s; com CmpLog, 1º crash em 3,0 s / 280 900 execs (B2: 0,25 s / 2 748) | **passa provisoriamente** (227% do B2, comparação não igual por igual; CmpLog pior) |
| B2: `NonDetGeneratorAFL.c` (referência) | — | 42 919 exec/s, 1 crash (`x == 42`) em 0,33 s | referência |
| B sob KLEE (`.so` nativo) | 1 caminho, não explora `x == 42` | 1 caminho completo; `x == 42` não explorado | **falha para `symex` (como esperado)** |
| A′: `no_std` + rustc 1.72.1 (LLVM 16) | 2 caminhos | 2 caminhos, ktests `42` e `0` | **passa** |
| A′ estendida: a biblioteca inteira (`std`, `serde_json`) com rustc 1.72.1 | — (fora do brief) | após 6 ajustes de fonte e `Cargo.lock` com resolução por MSRV, roda no KLEE com um subconjunto das flags do Map2Check: 22 caminhos, `x == 42` encontrado | **passa, com ressalvas** |
| C: Map2Check em LLVM 19 | sim/não + estimativa | KLEE 3.3 (2026-10-15) tem suporte completo a LLVM 17–19; passes usam 49 APIs `llvm::` | **viável, não medido** |

## Rota A: bitcode do rustc 1.82 no LLVM 16

```bash
cargo rustc --release --lib --crate-type staticlib -- --emit=llvm-bc -C panic=abort
llvm-dis-16 $CARGO_TARGET_DIR/release/deps/map2check-*.bc -o /dev/null; echo "dis16=$?"
clang-16 -emit-llvm -c spikes/llvm16/prog.c -o prog.bc
llvm-link-16 prog.bc $CARGO_TARGET_DIR/release/deps/map2check-*.bc -o linkedA.bc; echo "link16=$?"
```

Saída:

```
rustc 1.82.0 (f6e511eec 2024-10-15)   LLVM version: 19.1.1
llvm-dis-16: error: Unknown attribute kind (91) (Producer: 'LLVM19.1.1-rust-1.82.0-stable' Reader: 'LLVM 16.0.6')
dis16=1
llvm-link-16: target-docker/release/deps/map2check-77edb1d032f8b0d7.bc: error: Unknown attribute kind (91) (Producer: 'LLVM19.1.1-rust-1.82.0-stable' Reader: 'LLVM 16.0.6')
llvm-link-16: error:  loading file 'target-docker/release/deps/map2check-77edb1d032f8b0d7.bc'
link16=1
```

Resultado: **falha, como o brief previa.** O bitcode do LLVM 19 não é legível pelo LLVM 16. O formato não tem compatibilidade para trás.

## Rota B: staticlib nativo no passo final (LibFuzzer)

```bash
cargo build --release --features libfuzzer
clang-16 -emit-llvm -c prog.c -o prog.bc
clang-16 -fsanitize=fuzzer prog.bc $L -ldl -lpthread -lm -o prog.fuzz     # L=.../libmap2check.a
```

Com o `prog.c` do brief (o `main` original):

```
/usr/bin/ld: /tmp/prog-a25d77.o: in function `main':
prog.c:(.text.main[main]+0x0): multiple definition of `main'; /usr/lib/llvm-16/lib/clang/16/lib/linux/libclang_rt.fuzzer-x86_64.a(FuzzerMain.cpp.o):(.text.main+0x0): first defined here
/usr/bin/ld: .../libmap2check.a(map2check-...rcgu.o): in function `LLVMFuzzerTestOneInput':
map2check...:(.text.LLVMFuzzerTestOneInput+0x49): undefined reference to `__map2check_main__'
clang: error: linker command failed with exit code 1
```

**Há colisão de `main`.** O `LLVMFuzzerTestOneInput` da biblioteca chama `__map2check_main__`, então o programa precisa chegar com o `main` já renomeado, que é o que os passes do Map2Check fazem. Simulando o passe com `-Dmain=__map2check_main__`:

```bash
clang-16 -emit-llvm -c -Dmain=__map2check_main__ prog.c -o prog_m.bc
clang-16 -fsanitize=fuzzer prog_m.bc $L -ldl -lpthread -lm -o prog_m.fuzz   # linkB=0
./prog_m.fuzz -runs=1000                                                    # rc=0
```

```
INFO: Loaded 1 modules   (3 inline 8-bit counters)
#1000	DONE   cov: 2 ft: 3 corp: 1/1b lim: 11 exec/s: 0 rss: 28Mb
Done 1000 runs in 0 second(s)
```

Cada execução imprime o relatório JSON (`"result": "TRUE"`) na stdout. Uma rodada de 2 000 000 execuções com `-use_value_profile=1`:

```bash
./prog_m.fuzz -runs=2000000 -use_value_profile=1 -artifact_prefix=crB/ > fuzzB2.log 2>&1   # rc2=0
grep -E "^#|Done|SUMMARY|deadly|crash|exit" fuzzB2.log | tail -5
```

```
#1048576	pulse  cov: 2 ft: 67 corp: 58/229b lim: 4096 exec/s: 349525 rss: 28Mb
#2000000	DONE   cov: 2 ft: 67 corp: 58/229b lim: 4096 exec/s: 285714 rss: 28Mb
Done 2000000 runs in 7 second(s)
```

 A instrumentação SanitizerCoverage entra no bitcode do usuário no passo final (3 contadores), não na biblioteca.

Resultado: **passa**, com a condição de que o `main` do programa seja renomeado pelo passe antes da ligação.

## Rotas B1 e B2: AFL++ 4.40c

### B1: staticlib + driver libFuzzer do AFL++

Comando do brief, com o `prog.bc` cru:

```
[+] Found '-fsanitize=fuzzer', replacing with libAFLDriver.a
/usr/bin/ld: .../libmap2check.a(...): in function `LLVMFuzzerTestOneInput':
(.text.LLVMFuzzerTestOneInput+0x49): undefined reference to `__map2check_main__'
clang: error: linker command failed with exit code 1
```

Aqui o ligador não acusou `main` duplicado; o único erro é o `__map2check_main__` indefinido. Mesmo assim o `main` precisa ser renomeado. Com o `main` renomeado (`spikes/llvm16/b1build.sh`):

```bash
clang-16 -emit-llvm -c -Dmain=__map2check_main__ prog42.c -o prog42_m.bc
afl-clang-fast -g -O2 -fsanitize=fuzzer prog42_m.bc $L -ldl -lpthread -lm -o b1.afl
AFL_LLVM_CMPLOG=1 afl-clang-fast -g -O2 -fsanitize=fuzzer prog42_m.bc $L -ldl -lpthread -lm -o b1.cmplog.afl
```

Liga. Os símbolos foram verificados num build anterior com os mesmos fontes, mas sem `-g -O2` (`prog42_m.afl`). Para o `b1.afl` final, essa verificação não foi registrada:

```bash
nm prog42_m.afl | grep -E " T (main|LLVMFuzzerTestOneInput|__map2check_main__|__afl_persistent_loop)$"
strings prog42_m.afl | grep -c SIG_AFL_PERSISTENT
```

```
0000000000023830 T LLVMFuzzerTestOneInput
00000000000e5c70 T __afl_persistent_loop
00000000000188b0 T __map2check_main__
1
```

O `main` não aparece com o tipo `T`. Talvez seja o símbolo fraco do driver, mas isso não foi registrado. O marcador `##SIG_AFL_PERSISTENT##` está presente, então o binário roda em persistent mode. Tamanhos (`ls -la`): `b1.afl` tem 5 796 288 bytes; `b2.afl`, 146 512.

### B2: referência C (`NonDetGeneratorAFL.c`)

Ligação idêntica à do frontend (`caller.cpp:558–641`, modo reachability, `ContainerRealloc`), com os `.bc` de `release-afl/lib` montados somente leitura (`spikes/llvm16/b2build.sh`):

```bash
clang-16 -emit-llvm -c prog42_c.c -o prog42_c.bc
llvm-link-16 prog42_c.bc /mc/Map2CheckFunctions.bc /mc/TrackBBLog.bc /mc/NonDetLog.bc \
  /mc/PropertyGenerator.bc /mc/ContainerRealloc.bc /mc/AnalysisModeNone.bc \
  /mc/NonDetGeneratorAFL.bc /mc/WitnessGenerationNone.bc -o result.bc
afl-clang-fast -g -O2 result.bc -o b2.afl
AFL_LLVM_CMPLOG=1 afl-clang-fast -g -O2 result.bc -o b2.cmplog.afl
```

### Campanhas de 30 s

`spikes/llvm16/fuzz.sh`, com o mesmo ambiente que o frontend usa (`caller.cpp:919`), semente `A`, B1 e B2 em paralelo (1 núcleo cada):

```bash
AFL_NO_UI=1 AFL_NO_AFFINITY=1 AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
AFL_CRASHING_SEEDS_AS_NEW_CRASH=1 afl-fuzz -i in -o out -V 30 [-c ./X.cmplog.afl] -- ./X.afl
```

Valores de `out/default/fuzzer_stats`:

| Variante | `execs_per_sec` | `execs_done` | `saved_crashes` | `stability` | 1º crash (`time`, `execs`) | `x == 42`? |
|---|---|---|---|---|---|---|
| B1 sem CmpLog | **97 473,82** | 2 924 312 | 1 | 100,00% | 392 ms, 27 994 | sim, entrada `2a 00 00 00 …` |
| B2 sem CmpLog | **42 919,21** | 1 287 791 | 1 | 75,68% | 329 ms, 10 543 | sim, entrada `2a 00 00 00 64 00 18` |
| B1 com CmpLog (`-c`) | 97 270,49 | 2 918 212 | 1 | 100,00% | 3 037 ms, 280 900 | sim |
| B2 com CmpLog (`-c`) | 42 562,56 | 1 276 962 | 1 | 78,38% | 252 ms, 2 748 (`op:its`) | sim, entrada `2a 00 00 00` |

Throughput B1/B2: **227%** sem CmpLog e **229%** com CmpLog. O critério de 90% da D1 está **atendido só provisoriamente**, porque a comparação não é igual por igual:

1. O B2 grava arquivos a cada execução (`write_property` e `generate_aux_files` em `map2check_success`). O B1 só imprime JSON na stdout, que o afl-fuzz descarta.
2. A instrumentação difere. O runtime C entra no `afl-clang-fast` como bitcode e é instrumentado junto com o programa. O `libmap2check.a` é objeto nativo e não é instrumentado.
3. Foi uma única rodada por variante (n = 1).
4. B1 e B2 rodaram ao mesmo tempo, no mesmo contêiner (`--cpus 4`).

A remedição em condições iguais é a condição 3 da D1 (`decisoes.md`). Ela vem depois da Task 2.4 (saída em arquivo do Rust) e da Task 2.5 (`assume`), e usa programas com muitos `assume`.

**CmpLog e tempo até o crash.** O frontend sempre roda com CmpLog (`-c <hash>-cmplog.out`). Nesse modo, o B1 precisou de **3 037 ms e 280 900 execs** até o primeiro crash, e o B2 de **252 ms e 2 748 execs**: cerca de 100× mais execuções no B1. O crash do B2 veio da etapa de input-to-state (`op:its`); o do B1, de havoc. Sem CmpLog a diferença é pequena (27 994 contra 10 543 execs). Para guardas de valor mágico, comuns no SV-COMP, o tempo até o bug pesa mais que exec/s.

- **Hipótese principal** (lida do código, não medida): entradas mais curtas que o valor lido. O `read_bytes` do Rust (`rust/src/nondet/libfuzzer.rs:54-71`) devolve `None` se faltarem bytes, e `read_u32` vira 0. O `get_next_input_from_afl` do C volta ao início do buffer. Com a semente `A` (1 byte), o C lê `x = 0x41414141`. O CmpLog vê `0x41414141 == 42`, acha os bytes `41` na entrada e os troca por `2a 00 00 00`. No Rust, `x = 0` não vem de nenhum byte da entrada, então o input-to-state não tem o que substituir.
- **Hipótese secundária:** a leitura passa por código Rust não instrumentado.

O tempo até o primeiro crash com CmpLog passou a ser critério de aceitação da D1 (condição 4), remedido no corpus no gate 4.2.

**Estabilidade.** O B2 ficou em 75,68% / 78,38%, e o B1 em 100%. Não investiguei a causa. Hipótese: o runtime C instrumentado carrega estado entre as iterações persistentes (contêineres alocados em `map2check_init`, arquivos, `map2check_destroy` com `static alreadyReleased`), e isso faz arestas variarem entre execuções da mesma entrada. O runtime Rust não é instrumentado e zera o estado a cada `LLVMFuzzerTestOneInput`. Por isso, mesmo que vazasse estado, isso não apareceria como instabilidade.

Com entrada de pelo menos 4 bytes, os dois runtimes leem o valor como 4 bytes little-endian do início da entrada. Com entrada mais curta, divergem: o Rust devolve 0, e o C volta ao início do buffer (ver acima).

### Replay standalone do crash (achado relevante para a Task 3.x)

O frontend reproduz crashes redirecionando o arquivo para a stdin (`caller.cpp:957`: "the crash file is redirected in").

```
B2: ./b2.afl < crash            -> rc=134 (abort)                    OK
B1: ./b1.afl crash              -> rc=134 (abort)                    OK
B1: ./b1.afl < crash            -> rc=124 (timeout 5 s, não termina)
```

Pela stdin, o B1 imprime um relatório `"result": "TRUE"` e não termina. O driver libFuzzer do AFL++ não lê o caso de teste da stdin como o `NonDetGeneratorAFL.c`. Com B1, o replay do frontend precisa passar o arquivo como argumento.

## Rota B sob KLEE (biblioteca nativa)

O comando do brief não roda no KLEE 3.1:

```
klee: Unknown command line argument '--load=/src/spikes/llvm16/target-docker/release/libmap2check.so'.  Try: 'klee --help'
klee: Did you mean '--libc=...'?
```

O KLEE 3.1 não tem mais `--load`. Correção de ambiente: pré-carregar a `.so` com `LD_PRELOAD`, já que o KLEE resolve chamadas externas por `dlsym` no próprio processo. Duas falhas no caminho:

1. A `.so` com `--features libfuzzer` exige `__map2check_main__` na carga (`symbol lookup error: ... undefined symbol: __map2check_main__`), porque a ligação padrão do rustc (RELRO completo) resolve tudo na carga. Resolvido com `-C relro-level=off -C link-arg=-Wl,-z,lazy`.
2. A `.so` sem features não exporta `__VERIFIER_nondet_int` (0 símbolos): `KLEE: ERROR: failed external call: __VERIFIER_nondet_int`, 0 caminhos completos.

Comando que roda:

```bash
cargo rustc --release --features libfuzzer --lib --crate-type cdylib -- \
  -C panic=abort -C relro-level=off -C link-arg=-Wl,-z,lazy
LD_PRELOAD=$S klee --output-dir=klee-out-B --external-calls=all prog.bc
```

```
KLEE: WARNING: undefined reference to function: __VERIFIER_nondet_int
KLEE: WARNING ONCE: calling external: __VERIFIER_nondet_int() at [no debug info]
KLEE: done: total instructions = 14
KLEE: done: completed paths = 1
KLEE: done: partially completed paths = 0
KLEE: done: generated tests = 1
```

`klee-stats --to-csv`: `Instructions=14, ... TerminationExit=1`. Para gerar a tabela, o `klee-stats` exige o pacote Python `tabulate`, ausente na imagem; o CSV não exige.

Resultado: **1 caminho; `x == 42` não é explorado.** O nondet nativo devolve um valor concreto (0, sem buffer de fuzzer). Como o brief previa, a rota B não serve para `symex`.

## Rota A′: rustc 1.72.1 (LLVM 16) + bitcode

### A′ conforme o brief: crate `no_std` mínima (`spikes/llvm16/klee-rt`)

`#![no_std]`, `panic = "abort"`, `#[global_allocator]` sobre `malloc`/`free`, `#[panic_handler]` com `abort`, um `Vec<i32>` de log (para exercitar `alloc`) e `__VERIFIER_nondet_int` chamando `klee_make_symbolic`. Perfil release com `lto = "fat"`.

```bash
cd spikes/llvm16/klee-rt && RUSTUP_TOOLCHAIN=1.72.1 cargo rustc --release -- --emit=llvm-bc
llvm-dis-16 target/release/deps/klee_rt-*.bc     # dis16=0
llvm-link-16 ../prog.bc target/release/deps/klee_rt-*.bc -o linked.bc && klee linked.bc
```

```
rustc 1.72.1 (d5c2e9c34 2023-09-13)   LLVM version: 16.0.5
warning: Linking two modules of different target triples: '...klee_rt-...bc' is 'x86_64-unknown-linux-gnu' whereas 'llvm-link' is 'x86_64-pc-linux-gnu'
KLEE: WARNING: undefined reference to function: rust_eh_personality
KLEE: WARNING ONCE: Alignment of memory from call "malloc" is not modelled. Using alignment of 8.
KLEE: done: total instructions = 350
KLEE: done: completed paths = 2
KLEE: done: partially completed paths = 0
KLEE: done: generated tests = 2
ktest: __VERIFIER_nondet_int int: 42      ktest: __VERIFIER_nondet_int int: 0
```

Resultado: **passa, com 2 caminhos, como esperado.** O LTO é necessário. Sem ele (`CARGO_PROFILE_RELEASE_LTO=false`), o `--emit=llvm-bc` não inclui o código de `alloc`/`core`, e o KLEE para:

```
KLEE: WARNING: undefined reference to function: _ZN5alloc5alloc18handle_alloc_error...
KLEE: WARNING: undefined reference to variable: __rust_no_alloc_shim_is_unstable
KLEE: ERROR: Unable to load symbol(__rust_no_alloc_shim_is_unstable) while initializing globals
```

### A′ com `std` (`spikes/llvm16/klee-rt-std`, fora do brief)

`Mutex<Vec<i32>>`, `println!`, LTO fat. O bitcode tem 391 definições e 73 declarações. Ele liga com `llvm-link-16`, mas o KLEE aborta:

```
inlinable function call in a function with debug info must have a !dbg location
LLVM ERROR: Broken module found, compilation aborted!
```

O debug info do `std` pré-compilado é incompatível com o verificador. Ao rodar `opt-16 --strip-debug` no bitcode, passa:

```
{"result":"TRUE","nondets":1}
KLEE: done: completed paths = 2        (sem libc; com --libc=uclibc --posix-runtime: idem, 15 371 instruções)
```

Restam referências indefinidas, todas em funções que o programa não executa. `klee3.log` é a execução sem libc; `klee4.log` usa `--libc=uclibc --posix-runtime`:

```bash
grep -c "undefined reference" klee3.log    # 34
grep -c "undefined reference" klee4.log    # 17
```

Exemplos, nos dois logs: `_Unwind_Backtrace`, `_Unwind_GetIP`, `_Unwind_SetIP`, `__cxa_thread_atexit_impl`, `bcmp`, `dl_iterate_phdr` e `pthread_key_create`. Com a biblioteca real (`klee-full.log`), aparecem também `getrandom` e `statx`.

### A′ com a biblioteca real (`spikes/llvm16/full172`, fora do brief)

Cópia de `Cargo.toml` + `rust/` com rustc 1.72.1. Obstáculos, em ordem:

1. `error: failed to parse lock file at: /src/Cargo.lock`: o lockfile v4 não é lido pelo cargo 1.72.
2. Sem o lockfile, o resolvedor do 1.72 escolhe crates com `edition = "2024"` (`getrandom 0.4.3`, `wit-bindgen 0.57.1` via `mockall` e `cbindgen`). Correção: tirar `[dev-dependencies]` e `build.rs` (cbindgen) da cópia, declarar `rust-version = "1.72"` e gerar o lockfile assim: `rustup toolchain install 1.86.0 --profile minimal && CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS=fallback RUSTUP_TOOLCHAIN=1.86.0 cargo generate-lockfile && sed -i 's/^version = 4/version = 3/' Cargo.lock`. Resultado: `serde 1.0.229`, `serde_json 1.0.154`, `thiserror 2.0.20`.
3. Seis erros de fonte com o 1.72.1:
   ```
   error: extern block cannot be declared unsafe            --> rust/src/nondet/libfuzzer.rs:44
   error[E0658]: use of unstable library feature 'lazy_cell' --> rust/src/state.rs:4, :14, :15 (x2)
   error[E0658]: use of unstable library feature 'mutex_unpoison' --> rust/src/state.rs:68
   ```
   Correção: `extern "C"` sem `unsafe`, `LazyLock` → `OnceLock::get_or_init` e remoção de `clear_poison()`. As duas primeiras compilam igual em 1.82. A terceira muda o comportamento do build normal, porque o mutex envenenado deixa de ser limpo. O custo e a mitigação (`#[cfg(not(feature = "klee"))]`) estão na D1, em `decisoes.md`.
4. Para o KLEE, um módulo novo `nondet/klee.rs` (feature `klee`, que não existe no repo e é só do spike) com `__VERIFIER_nondet_int` → `klee_make_symbolic`, que registra o valor no `AnalysisState` real.

```bash
cd spikes/llvm16/full172      # manifesto próprio: build = false, sem dev-deps, [workspace], Cargo.lock v3
RUSTUP_TOOLCHAIN=1.72.1 CARGO_TARGET_DIR=/src/spikes/llvm16/target-172c \
  cargo rustc --release --features klee --lib --crate-type staticlib -- --emit=llvm-bc -C panic=abort
opt-16 --strip-debug /src/spikes/llvm16/target-172c/release/deps/map2check-*.bc -o rt-nodbg.bc          # só o runtime; o programa mantém -g
clang-16 -g -emit-llvm -c prog.c -o prog-g.bc
llvm-link-16 prog-g.bc rt-nodbg.bc -o linked5.bc
klee --external-calls=all --optimize --use-cex-cache --libc=uclibc linked5.bc   # subconjunto das flags de caller.cpp:815-822
```

```
KLEE: done: total instructions = 68391
KLEE: done: completed paths = 22
KLEE: done: partially completed paths = 0
KLEE: done: generated tests = 22
```

Ficaram de fora estas flags do frontend: `--solver-backend=<solver>` (ou `--solver-backend=metasmt --metasmt-backend=<solver>`), as políticas de parada e de busca, e a flag de sementes.

Há 21 relatórios JSON `"result": "TRUE"` com `Container_NonDetLog` preenchido. Entre os ktests estão `42` (o caminho de `return 1`, sem relatório), `0`, `1`, `-8`, `-2147483648` etc. Sem o `--strip-debug` no runtime, o resultado é o mesmo `Broken module found` da variante `std`.

**Explosão de caminhos:** a saída tem 22 caminhos, não 2. A serialização do valor simbólico pelo `serde_json` (formatação de inteiros) ramifica sobre o símbolo. O runtime C escreve o log por chamada externa, que concretiza o valor. O runtime Rust para KLEE precisa concretizar antes de formatar (`klee_get_value_i32`) ou não serializar valores simbólicos.

Resultado: **a biblioteca real roda no KLEE 3.1/LLVM 16 pela rota A′**, com MSRV 1.72 (seis ajustes de fonte e `Cargo.lock` próprio), LTO fat, `--strip-debug` do runtime e concretização na saída.

## Rota C: levar o Map2Check para LLVM 19 (pesquisa)

```bash
cd Map2Check-cutover/modules/backend/pass
grep -ohE 'llvm::[A-Za-z:]+' *.cpp | sort -u | wc -l          # 49
grep -ohE 'llvm::[A-Za-z:]+' *.cpp *.hpp | sort -u | wc -l    # 60
```

Os números de tamanho e de uso saem destes comandos, rodados no mesmo diretório:

```bash
cat *.cpp *.hpp | wc -l                                                              # 4253
grep -c "using llvm::\|namespace llvm" *.cpp *.hpp | awk -F: '{s+=$2} END{print s}'  # 163
grep -ohE '\b(startswith|endswith|CreateGlobalStringPtr|insertBefore|getTerminator|getOrInsertFunction|DebugLoc|dbg\.declare|DbgDeclareInst)\b' *.cpp *.hpp | sort | uniq -c | sort -rn
#  33 getOrInsertFunction  25 CreateGlobalStringPtr  5 DebugLoc  4 endswith
#   3 DbgDeclareInst         2 startswith             1 insertBefore  1 getTerminator  1 dbg.declare
grep -ohE '\b(FunctionCallee|PassManager|PassPluginLibraryInfo|PointerType::get)\b' *.cpp *.hpp | sort | uniq -c
#  58 FunctionCallee  10 PassManager  10 PassPluginLibraryInfo  44 PointerType::get
```

A contagem de passes vem do `CMakeLists.txt`, que tem 9 entradas em `MAP2CHECK_PASS_LIB`. Usos que quebram ou mudam de semântica entre LLVM 16 e 19:

| Uso | Contagem | Situação no LLVM 19 |
|---|---|---|
| `StringRef::startswith` / `endswith` | 2 + 4 | removidos (renomeados para `starts_with`/`ends_with`). Erro de compilação, troca mecânica |
| `DbgDeclareInst` / `dbg.declare` | 3 + 1 | o LLVM 19 representa debug info como *debug records* (RemoveDIs). Iterar instruções não acha mais `dbg.declare`. **Mudança de semântica**, exige revisão |
| `CreateGlobalStringPtr` | 25 | ainda existe no 19 (deprecado no 20) |
| `getOrInsertFunction` / `FunctionCallee` | 33 / 58 | estável |
| `PassPluginLibraryInfo` / `PassManager` (novo PM) | 10 / 10 | já no novo PM; estável |

KLEE: releases no GitHub, consultadas em 2026-10-15 com `curl -s https://api.github.com/repos/klee/klee/releases`. As frases entre aspas são citações literais do corpo de cada release:

- **v3.1** (2024-02-29, a da imagem): LLVM 11–16.
- **v3.2** (2025-12-23): "Added partial support for LLVM 17-19 (@mrexodia)" e "Current recommended version is LLVM 16". <https://github.com/klee/klee/releases/tag/v3.2>
- **v3.3** (`published_at` 2026-10-15T15:14:13Z, mesmo dia do spike): "Added full support for LLVM 17-19 (@ccadar)" e "Current recommended version is LLVM 18". <https://github.com/klee/klee/releases/tag/v3.3>

Resposta: **sim, há KLEE com suporte a LLVM 19 (3.3)**, mas a release saiu hoje e não foi testada aqui. Não verifiquei se o AFL++ 4.40c compila com LLVM 19. Estimativa da Rota C: os passes são P–M (troca mecânica mais revisão do tratamento de debug info, cerca de 2 a 4 dias). Somam-se a reconstrução da imagem (clang/LLVM 19, KLEE 3.3 + STP/Z3 + klee-uclibc para LLVM 19, AFL++ recompilado) e a revalidação dos baselines de corpus, porque todo o pipeline muda de versão. No total, G (1 a 2 semanas), com o risco de ser a primeira versão de KLEE com suporte completo a LLVM 19.

## Remedição (Task 2.5b)

Data: 2026-10-15. Biblioteca no commit `f4e4908` (branch `cutover/runtime-rust`): o leitor de entrada segue o `NonDetGeneratorAFL.c` (volta ao início do buffer, `sizeof(tipo)` bytes por valor) e um `__VERIFIER_assume` falso abandona a entrada sem encerrar o processo persistente (desenrola até o `LLVMFuzzerTestOneInput`, que devolve 0). Responde às condições 3 e 4 da D1.

### Montagem

Tudo na imagem `map2check-dev:cutover-rust`, com `docker run --rm --cpus 4`. As campanhas rodaram **em sequência**, um fuzzer por vez, 5 repetições de cada variante.

- **B1:** `libmap2check.a` do perfil `runtime` com `--features libfuzzer` (rustc 1.82 da imagem), ligado com `afl-clang-fast -g -O2 -fsanitize=fuzzer` ao programa com `-Dmain=__map2check_main__`; o binário CmpLog com `AFL_LLVM_CMPLOG=1`. Comandos iguais aos de `b1build.sh` do spike.
- **B2:** o runtime C de `develop` compilado **das fontes** (`modules/backend/library/lib/*.c`, `clang-16 -c -emit-llvm`, como o `CMakeLists.txt` da biblioteca), na ligação de alcançabilidade do `caller.cpp` (`Map2CheckFunctions`, `TrackBBLog`, `NonDetLog`, `PropertyGenerator`, `ContainerRealloc`, `AnalysisModeNone`, `NonDetGeneratorAFL`, `WitnessGenerationNone`), `llvm-link-16` e `afl-clang-fast -g -O2`. Comandos iguais aos de `b2build.sh` do spike.
- **Programas:** `prog42.c` / `prog42_c.c` do spike (o `prog.c` com `abort()` em `x == 42`, para o crash ser contado) e um programa com muitos `assume`, em duas formas como as anteriores:

```c
/* assume.c (B1); assume_c.c (B2) chama map2check_non_det_int,
 * map2check_assume (= nondet_assume, Map2CheckFunctions.c:45) e map2check_init(0) */
int main(void) {
  map2check_init();
  int x = __VERIFIER_nondet_int();
  __VERIFIER_assume(x > 100);
  __VERIFIER_assume(x < 200);
  if (x == 150) abort();
  map2check_success();
  return 0;
}
```

- **Campanha:** semente `A` (a do frontend, `caller.cpp:904-907`) e o ambiente do frontend (`caller.cpp:919-925`) sem `AFL_BENCH_UNTIL_CRASH`, para a campanha durar os 30 s inteiros:

```bash
AFL_NO_UI=1 AFL_NO_AFFINITY=1 AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
AFL_CRASHING_SEEDS_AS_NEW_CRASH=1 afl-fuzz -i seed -o runs/<v>-<prog>-<cmplog>-<rep> -V 30 \
  [-c ./<v>-<prog>.cmplog.afl] -- ./<v>-<prog>.afl
```

  Ordem: para cada repetição, `prog42` e depois `assume`; sem e com CmpLog; B1 e depois B2. O 1º crash vem do nome do primeiro arquivo em `crashes/` (`time`, `execs`, `op`).

Antes das campanhas, um teste diferencial ligou um programa que lê um valor de cada tipo (16 tipos, `pchar` incluído) ao B1 e ao B2 e comparou as saídas para entradas de 1, 2, 4, 7, 7 (`pchar` de tamanho 5), 37, 64 e 200 bytes: **idênticas em todas** (B2 lendo da stdin, B1 pelo `LLVMFuzzerTestOneInput`).

### Dados brutos

| rep | rota | programa | CmpLog | `execs_per_sec` | `execs_done` | `stability` | 1º crash (`time` ms, `execs`, `op`) |
|---|---|---|---|---|---|---|---|
| 1 | B1 | `prog42` | não | 113373,29 | 3 401 312 | 100,00% | 3636, 397 890, `havoc` |
| 1 | B2 | `prog42` | não | 96080,26 | 2 882 504 | 75,68% | 82, 1 677, `havoc` |
| 1 | B1 | `prog42` | sim | 113733,28 | 3 412 112 | 100,00% | 231, 14 988, `havoc` |
| 1 | B2 | `prog42` | sim | 95805,70 | 2 876 183 | 78,38% | 207, 544, `its` |
| 1 | B1 | `assume` | não | 67556,28 | 2 027 837 | 100,00% | 246, 19 009, `havoc` |
| 1 | B2 | `assume` | não | 115492,63 | 3 465 010 | 80,00% | 295, 27 045, `havoc` |
| 1 | B1 | `assume` | sim | 102674,16 | 3 080 430 | 100,00% | 247, 7 843, `havoc` |
| 1 | B2 | `assume` | sim | 123441,82 | 3 703 378 | 100,00% | 204, 1 534, `havoc` |
| 2 | B1 | `prog42` | não | 116556,51 | 3 496 812 | 100,00% | 201, 15 586, `havoc` |
| 2 | B2 | `prog42` | não | 98477,62 | 2 954 427 | 75,68% | 1436, 130 559, `havoc` |
| 2 | B1 | `prog42` | sim | 115136,56 | 3 454 212 | 100,00% | 822, 86 511, `havoc` |
| 2 | B2 | `prog42` | sim | 97434,11 | 2 924 777 | 78,38% | 189, 538, `its` |
| 2 | B1 | `assume` | não | 59714,79 | 1 792 220 | 100,00% | 109, 2 636, `havoc` |
| 2 | B2 | `assume` | não | 116131,52 | 3 484 178 | 80,00% | 82, 1 306, `havoc` |
| 2 | B1 | `assume` | sim | 59930,52 | 1 803 729 | 100,00% | 145, 8 689, `havoc` |
| 2 | B2 | `assume` | sim | 101517,68 | 3 046 850 | 100,00% | 469, 37 277, `havoc` |
| 3 | B1 | `prog42` | não | 116879,84 | 3 506 512 | 100,00% | 1991, 229 706, `havoc` |
| 3 | B2 | `prog42` | não | 97799,48 | 2 934 180 | 75,68% | 671, 56 521, `havoc` |
| 3 | B1 | `prog42` | sim | 115509,88 | 3 465 412 | 100,00% | 298, 25 229, `havoc` |
| 3 | B2 | `prog42` | sim | 98499,00 | 2 955 167 | 78,38% | 196, 545, `its` |
| 3 | B1 | `assume` | não | 100495,07 | 3 015 053 | 100,00% | 513, 48 445, `havoc` |
| 3 | B2 | `assume` | não | 106180,13 | 3 185 510 | 80,00% | 140, 9 025, `havoc` |
| 3 | B1 | `assume` | sim | 80445,25 | 2 414 001 | 100,00% | 158, 8 272, `havoc` |
| 3 | B2 | `assume` | sim | 107068,98 | 3 212 819 | 100,00% | 298, 13 751, `havoc` |
| 4 | B1 | `prog42` | não | 116096,53 | 3 483 012 | 100,00% | 801, 83 658, `havoc` |
| 4 | B2 | `prog42` | não | 98181,92 | 2 945 654 | 75,68% | 5951, 594 288, `havoc` |
| 4 | B1 | `prog42` | sim | 115666,54 | 3 470 112 | 100,00% | 1346, 146 540, `havoc` |
| 4 | B2 | `prog42` | sim | 96819,37 | 2 904 678 | 78,38% | 190, 539, `its` |
| 4 | B1 | `assume` | não | 64018,25 | 1 922 532 | 100,00% | 208, 16 015, `havoc` |
| 4 | B2 | `assume` | não | 112247,26 | 3 367 530 | 80,00% | 291, 26 376, `havoc` |
| 4 | B1 | `assume` | sim | 75394,05 | 2 261 897 | 100,00% | 103, 1 936, `havoc` |
| 4 | B2 | `assume` | sim | 123763,01 | 3 713 014 | 100,00% | 629, 46 719, `havoc` |
| 5 | B1 | `prog42` | não | 116389,85 | 3 491 812 | 100,00% | 590, 59 409, `havoc` |
| 5 | B2 | `prog42` | não | 98060,26 | 2 942 102 | 75,68% | 416, 34 493, `havoc` |
| 5 | B1 | `prog42` | sim | 115703,21 | 3 471 212 | 100,00% | 836, 88 894, `havoc` |
| 5 | B2 | `prog42` | sim | 97957,20 | 2 938 814 | 78,38% | 185, 650, `its` |
| 5 | B1 | `assume` | não | 57883,57 | 1 736 565 | 100,00% | 103, 3 406, `havoc` |
| 5 | B2 | `assume` | não | 115598,85 | 3 468 081 | 80,00% | 118, 4 449, `havoc` |
| 5 | B1 | `assume` | sim | 64970,70 | 1 949 446 | 100,00% | 91, 1 497, `havoc` |
| 5 | B2 | `assume` | sim | 99577,21 | 2 987 416 | 100,00% | 227, 4 740, `havoc` |

### Medianas (n = 5)

| Programa | CmpLog | exec/s B1 | exec/s B2 | B1/B2 | 1º crash B1 (ms; execs) | 1º crash B2 (ms; execs) | B1 ÷ B2 |
|---|---|---|---|---|---|---|---|
| `prog42` | não | 116 390 | 98 060 | **118,7%** | 801; 83 658 | 671; 56 521 | 1,19× |
| `prog42` | sim | 115 510 | 97 434 | **118,6%** | **822; 86 511** | **190; 544** | **4,33×** |
| `assume` | não | 64 018 | 115 493 | **55,4%** | 208; 16 015 | 140; 9 025 | 1,49× |
| `assume` | sim | 75 394 | 107 069 | **70,4%** | 145; 7 843 | 298; 13 751 | 0,49× |

Todas as 40 campanhas acharam o crash. Estabilidade: B1 100% em todas; B2 75,68% (`prog42`), 78,38% (`prog42` com CmpLog), 80% e 100% (`assume`).

### Leitura

**Throughput (condição 3).** No `prog42` o B1 fica em 119% do B2, agora com o B2 gravando arquivos e as campanhas em sequência. No programa com `assume`, quase toda entrada é rejeitada, e o B1 cai para **55%** (sem CmpLog) e **70%** (com CmpLog) do B2. O B2 rejeita com `longjmp`, que custa poucos nanossegundos; o B1 rejeita com um desenrolar de pilha (`resume_unwind` + `catch_unwind`), que passa pelo unwinder (`_Unwind_RaiseException`, busca de FDE) a cada rejeição. O B1 também varia mais entre repetições (57 884 a 100 495 exec/s sem CmpLog), o que é consistente com o custo crescer com a fração de entradas rejeitadas.

**Tempo até o 1º crash com CmpLog (condição 4).** No `prog42` o B2 achou o crash pela etapa input-to-state (`op:its`) nas 5 repetições, em 185 a 207 ms; o B1, por havoc nas 5, com mediana de 822 ms. Corrigir o leitor (a hipótese principal) **não fechou a diferença**. Linha de base com a biblioteca de antes desta task (`0d5b1f6`, leitor que devolvia 0), mesmo protocolo, só `prog42` com CmpLog: 102, 749, 2 845, 115 e 1 083 ms, mediana **749 ms**, todas por havoc. A diferença está no corpus. No B2, o runtime C é instrumentado, e o ramo de volta ao início do buffer de `get_next_input_from_afl` é uma aresta nova: entradas de 2 e 4 bytes (`41 41`, `c0 c0 c0 c0`) entram no corpus em 50 execuções (`corpus_count` 4), e o input-to-state troca os 4 bytes do `c0c0c0c0` por `2a 00 00 00`. No B1 o leitor é Rust não instrumentado, o corpus fica só com a semente `A` (`corpus_count` 1), e o input-to-state não consegue pôr um operando de 4 bytes numa entrada de 1 byte. É a hipótese secundária da condição 4.

Verificação (informativa, não altera o protocolo): a mesma campanha `prog42` com CmpLog, mas com a semente `AAAA` e `AFL_BENCH_UNTIL_CRASH=1`, 5 repetições sequenciais. O B1 achou o crash em 171 a 184 ms (13 execs, `op:its`) e o B2 em 170 a 184 ms (25 execs, `op:its`): as duas rotas ficam iguais quando a semente já tem o tamanho do valor lido.

No programa com `assume`, com CmpLog, o B1 achou o crash antes do B2 (mediana 145 ms contra 298 ms).

### Veredito contra os critérios da D1

- **Condição 3 (throughput ≥ 90% do B2): NÃO ATENDIDA.** Atendida no `prog42` (119%), não atendida no programa com `assume` (55% sem CmpLog, 70% com CmpLog).
- **Condição 4 (1º crash com CmpLog não pior que 2× a mediana do B2): NÃO ATENDIDA** no `prog42` (822 ms contra 190 ms, 4,33×); atendida no programa com `assume` (0,49×).

A rota da D1 não foi alterada. Caminhos possíveis, para decisão do controlador: (a) para a condição 4, uma semente no frontend (Task 3.x) com pelo menos o tamanho do maior valor lido (8 bytes cobrem `long`, `double` e ponteiros); com 4 bytes e um `int`, o teste acima igualou B1 e B2; (b) para a condição 3, rejeitar a entrada sem desenrolar a pilha, por exemplo com um `setjmp` num trecho C ligado à biblioteca (exige compilar C no `build.rs`, e o `longjmp` só é definido se nenhum frame Rust pulado tiver destrutor); (c) a alternativa nomeada na D1, o B2 (port do `__AFL_LOOP`).

## Como reproduzir

Na branch `spike/llvm16`: `spikes/llvm16/{b1build.sh,b2build.sh,fuzz.sh}`, `klee-rt/`, `klee-rt-std/`, `full172/` (com o `Cargo.lock` v3 usado) e `Dockerfile.rust`.
