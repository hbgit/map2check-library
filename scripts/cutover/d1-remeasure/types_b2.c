/* Differential check (B2): develop's NonDetGeneratorAFL.c reading one value
 * of each type from the test case on stdin. */
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
extern int map2check_non_det_int(void);
extern unsigned map2check_non_det_uint(void);
extern unsigned map2check_non_det_unsigned(void);
extern char map2check_non_det_char(void);
extern unsigned char map2check_non_det_uchar(void);
extern short map2check_non_det_short(void);
extern unsigned short map2check_non_det_ushort(void);
extern long map2check_non_det_long(void);
extern unsigned long map2check_non_det_ulong(void);
extern int map2check_non_det_bool(void);
extern size_t map2check_non_det_size_t(void);
extern loff_t map2check_non_det_loff_t(void);
extern unsigned long map2check_non_det_sector_t(void);
extern double map2check_non_det_double(void);
extern void *map2check_non_det_pointer(void);
extern char *map2check_non_det_pchar(void);
int __map2check_main__(int argc, char **argv) {
  (void)argc; (void)argv;
  printf("char %d\n", map2check_non_det_char());
  printf("int %d\n", map2check_non_det_int());
  printf("bool %d\n", map2check_non_det_bool() != 0);
  printf("short %d\n", map2check_non_det_short());
  printf("long %ld\n", map2check_non_det_long());
  printf("uchar %u\n", map2check_non_det_uchar());
  printf("ushort %u\n", map2check_non_det_ushort());
  printf("uint %u\n", map2check_non_det_uint());
  printf("unsigned %u\n", map2check_non_det_unsigned());
  printf("ulong %lu\n", map2check_non_det_ulong());
  printf("size_t %zu\n", map2check_non_det_size_t());
  printf("loff_t %lld\n", (long long)map2check_non_det_loff_t());
  printf("sector_t %lu\n", map2check_non_det_sector_t());
  double d = map2check_non_det_double();
  printf("double %016llx\n", *(unsigned long long *)&d);
  printf("pointer %p\n", map2check_non_det_pointer());
  char *s = map2check_non_det_pchar();
  printf("pchar %s\n", s ? s : "(null)");
  if (s) { unsigned n = 0; for (char *p = s; *p; p++) n = n * 31 + (unsigned char)*p; printf("pchar_hash %u len %zu\n", n, (size_t)(s ? __builtin_strlen(s) : 0)); }
  free(s);
  printf("int %d\n", map2check_non_det_int());
  return 0;
}
