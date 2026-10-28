/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.7, klee_generator_driver_matches_c: 1025 logged rows, one above
 * MAP2CHECK_KLEE_LOG_MAX_ROWS: nondet_generate_aux_witness_files writes no
 * klee_log.csv (NonDetGeneratorKlee.c:57-62). */
void map2check_init(int);
void map2check_success(void);
void nondet_generate_aux_witness_files(void);
int map2check_non_det_int(void);
void map2check_nondet_int(unsigned, unsigned, int, const char *);
int __map2check_main__(int argc, char **argv) {
  (void)argc; (void)argv;
  map2check_init(0);
  for (int i = 0; i < 1025; i++)
    map2check_nondet_int(10, 0, i, "main");
  int x = map2check_non_det_int();
  if (x == 3)
    nondet_generate_aux_witness_files();
  map2check_success();
  return 0;
}
