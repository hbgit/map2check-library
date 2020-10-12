#include <assert.h>
#include <stdlib.h>

#include "../include/nondet/nondetlog.h"

extern void klee_assume(int);
extern void klee_make_symbolic(void *addr, size_t nbytes, const char *name);

#include <stdio.h>

int main(){
  
  int vuint;  
  klee_make_symbolic(&vuint, sizeof(vuint), "non_det_");
  //printf("%d \n", vuint);
  // BUG from KLEE, the vunit value is not int
  //const char * tmp = map2check_convert_int_to_string(vuint);
  non_det_log_t *obj = map2check_save_nondet_log_int(1, 12, 0, INT_ID, &vuint, "foo");

  if(vuint == 12){
    print_obj_as_json(*obj);
    assert(0);
  }

  return 0;
}