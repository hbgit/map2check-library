# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Map2Check-Library is a Rust library with a C ABI for the Map2Check program verification tool. It tracks memory, basic blocks, and nondeterministic values, and checks safety properties (overflow, memory safety, assert reachability) in programs analyzed by LibFuzzer. The build produces the static library (`libmap2check.a`) and generates `include/map2check.h`. Remaining parity work with the legacy C implementation is tracked in [TODO.md](TODO.md).

## Build Commands

The project uses the Rust toolchain pinned in `rust-toolchain.toml`. Run Cargo commands from the repository root.

```sh
# Debug build
cargo build

# Release build
cargo build --release

# Generate the C header and build all features
cargo build --all-features
```

## Running Tests

```sh
# Run all Rust unit tests
cargo test --all-features

# Lint and dependency checks (also run in CI)
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo deny check

# Exercise the C ABI with ASan and UBSan (requires clang)
cargo build --release --all-features
clang -fsanitize=address,undefined -fno-omit-frame-pointer \
  tests/ffi_harness.c target/release/libmap2check.a \
  -ldl -lpthread -lm -o target/ffi_harness
target/ffi_harness
```

## Architecture

### Source Layout

- [rust/src/](rust/src/) — Rust implementation and C FFI
- [tests/ffi_harness.c](tests/ffi_harness.c) — C ABI stress harness

### Module Packages

Each package lives in a subdirectory of `rust/src/`:

| Package | Purpose |
|---|---|
| `caller/` | Result and violated-property types, global step counter. |
| `nondet/` | Typed nondeterministic values and LibFuzzer generators. |
| `memtrack/` | Memory allocation tracking and memory-safety checks. |
| `bbtrack/` | Basic-block entries and lookup. |
| `analysismode/` | Verification condition checkers: `analysis_assert` (assert reachability), `analysis_overflow` (arithmetic overflow), `analysis_memory` (memory safety). |

### Container Pattern

Analysis records are stored in vectors in the process-wide `AnalysisState`, protected by a mutex and reset by `map2check_reset()`.

### Output Format

At analysis end, `print_all_containers_as_json()` serializes the state to RFC 8259 JSON on stdout using `serde_json`.

### Generated Header

`build.rs` runs `cbindgen` (config in `cbindgen.toml`) and rewrites `include/map2check.h`. Change Rust exports or `cbindgen.toml`, never the header.

## Repository Conventions

- Commits must have verified signatures.
- Never add AI attributions (e.g. "Co-authored-by", "Generated with ...") to commits or PR descriptions.
- See [.github/copilot-instructions.md](.github/copilot-instructions.md) for the same conventions in more detail.

## Regras obrigatórias

1. **GitHub CLI e ações remotas somente sob solicitação explícita.**
   Não execute, sem um pedido explícito do usuário na mensagem atual, comandos `gh` que
   criem, alterem ou encerrem algo no GitHub: `gh pr create/merge/close/comment/review`,
   `gh issue create/close/comment/edit`, `gh release`, `gh repo` e similares. O mesmo vale
   para `git push`, criação de tags remotas e alteração de branches remotos. Comandos apenas
   de leitura (`gh pr view`, `gh issue list`) são permitidos. Na dúvida, pergunte antes.

2. **Escopo restrito a este repositório.**
   Todas as modificações de código, testes, configurações e documentação devem ser feitas
   somente neste repositório. Nunca altere, faça commit ou abra PR/issue no repositório do
   Map2Check, nem em qualquer outro repositório.

3. **Map2Check para testes de integração: cópia local e sem versionamento.**
   - Baixe o Map2Check sempre do branch `develop`, para o diretório `vendor/map2check/` (ou
     outro que o usuário indicar), por meio de
     `git clone --depth 1 --branch develop <url> vendor/map2check`. Não use tags nem tarballs
     de release.
   - Logo após o download, remova o versionamento com `rm -rf vendor/map2check/.git`, para
     que nenhum comando git atue sobre o repositório original.
   - Garanta que `vendor/map2check/` esteja no `.gitignore` deste repositório, para que a
     cópia não seja commitada aqui.
   - Registre o commit do `develop` baixado (por exemplo, em `vendor/MAP2CHECK_VERSION`) para
     tornar os testes reproduzíveis.
   - Não edite os fontes baixados. Se um teste exigir mudanças no Map2Check, pare e informe
     o usuário.

## Key Entry Points

- `map2check_init(int isSvComp)` — initializes the global analysis state (C runtime signature)
- `map2check_success()` / `set_false_result(prp, line, func)` — set final verification result
- `print_all_containers_as_json()` — emits the JSON result report
- `map2check_is_valid_assert()`, `map2check_map_malloc()`, `map2check_map_free()` etc. — called by LLVM instrumentation passes in the Map2Check tool
