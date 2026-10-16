#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "map2check.h"
#define __map2check_main__ __map2check_main__
/* Differential check (B1): the Rust library reading one value
 * of each type from the input. */



















int __map2check_main__(void) { int argc = 0; char **argv = NULL;
  (void)argc; (void)argv;
  printf("char %d\n", __VERIFIER_nondet_char());
  printf("int %d\n", __VERIFIER_nondet_int());
  printf("bool %d\n", __VERIFIER_nondet_bool() != 0);
  printf("short %d\n", __VERIFIER_nondet_short());
  printf("long %ld\n", __VERIFIER_nondet_long());
  printf("uchar %u\n", __VERIFIER_nondet_uchar());
  printf("ushort %u\n", __VERIFIER_nondet_ushort());
  printf("uint %u\n", __VERIFIER_nondet_uint());
  printf("unsigned %u\n", __VERIFIER_nondet_uint());
  printf("ulong %lu\n", __VERIFIER_nondet_ulong());
  printf("size_t %zu\n", __VERIFIER_nondet_size_t());
  printf("loff_t %lld\n", (long long)__VERIFIER_nondet_loff_t());
  printf("sector_t %lu\n", __VERIFIER_nondet_sector_t());
  double d = __VERIFIER_nondet_double();
  printf("double %016llx\n", *(unsigned long long *)&d);
  printf("pointer %p\n", __VERIFIER_nondet_pointer());
  char *s = __VERIFIER_nondet_pchar();
  printf("pchar %s\n", s ? s : "(null)");
  if (s) { unsigned n = 0; for (char *p = s; *p; p++) n = n * 31 + (unsigned char)*p; printf("pchar_hash %u len %zu\n", n, (size_t)(s ? __builtin_strlen(s) : 0)); }
  free(s);
  printf("int %d\n", __VERIFIER_nondet_int());
  return 0;
}
/* Feeds the file named on the command line to LLVMFuzzerTestOneInput once. */
int main(int argc, char **argv) {
  FILE *f = fopen(argv[1], "rb");
  static uint8_t buf[1 << 20];
  size_t n = fread(buf, 1, sizeof buf, f);
  fclose(f);
  return LLVMFuzzerTestOneInput(buf, n);
}
