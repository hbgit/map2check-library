Audit-ID: M2-AC2
Auditoria do plano Rust (`origin/feature/rust` @ `0f28571`, auditoria de 2026-10-14). Itens parcialmente implementados que esta issue cobre:

- **M2-AC2** (PARCIAL): duas iterações executadas, mas só rc==0 é verificado; containers não são comparados — evidência: tests/ffi_harness.c:266-273; test/codefuzz_by_caller_test.c:44-53

Ver `audit/relatorio_auditoria.md` para os detalhes.
