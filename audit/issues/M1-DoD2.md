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
