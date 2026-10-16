# Decisões do cutover do runtime C do Map2Check

Registro das decisões D1–D5 do plano `docs/superpowers/plans/2026-10-15-cutover-runtime-c-map2check.md`. Uma decisão só vale depois de aprovada pelo mantenedor (comentário na issue #20).

## D1

**Pergunta:** como o runtime Rust entra no pipeline LLVM 16 do Map2Check (`develop`: clang/LLVM 16.0.6, AFL++ 4.40c, KLEE 3.1), e como o AFL++ dirige as entradas.

**Status: PROPOSTA — aguardando aprovação do mantenedor**

Evidência: `docs/cutover/spike-llvm16.md` (Task 1.1). Código na branch local `spike/llvm16`.

### Proposta por gerador

| Gerador | Rota proposta | Evidência principal |
|---|---|---|
| `none` | **B**: `libmap2check.a` nativo (rustc do repo, 1.82) ligado no passo final, sem `llvm-link` | A rota B liga e roda com clang-16 (`rc=0`). O frontend de `develop` não executa o modo `none` (`Caller::executeAnalysis`: "This mode is not supported"; `map2check.cpp:977` troca `None` por AFL++). Basta que a ligação funcione, e ela usa o mesmo artefato do `afl`. |
| `afl` | **B + B1**: `libmap2check.a` nativo + driver libFuzzer do AFL++ (`afl-clang-fast -fsanitize=fuzzer`), chamando o `LLVMFuzzerTestOneInput` da biblioteca | Em 30 s, o B1 fez 97 474 exec/s contra 42 919 do `NonDetGeneratorAFL.c` (227%; 229% com CmpLog). Os dois acharam `x == 42`, com 1 `saved_crashes` cada. O critério da D1 (≥ 90% do C) é atendido sem portar o `__AFL_LOOP` para Rust (B2). |
| `symex` | **A′**: runtime compilado para bitcode por um rustc com LLVM 16 (1.72.1, LLVM 16.0.5), LTO fat, `opt-16 --strip-debug` só no runtime e `llvm-link-16` com o `-result.bc` | A rota A falha (`llvm-dis-16: error: Unknown attribute kind (91) (Producer: 'LLVM19.1.1-rust-1.82.0-stable' Reader: 'LLVM 16.0.6')`). A rota B sob KLEE dá 1 caminho, sem explorar `x == 42`. A A′ dá 2 caminhos (ktests 42 e 0) na crate `no_std` do brief. A **biblioteca real** (`std`, `serde_json`, `Mutex`) também roda no KLEE 3.1 com as flags do `caller.cpp`: 22 caminhos completos, `x == 42` encontrado. |

A rota C (Map2Check em LLVM 19) fica como **alternativa futura para `symex`**, não como caminho do cutover. O KLEE 3.3, com "full support for LLVM 17-19", saiu em 2026-10-15 e não foi testado. Migrar o pipeline inteiro custa G (1 a 2 semanas) mais a revalidação dos baselines.

O `symex` **não está bloqueado**: existe uma rota medida que funciona. A consequência prevista no brief para o caso de nenhuma rota servir não se aplica. O texto era: "o cutover completo fica bloqueado: pela restrição 'não remover sem equivalente validado', o runtime C do KLEE não pode sair".

### Comandos de build e ligação que a Task 3.1 implementa

`none` e `afl` (o passe já renomeia `main` para `__map2check_main__`):

```bash
# biblioteca (rustc do repo)
cargo build --release --features libfuzzer          # -> target/release/libmap2check.a
# programa: o -result.bc sai do llvm-link SEM os .bc do runtime C
afl-clang-fast -g -O2 -fsanitize=fuzzer <hash>-result.bc libmap2check.a -ldl -lpthread -lm -o <hash>-fuzzed.out
AFL_LLVM_CMPLOG=1 afl-clang-fast -g -O2 -fsanitize=fuzzer <hash>-result.bc libmap2check.a -ldl -lpthread -lm -o <hash>-cmplog.out
afl-fuzz -i afl-in -o afl-out -c ./<hash>-cmplog.out -- ./<hash>-fuzzed.out
# replay: o crash vai como ARGUMENTO, não pela stdin (ver condição 2)
./<hash>-witness-fuzzed.out <crash-file>
```

`symex`:

```bash
# runtime em bitcode LLVM 16 (toolchain separado, LTO fat no perfil)
RUSTUP_TOOLCHAIN=1.72.1 cargo rustc --release --features klee --lib --crate-type staticlib -- --emit=llvm-bc -C panic=abort
opt-16 --strip-debug target/release/deps/map2check-*.bc -o map2check-klee.bc
llvm-link-16 <hash>-output.bc map2check-klee.bc -o <hash>-witness-result.bc
klee --external-calls=all --optimize --use-cex-cache --libc=uclibc ./<hash>-witness-result.bc
```

### Condições da proposta (o que a aprovação aceita junto)

1. **`main` renomeado é obrigatório.** Com o `prog.c` cru, a ligação falha (`multiple definition of 'main'` no LibFuzzer; `undefined reference to '__map2check_main__'` no LibFuzzer e no AFL++). O passe atual já renomeia o `main`; isso não pode regredir.
2. **Replay pela stdin não funciona com B1.** `./b1.afl < crash` não termina (`rc=124` após 5 s), enquanto `./b1.afl crash` aborta (`rc=134`). O frontend (`caller.cpp:957`) hoje redireciona o arquivo para a stdin e precisa passar a usar argumento.
3. **`assume` em persistent mode.** O C faz `longjmp` e segue para a próxima entrada. O Rust faz `exit(0)` (`libfuzzer.rs`, `__VERIFIER_assume`), que derruba o processo persistente. O throughput medido não cobre programas com `assume`. Medir na Task 2.5 antes de fechar o B1. Se cair abaixo de 90% do C, a resposta é B2 (port do loop).
4. **MSRV 1.72 para o build `symex`.** Com rustc 1.72.1, a biblioteca real tem 6 erros de fonte: `unsafe extern` (1), `LazyLock` (4) e `Mutex::clear_poison` (1). Também precisa de um `Cargo.lock` v3 resolvido por MSRV (`serde_json 1.0.154`, `thiserror 2.0.20`), sem `mockall`/`cbindgen` no grafo desse build. Trocas usadas no spike: `extern "C"`, `OnceLock`, sem `clear_poison`. Alternativa: um crate `no_std` separado só para KLEE (rota A′ do brief, comprovada), ao custo de duplicar a lógica de estado.
5. **LTO fat e `--strip-debug` no runtime `symex` são obrigatórios.** Sem LTO: `KLEE: ERROR: Unable to load symbol(__rust_no_alloc_shim_is_unstable)`. Com o debug info do `std`: `LLVM ERROR: Broken module found` ("inlinable function call in a function with debug info must have a !dbg location"). O `-g` do programa analisado é preservado.
6. **Concretizar antes de serializar no `symex`.** O `serde_json` formatando valores simbólicos levou `prog.c` de 2 para 22 caminhos. O gerador KLEE do Rust precisa concretizar (`klee_get_value_*`) o que vai para o log, como o C faz ao escrever por chamada externa.
7. **A rota B sob KLEE não é usada.** Além de não explorar símbolos, o KLEE 3.1 não tem `--load` (`Unknown command line argument '--load=...'`), e a `.so` só carrega com `LD_PRELOAD` e `-Wl,-z,lazy`.
8. **O `rustc 1.72.1` (2023) fica preso ao LLVM 16.** Quando o Map2Check migrar de LLVM, o toolchain do `symex` precisa acompanhar. A rota C remove essa dependência.
