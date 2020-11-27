#include <assert.h>
#include <stdlib.h>

#include "../include/nondet/nondet_gen_libfuzzer.h"

int __map2check_main__() {
  

  unsigned int vuint = map2check_gen_data_fuzzer_unsigned();

  int a = map2check_gen_data_fuzzer_bool();
  
  if(vuint < 12 && a == 1){
    abort();
  } 

  return 0;
}