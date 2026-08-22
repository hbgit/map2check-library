[![License](https://img.shields.io/badge/license-GPL--3-lighgreen)](../master/LICENSE)
[![Build Status](https://travis-ci.org/hbgit/map2check-library.svg?branch=master)](https://travis-ci.org/hbgit/map2check-library)
[![codecov](https://codecov.io/gh/hbgit/map2check-library/branch/master/graph/badge.svg)](https://codecov.io/gh/hbgit/map2check-library)

# Map2Check-Library

Biblioteca de suporte à ferramenta [Map2Check](https://github.com/hbgit/map2check), reescrita em **Rust** (rewrite completo do C original). Provê rastreamento dinâmico e verificação de propriedades de segurança para programas analisados por KLEE ou LibFuzzer:

- Rastreamento de blocos básicos (`bbtrack`)
- Rastreamento de endereços de memória e operações de gerenciamento de memória (`memtrack`)
- Rastreamento de valores não-determinísticos gerados por KLEE e LibFuzzer (`nondet`)
- Verificação de propriedades de segurança: overflow aritmético, memória inválida, assert definido pelo usuário (`analysismode`)
- API C compatível via FFI (`ffi.rs`) para integração direta com a LLVM Pass do Map2Check

## Requisitos

O projeto exige **Rust 1.82.0**, conforme definido em `rust-toolchain.toml` (edição 2021). O `rustup` seleciona automaticamente esse toolchain ao executar os comandos na raiz do projeto.

Ferramentas necessárias:

- `rustup` e `cargo`
- Componentes Rust `clippy` e `rustfmt`
- Docker, para o build da imagem
- `cargo-tarpaulin`, `cargo-audit`, `cargo-deny` e `cbindgen` para cobertura, auditoria e desenvolvimento
- `clang` e `llvm-link` para a geração do bitcode usado pelo KLEE

```sh
rustup component add clippy rustfmt
cargo install cargo-tarpaulin cargo-audit cargo-deny cbindgen
```

## Features disponíveis

As features configuradas no `Cargo.toml` são:

- `libfuzzer`: habilita a integração com o LibFuzzer.
- `klee`: habilita o build de bitcode para integração com o KLEE.

## Build e testes

Execute os comandos a seguir na raiz do projeto:

```sh
# Compilar a biblioteca em modo release
cargo build --release

# Checar lint e possíveis erros
cargo clippy

# Verificar e formatar o código
cargo fmt

# Rodar todos os testes com todas as features ativadas
cargo test --all-features
```

O artefato principal é gerado em `target/release/libmap2check.a`.

### Cobertura

Para gerar o relatório de cobertura localmente:

```sh
cargo tarpaulin --out Html --output-dir coverage/ --all-features
```

O relatório HTML fica em `coverage/tarpaulin-report.html`.

### Geração do header C

O arquivo `include/map2check.h` é gerado automaticamente durante a compilação. O script `build.rs` executa o `cbindgen` usando `cbindgen.toml` e grava o resultado na pasta `include/`. Portanto, não é necessário gerar o header manualmente.

### Build via Docker

O `Dockerfile` na raiz usa um build multi-stage para compilar a biblioteca, gerar o bitcode do KLEE, executar os testes e gerar a cobertura:

```sh
docker build -t hbgit/map2check-library .
```

Para executar o script de integração com KLEE:

```sh
docker pull klee/klee:2.2
./run_klee_test.sh
```

## Linting e auditoria

```sh
cargo audit
cargo deny check
```

## Arquitetura

### Estrutura de Módulos

```
rust/src/
├── lib.rs                     # Raiz da crate; re-exports
├── error.rs                   # Map2CheckError (thiserror)
├── state.rs                   # AnalysisState + OnceLock<Arc<Mutex<...>>>
├── ffi.rs                     # ÚNICO módulo com unsafe — extern "C" ABI
├── caller/mod.rs              # ViolatedProperty, AnalysisResult, step counter
├── nondet/
│   ├── mod.rs                 # NonDetValue (enum), NonDetEntry
│   └── libfuzzer.rs           # LLVMFuzzerTestOneInput (feature = "libfuzzer")
├── memtrack/mod.rs            # MemTrackEntry, VCC checks de memória
├── bbtrack/mod.rs             # BasicBlockEntry, busca por linha
├── analysismode/
│   ├── mod.rs                 # VccChecker trait, VccContext, VccOutcome
│   ├── assert.rs              # AssertChecker
│   ├── overflow.rs            # AddI32, SubI32, MulI32 ... (checked_* arithmetic)
│   └── memory.rs              # LoadChecker, FreeChecker, DerefChecker, MemCleanupChecker
└── output/mod.rs              # to_json(), print_json() via serde_json
```

### Conectividade com Map2Check

```
Map2Check Tool (LLVM Pass / Instrumentação)
        │
        │  extern "C" ABI  (ffi.rs)
        ▼
┌─────────────────────────────────────────────┐
│           libmap2check.a / .bc              │
│                                             │
│  caller ─┐                                 │
│  nondet  ├──► AnalysisState                │
│  memtrack│    OnceLock<Arc<Mutex<...>>>     │
│  bbtrack ┘                                 │
│                                             │
│  analysismode ──► VccChecker trait          │
│  output   ──► serde_json                   │
└─────────────────────────────────────────────┘
        │
        │  llvm-link-8
        ▼
libmap2check_klee.bc / libmap2check_libfuzzer.bc
```

### Decisões de Segurança

| Padrão C | Equivalente Rust |
|---|---|
| `TAILQ` globais sem lock | `OnceLock<Arc<Mutex<AnalysisState>>>` |
| `union Data` (type-punning) | `NonDetValue` enum com dados; `f32::from_bits()` |
| Buffer fixo `char[512]` sem bounds | `serde_json::to_string()` — tamanho dinâmico |
| `search_in_container_by_address` retorna ponteiro não-inicializado | `find_by_address` retorna `Option<&MemTrackEntry>` |
| Aritmética `INT_MAX/INT_MIN` manual | `i32::checked_add()`, `checked_sub()` etc. |
| `lib/json-maker.c` + `ftoa.c` | `serde_json` + `#[derive(Serialize)]` |

**Política de `unsafe`**: somente `ffi.rs` contém blocos `unsafe`. Todos os outros módulos têm `#![deny(unsafe_code)]`. Cada bloco unsafe em `ffi.rs` possui um comentário `// SAFETY:`.

## Output JSON

Ao final da análise, `print_all_containers_as_json()` emite no stdout:

```json
{
  "map2check_log": {
    "result": "true",
    "property": "NONE",
    "step": 42,
    "line": 0,
    "function_name": "",
    "Container_NonDetLog": [
      {
        "step": 1,
        "line": 10,
        "scope": 0,
        "function_name": "main",
        "value": { "type": "INT", "value": 7 }
      }
    ],
    "Container_TrackBBLog": [ ... ],
    "Container_AllocationLog": [ ... ]
  }
}
```

`Container_AllocationLog` só é incluído quando a violação é de segurança de memória (`MemsafetyFree`, `MemsafetyDeref`, `MemsafetyMemcleanup`).

## Map2Check flow com a biblioteca

<center>
<img src="./docs/imgs/map2check-flowchart.png">
</center>
