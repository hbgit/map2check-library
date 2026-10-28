/* SPDX-License-Identifier: GPL-3.0-only
 * Programa de fumaça da matriz de link (scripts/it/check-link-matrix.sh).
 * Seguro em todos os modos: aloca, escreve, soma, confere e libera, com um
 * nondet limitado. Usa malloc/free (memtrack, memcleanup), aritmética com
 * sinal (overflow) e reach_error (alcance). */
#include <stdlib.h>
extern void __assert_fail(const char *, const char *, unsigned int, const char *);
void reach_error(void) { __assert_fail("0", "link-smoke.c", 9, "reach_error"); }
extern int __VERIFIER_nondet_int(void);
/* Não se chama __VERIFIER_assert: AnalysisModeAssert.bc define esse nome e o
 * llvm-link do C falharia com "symbol multiply defined" no modo assert. */
static void check(int cond) {
  if (!cond) {
  ERROR: { reach_error(); abort(); }
  }
}
int main(void) {
  int n = __VERIFIER_nondet_int();
  if (n < 0 || n > 8)
    return 0;
  int *a = malloc(sizeof(int) * 9); /* tamanho fixo: KLEE concretiza tamanho simbólico */
  if (a == NULL)
    return 0;
  int s = 0;
  for (int i = 0; i <= n; i++) {
    a[i] = i;
    s += a[i];
  }
  check(s == n * (n + 1) / 2);
  free(a);
  return 0;
}
