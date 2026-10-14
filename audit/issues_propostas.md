# Issues propostas — auditoria do plano Rust

Repositório: `hbgit/map2check-library`. Nada foi criado ainda; o script `audit/create_issues.sh` só simula (dry-run) até receber `--apply`.

## Resumo

| ação | quantidade |
|---|---|
| Issues novas | 5 |
| Comentários em issues abertas (agrupam 14 itens PARCIAIS) | 6 |
| Itens PENDENTES já cobertos por issue aberta (sem ação) | 63 |
| Itens incorporados ao corpo de uma issue nova | 4 |
| Milestones a criar (§3.3) | 8 (não existe nenhum) |
| Labels a criar (plano) | 12 (não existe nenhuma) |

## Issues novas

| Audit-ID | título | milestone | labels | também cobre |
|---|---|---|---|---|
| M1-AC8 | `ci: run cargo-tarpaulin in CI and enforce coverage gate outside ffi*.rs` | M1 — Restaurar build, CI e higiene | area:ci,kind:test | M1-E1, M3-AC3, G-1 |
| M1-DoD2 | `ci: protect feature/rust and require green CI on PRs` | M1 — Restaurar build, CI e higiene | area:ci | M1-DoD1 |
| M1-I5 | `chore: remove C-era dead artifacts (.clangd, compile_commands.json, .travis.yml, .vscode, stale docs)` | M1 — Restaurar build, CI e higiene | kind:feature | — |
| M3-E3 | `test: add Rust unit tests for each exported FFI symbol` | M3 — Completar paridade da API núcleo | kind:test | — |
| M3-DoD1 | `build: version the C header and crate as v1.0.0-rc1` | M3 — Completar paridade da API núcleo | area:build | — |

### M1-AC8 — `ci: run cargo-tarpaulin in CI and enforce coverage gate outside ffi*.rs`

Audit-ID: M1-AC8
Status na auditoria: PENDENTE (`origin/feature/rust` @ `0f28571`, auditoria de 2026-10-14)

## Trecho do plano
> M1 — Entregáveis: "`.github/workflows/ci.yml` (build+test+clippy+fmt+deny+tarpaulin)"
> M1 — Critério: "cobertura tarpaulin ≥ 70% fora de `ffi.rs`"
> M3 — Critério: "cobertura ≥ 75%"
> §3.4 (1): "CI da biblioteca verde (build, testes, lints, deny/audit, cobertura ≥ 80% fora de `ffi*.rs`) com toolchain fixado."

## O que falta (evidência)
- **M1-AC8** (PENDENTE): cobertura medida 52,1% fora de ffi.rs (< 70%) e sem gate — evidência: evidence/coverage.txt (151/290 linhas)
- **M1-E1** (PARCIAL): CI.yml tem build/test/clippy/fmt/deny/audit mas não tarpaulin; cobertura só roda no estágio Docker com falha mascarada — evidência: CI.yml:24-109; Dockerfile:34-39 (`|| mkdir -p /coverage`)
- **M3-AC3** (PENDENTE): cobertura 52,1% (< 75%) — evidência: evidence/coverage.txt
- **G-1** (PENDENTE): CI verde e toolchain fixado, mas cobertura 52,1% < 80% e sem gate — evidência: evidence/coverage.txt; run 38490671308
- Cobertura medida no estágio `test` do Dockerfile: **151/290 linhas = 52,1%** (`audit/evidence/coverage.txt`). Piores módulos: `analysismode/memory.rs` 6/42, `nondet/libfuzzer.rs` 20/85.
- O `cargo tarpaulin` só roda dentro do `docker build` e termina em `|| mkdir -p /coverage` (Dockerfile:34-39), então uma falha nunca quebra o CI; não há relatório publicado nem limiar.

## Critério de aceitação
- [ ] Step de tarpaulin no `CI.yml` (excluindo `rust/src/ffi*.rs`) que publica o relatório (lcov) como artefato.
- [ ] Gate com `--fail-under 70` agora, subindo para 75 (fim de M3) e 80 (critério global §3.4-1).
- [ ] Remover o `|| mkdir -p /coverage` do Dockerfile ou torná-lo explícito/documentado.

## Dependências
- Nenhuma (M1). Os testes que elevam a cobertura podem vir de M3 (ver issue de testes por export).

