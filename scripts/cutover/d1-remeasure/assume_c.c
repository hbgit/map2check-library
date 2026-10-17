/* B2 reference: assume.c as the Map2Check passes leave it for the C runtime
 * (main renamed, nondet and assume calls renamed, map2check_init(0)). The
 * C runtime's map2check_assume is nondet_assume (Map2CheckFunctions.c). */
#include <stdlib.h>
extern void map2check_init(int isSvComp);
extern void map2check_success(void);
extern int map2check_non_det_int(void);
extern void map2check_assume(int);
int __map2check_main__(int argc, char **argv) {
  (void)argc; (void)argv;
  map2check_init(0);
  int x = map2check_non_det_int();
  map2check_assume(x > 100);
  map2check_assume(x < 200);
  if (x == 150) abort();
  map2check_success();
  return 0;
}
