/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.7, klee_generator_driver_matches_c: drives the generator module
 * directly, as the instrumented program and WitnessGeneration.c would.
 * Typed nondet values are logged (NonDetLog) and nondet_generate_aux_witness_files
 * pins them and writes klee_log.csv (NonDetGeneratorKlee.c:33-62). Linked as
 * the program of the generator's main (__map2check_main__). */
#include <stddef.h>
void map2check_init(int);
void map2check_success(void);
void nondet_generate_aux_witness_files(void);
int map2check_non_det_int(void);
char map2check_non_det_char(void);
double map2check_non_det_double(void);
unsigned long long map2check_non_det_ulonglong(void);
void map2check_nondet_int(unsigned, unsigned, int, const char *);
void map2check_nondet_char(unsigned, unsigned, char, const char *);
void map2check_nondet_double(unsigned, unsigned, double, const char *);
void map2check_nondet_ulonglong(unsigned, unsigned, unsigned long long, const char *);
int __map2check_main__(int argc, char **argv) {
  (void)argc; (void)argv;
  map2check_init(0);
  int x = map2check_non_det_int();
  map2check_nondet_int(10, 0, x, "main");
  char c = map2check_non_det_char();
  map2check_nondet_char(11, 0, c, "main");
  double d = map2check_non_det_double();
  map2check_nondet_double(12, 0, d, "main");
  unsigned long long u = map2check_non_det_ulonglong();
  map2check_nondet_ulonglong(13, 0, u, "main");
  if (x == 42 && c == 'z' && u == 7)
    nondet_generate_aux_witness_files();
  map2check_success();
  return 0;
}