## Também cobre
- M1-E1
- M3-AC3
- G-1

Fonte: `docs/plano_map2check_library_rust.md`; relatório: `audit/relatorio_auditoria.md`.

### M1-DoD2 — `ci: protect feature/rust and require green CI on PRs`

Audit-ID: M1-DoD2
Status na auditoria: PENDENTE (`origin/feature/rust` @ `0f28571`, auditoria de 2026-10-14)

## Trecho do plano
> M1 — DoD: "CI verde obrigatório em PR; branch protegida."

## O que falta (evidência)
- **M1-DoD2** (PENDENTE): feature/rust sem proteção (HTTP 404); só master é protegida — evidência: evidence/protection.txt
- **M1-DoD1** (PENDENTE): feature/rust não protegida; master sem required_status_checks — evidência: evidence/protection.txt; gh api .../master/protection → checks:null
- `gh api repos/hbgit/map2check-library/branches/feature/rust/protection` → HTTP 404 "Branch not protected".
- `master` é protegida (1 review, assinaturas obrigatórias), mas `required_status_checks` é `null`: o CI não é obrigatório nem lá.

## Critério de aceitação
- [ ] `feature/rust` protegida com required status check `build_and_test` (workflow "CI Map2Check Rust").
- [ ] O mesmo check exigido em `master`.
- [ ] Assinatura de commits exigida em `feature/rust`, como já ocorre em `master`.

## Dependências
- Nenhuma.

## Também cobre
- M1-DoD1

Fonte: `docs/plano_map2check_library_rust.md`; relatório: `audit/relatorio_auditoria.md`.

### M1-I5 — `chore: remove C-era dead artifacts (.clangd, compile_commands.json, .travis.yml, .vscode, stale docs)`

Audit-ID: M1-I5
Status na auditoria: PARCIAL (`origin/feature/rust` @ `0f28571`, auditoria de 2026-10-14)

## Trecho do plano
> M1 — Issue 5: "`chore: remove C-era dead artifacts (.clangd, compile_commands.json, .travis.yml, .vscode, stale docs)`"

## O que falta (evidência)
- **M1-I5** (PARCIAL): artefatos removidos, mas docs C-era (Doxyfile, UML .xmi) continuam — evidência: git ls-files docs/: Doxyfile, "C map2checklibrary.xmi", map2checklibrary.xmi
- `.clangd`, `compile_commands.json`, `.travis.yml` e `.vscode` já não estão rastreados em `feature/rust`.
- Continuam em `docs/` artefatos da era C: `Doxyfile`, `C map2checklibrary.xmi` e `map2checklibrary.xmi` (UML da implementação C).

## Critério de aceitação
- [ ] Remover os artefatos C de `docs/`, ou movê-los para um diretório `docs/legacy-c/` com uma nota explicando por que permanecem.
- [ ] `git ls-files` não lista nenhum artefato de build/IDE da era C.

## Dependências
- Nenhuma.

Fonte: `docs/plano_map2check_library_rust.md`; relatório: `audit/relatorio_auditoria.md`.

### M3-E3 — `test: add Rust unit tests for each exported FFI symbol`

Audit-ID: M3-E3
Status na auditoria: PARCIAL (`origin/feature/rust` @ `0f28571`, auditoria de 2026-10-14)

## Trecho do plano
> M3 — Entregáveis: "`ffi.rs` completo; header regenerado; testes unitários por símbolo; `test/*.c` migrados para a API vigente e compilados no CI."

## O que falta (evidência)
- **M3-E3** (PARCIAL): testes unitários cobrem módulos internos, não cada export; os exports só são exercitados pelo harness C — evidência: evidence/test_names.txt (52 testes)
- Os 52 testes Rust (`audit/evidence/test_names.txt`) cobrem módulos internos (`memtrack`, `analysismode`, `nondet`, `output`, `state`), mas não há teste Rust por export de `ffi.rs` (46 exports). Os exports só são exercitados pelo harness C `tests/ffi_harness.c`.
- `rust/src/ffi.rs` está fora da medição de cobertura (Dockerfile:39), então essa lacuna não aparece em nenhum número.

## Critério de aceitação
- [ ] Para cada símbolo de `include/map2check.h`, ao menos um teste Rust (`#[cfg(test)]` em `ffi.rs` ou `tests/`) que chama o export e verifica o efeito no estado.
- [ ] Uma lista de verificação (script ou teste) falha quando um export novo não tem teste.

