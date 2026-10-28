/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.8, SD-20 scope (user decision of 2026-10-27): which way the
 * runtime writes map2check_property. write_property writes it, a descriptor
 * is held open on that file, and write_property writes it again:
 *   - written in place (develop's fopen("w"): truncate + write), the held
 *     descriptor reads the new text, "NONE";
 *   - written to a temporary file renamed over the target (SD-20), the held
 *     descriptor still reads the old file, "TARGET-REACHED...".
 * The verdict goes to the file write-mode ("plain" or "atomic"). No
 * symbolic value: one KLEE path. Linked by test-klee-generator.sh (symex:
 * the drop-in must be atomic) and test-afl-generator.sh (afl: plain, as the
 * C). */
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

void map2check_init(int);
void write_property(int violated, int line, const char *function_name);

int __map2check_main__(void) {
  map2check_init(0);
  write_property(5 /* TARGET_REACHED */, 10, "first");
  int fd = open("map2check_property", O_RDONLY);
  write_property(0 /* NONE */, 0, "");
  char buf[16] = {0};
  const char *mode = "unknown";
  if (fd >= 0 && read(fd, buf, 4) == 4)
    mode = memcmp(buf, "NONE", 4) == 0 ? "plain" : "atomic";
  int out = open("write-mode", O_WRONLY | O_CREAT | O_TRUNC, 0644);
  if (out >= 0) {
    (void)!write(out, mode, strlen(mode));
    close(out);
  }
  return 0;
}
