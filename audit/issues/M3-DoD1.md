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
