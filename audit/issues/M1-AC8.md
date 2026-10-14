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