## Dependências
- M2 (`map2check_reset` para isolar os testes).

Fonte: `docs/plano_map2check_library_rust.md`; relatório: `audit/relatorio_auditoria.md`.

### M3-DoD1 — `build: version the C header and crate as v1.0.0-rc1`

Audit-ID: M3-DoD1
Status na auditoria: PENDENTE (`origin/feature/rust` @ `0f28571`, auditoria de 2026-10-14)

## Trecho do plano
> M3 — DoD: "header versionado `v1.0.0-rc1`; nenhuma função stub silenciosa restante."

## O que falta (evidência)
- **M3-DoD1** (PENDENTE): nenhum v1.0.0-rc1 em header, Cargo ou tags — evidência: Cargo.toml:4 (1.0.0); evidence/tags.txt
- `Cargo.toml:4` traz `version = "1.0.0"`; o header gerado não contém versão; não há tags nem releases no repositório (`audit/evidence/tags.txt`, `releases.txt`).

## Critério de aceitação
- [ ] Versão do crate `1.0.0-rc1` e a mesma versão exposta no header gerado (ex.: `#define MAP2CHECK_VERSION "1.0.0-rc1"` emitido pelo `build.rs`/cbindgen).
- [ ] Tag `v1.0.0-rc1` criada no commit que fecha M3.

