#include <assert.h>
#include <stdlib.h>
//#include <math.h>

#include "../include/nondet/nondet_gen_libfuzzer.h"

int __map2check_main__() {
  

  unsigned int vuint = map2check_gen_data_fuzzer_unsigned();
  int a              = map2check_gen_data_fuzzer_bool();
  char c             = map2check_gen_data_fuzzer_char();
  int i              = map2check_gen_data_fuzzer_int32_t();
  unsigned long ul   = map2check_gen_data_fuzzer_ulong();
  float f            = map2check_gen_data_fuzzer_float();
  //double d           = map2check_gen_data_fuzzer_double();  
  // && fabs(d-3.9999999) < 0.00001

  if(vuint < 12 && a == 1 && c == '?' && i == 85 && f == 0.5f && ul == 17284){
    abort();
  } 

  return 0;
}