/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Task 2.8: a stand-in for AFL++'s afl-compiler-rt that runs a fixed list of
 * inputs through the persistent loop of NonDetGeneratorAFL in ONE process,
 * the way afl-fuzz does in shared-memory persistent mode: every
 * __afl_persistent_loop call that returns 1 has put the next input at
 * __afl_fuzz_ptr / *__afl_fuzz_len. Linked natively with the C runtime and
 * with the drop-in runtime by scripts/runtime-ir/test-afl-generator.sh; the
 * real afl-compiler-rt runs only one input per process outside afl-fuzz.
 *
 * Environment:
 *   M2C_AFL_INPUTS  input files, separated by ':', run in that order;
 *   M2C_AFL_REPEAT  run the whole list this many times (default 1).
 * Each iteration that starts writes "iteration <n>" to stdout, the end of the
 * loop "loop done", and then "maxrss_kb <n>" (getrusage) to stderr.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>

/* The names the IR expansion of __AFL_FUZZ_INIT / __AFL_LOOP references. */
int __afl_connected = 1;
unsigned char *__afl_fuzz_ptr;
static unsigned int fuzz_len_storage;
unsigned int *__afl_fuzz_len = &fuzz_len_storage;

static unsigned char buffer[1 << 20];
static char **files;
static int nfiles, next, repeat = 1, round_no;
static unsigned long iteration;

static void load_list(void) {
  /* Unbuffered, so what the program printed survives its abort. */
  setvbuf(stdout, NULL, _IONBF, 0);
  const char *list = getenv("M2C_AFL_INPUTS");
  const char *r = getenv("M2C_AFL_REPEAT");
  if (r != NULL)
    repeat = atoi(r);
  if (list == NULL || *list == '\0')
    return;
  char *copy = strdup(list);
  int cap = 1;
  for (const char *p = list; *p != '\0'; p++)
    cap += *p == ':';
  files = calloc((size_t)cap, sizeof(char *));
  for (char *tok = strtok(copy, ":"); tok != NULL; tok = strtok(NULL, ":"))
    files[nfiles++] = tok;
}

int __afl_persistent_loop(unsigned int max_cnt) {
  (void)max_cnt;
  static int loaded;
  if (!loaded) {
    loaded = 1;
    load_list();
  }
  if (next == nfiles) {
    next = 0;
    round_no++;
  }
  if (nfiles == 0 || round_no >= repeat) {
    struct rusage ru;
    getrusage(RUSAGE_SELF, &ru);
    printf("loop done\n");
    fflush(stdout);
    fprintf(stderr, "maxrss_kb %ld\n", ru.ru_maxrss);
    return 0;
  }
  FILE *f = fopen(files[next], "rb");
  if (f == NULL) {
    perror(files[next]);
    exit(2);
  }
  size_t n = fread(buffer, 1, sizeof(buffer), f);
  fclose(f);
  next++;
  __afl_fuzz_ptr = buffer;
  fuzz_len_storage = (unsigned int)n;
  if (repeat == 1)
    printf("iteration %lu\n", ++iteration);
  fflush(stdout);
  return 1;
}