## Dependências
- M3 completo (ver comentário em #13 sobre `next_current_step`).

Fonte: `docs/plano_map2check_library_rust.md`; relatório: `audit/relatorio_auditoria.md`.

## Comentários em issues abertas (itens PARCIAIS)

### Comentário em #8 (itens M2-E3, M2-I6, M2-AC1, G-6)

Audit-ID: M2-I6
Auditoria do plano Rust (`origin/feature/rust` @ `0f28571`, auditoria de 2026-10-14). Itens parcialmente implementados que esta issue cobre:

- **M2-E3** (PARCIAL): harness hostil existe, mas não chama __VERIFIER_error e o CI tenta 5× para mascarar um SIGSEGV intermitente — evidência: tests/ffi_harness.c; CI.yml:36-60
- **M2-I6** (PARCIAL): harness ASan+UBSan no CI, mas com retry 5× e sem __VERIFIER_error — evidência: CI.yml:50-60; tests/ffi_harness.c
- **M2-AC1** (PARCIAL): harness retorna 0 no CI só após até 5 tentativas; o critério exige 100% dos exports e execução limpa — evidência: CI.yml:36-60; run 38490671308
- **G-6** (PARCIAL): harness hostil roda sob ASan/UBSan, mas com retry que mascara SIGSEGV intermitente — evidência: M2-AC1; CI.yml:36-60

Ver `audit/relatorio_auditoria.md` para os detalhes.

### Comentário em #9 (itens M2-AC2)

Audit-ID: M2-AC2
Auditoria do plano Rust (`origin/feature/rust` @ `0f28571`, auditoria de 2026-10-14). Itens parcialmente implementados que esta issue cobre:

- **M2-AC2** (PARCIAL): duas iterações executadas, mas só rc==0 é verificado; containers não são comparados — evidência: tests/ffi_harness.c:266-273; test/codefuzz_by_caller_test.c:44-53

Ver `audit/relatorio_auditoria.md` para os detalhes.

### Comentário em #11 (itens M6-I2)

Audit-ID: M6-I2
Auditoria do plano Rust (`origin/feature/rust` @ `0f28571`, auditoria de 2026-10-14). Itens parcialmente implementados que esta issue cobre:

- **M6-I2** (PARCIAL): is_invalid_address foi reescrito e testado, mas a adjudicação vs. container_memtracklog.c não foi documentada — evidência: memtrack/mod.rs:102; memtrack::tests::invalid_address_*; sem docs/semantic-deltas.md

Ver `audit/relatorio_auditoria.md` para os detalhes.

### Comentário em #13 (itens M1-AC7, M3-E1, M3-I2, M3-AC1)

Audit-ID: M3-AC1
Auditoria do plano Rust (`origin/feature/rust` @ `0f28571`, auditoria de 2026-10-14). Itens parcialmente implementados que esta issue cobre:

- **M1-AC7** (PARCIAL): header contém todos os exports, mas não existe passo de nm-diff no CI — evidência: evidence/missing_in_header.txt (só __map2check_main__, que é import); CI.yml sem nm
- **M3-E1** (PARCIAL): falta next_current_step da §1.2(a), sem justificativa documentada — evidência: evidence/missing_core.txt
- **M3-I2** (PARCIAL): exportado e testado, mas a escolha semântica vs. AnalysisModeMemtrack.c não está registrada — evidência: evidence/nm_all.txt; memtrack::tests::*free_resolved*; docs/api-deltas.md sem seção
- **M3-AC1** (PARCIAL): só next_current_step ausente, sem exceção documentada; diff nm não roda no CI — evidência: evidence/missing_core.txt; docs/api-deltas.md

Ver `audit/relatorio_auditoria.md` para os detalhes.

### Comentário em #15 (itens M6-I3)

Audit-ID: M6-I3
Auditoria do plano Rust (`origin/feature/rust` @ `0f28571`, auditoria de 2026-10-14). Itens parcialmente implementados que esta issue cobre:

- **M6-I3** (PARCIAL): is_deref_error passou a considerar points_to (teste), mas a adjudicação não foi documentada e has_memcleanup_error não foi revisado — evidência: memtrack/mod.rs:124-138; memtrack::tests::deref_resolves_allocation_through_stored_pointer

Ver `audit/relatorio_auditoria.md` para os detalhes.

### Comentário em #16 (itens M1-E5, M1-I4, M1-I6)

Audit-ID: M1-I4
Auditoria do plano Rust (`origin/feature/rust` @ `0f28571`, auditoria de 2026-10-14). Itens parcialmente implementados que esta issue cobre:

- **M1-E5** (PARCIAL): header commitado, mas não há release nem upload de artefato — evidência: include/map2check.h; evidence/releases.txt vazio; sem upload-artifact em CI.yml
- **M1-I4** (PARCIAL): build.rs gera o header, mas o CI não publica o header como artefato — evidência: build.rs:17-22; CI.yml sem upload-artifact
- **M1-I6** (PARCIAL): CI roda só --all-features; não há matriz default × libfuzzer para `cargo test` — evidência: CI.yml:33-34 (sem `matrix:`); local evidence/test_default.log e test_libfuzzer.log rc=0

Ver `audit/relatorio_auditoria.md` para os detalhes.

## Itens PENDENTES já cobertos por issues abertas (sem ação nova)

| issue | itens |
|---|---|
| #5 | M2-DoD2, M6-E2, M6-DoD1, M7-E3, M7-I4, M8-DoD3, G-7 |
| #15 | M6-E1, M6-I1, M6-AC1, G-3 |
| #17 | M4-I4 |
| #18 | M6-E3, M6-I4, M6-I5, M6-AC2, M6-AC3, M7-AC3, G-5 |
| #19 | M5-E2, M5-I4, M5-I5, M5-AC2 |
| #20 | M4-E1, M4-E2, M4-E3, M4-E4, M4-I1, M4-I2, M4-I3, M4-I5, M4-AC1, M4-AC2, M4-DoD1 |
| #21 | M5-E1, M5-E3, M5-I1, M5-I2, M5-I3, M5-AC1, M5-DoD1, M5-DoD2, G-2 |
| #22 | M7-E1, M7-E2, M7-I1, M7-I2, M7-I3, M7-AC1, M7-AC2, M7-DoD1, M7-DoD2, G-4 |
| #23 | M8-I2, M8-I3, M8-I4, M8-I5, M8-I6, M8-AC2 |
| #24 | M8-I1, M8-AC1, M8-DoD1, M8-DoD2 |

## Fora do escopo do pedido (sugestões, não incluídas no script)

- As issues #5–#24 não têm milestone nem labels. Depois de criar os milestones e as labels, podem ser atribuídos com `gh issue edit <n> -m "<milestone>" --add-label ...`.
- Pela evidência, #6, #7, #10 e #12 parecem cumpridas em `feature/rust` (M3-I4, M3-I6, M3-I3, `docs/api-deltas.md`), e #9 e #16 estão quase. Vale revisar e fechar manualmente.
- Os títulos das issues existentes não seguem o padrão `area: descrição` do plano.
