Audit-ID: M3-AC1
Auditoria do plano Rust (`origin/feature/rust` @ `0f28571`, auditoria de 2026-10-14). Itens parcialmente implementados que esta issue cobre:

- **M1-AC7** (PARCIAL): header contém todos os exports, mas não existe passo de nm-diff no CI — evidência: evidence/missing_in_header.txt (só __map2check_main__, que é import); CI.yml sem nm
- **M3-E1** (PARCIAL): falta next_current_step da §1.2(a), sem justificativa documentada — evidência: evidence/missing_core.txt
- **M3-I2** (PARCIAL): exportado e testado, mas a escolha semântica vs. AnalysisModeMemtrack.c não está registrada — evidência: evidence/nm_all.txt; memtrack::tests::*free_resolved*; docs/api-deltas.md sem seção
- **M3-AC1** (PARCIAL): só next_current_step ausente, sem exceção documentada; diff nm não roda no CI — evidência: evidence/missing_core.txt; docs/api-deltas.md

Ver `audit/relatorio_auditoria.md` para os detalhes.
