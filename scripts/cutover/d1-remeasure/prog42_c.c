/* B2 reference: prog42.c as the Map2Check passes would leave it for the C
 * runtime (main renamed, nondet call renamed to the generator symbol). */
#include <stdlib.h>
extern void map2check_init(int isSvComp);
extern void map2check_success(void);
extern int map2check_non_det_int(void);
int __map2check_main__(int argc, char **argv) {
  (void)argc; (void)argv;
  map2check_init(0);
  int x = map2check_non_det_int();
  if (x == 42) abort();
  map2check_success();
  return 0;
}
