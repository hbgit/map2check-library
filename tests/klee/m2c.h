/* SPDX-License-Identifier: GPL-3.0-only
 *
 * The calls the Map2Check passes put into an analysed program, in two
 * dialects: the Rust runtime's (default) and develop's C runtime's
 * (-DM2C_DEVELOP), so tests/klee_paths.sh runs one program against both and
 * compares the KLEE paths. `main` is already renamed to __map2check_main__,
 * as the Map2CheckLibrary pass does; the runtime supplies `main`.
 *
 * Mode values: Rust `AnalysisMode` (rust/src/analysismode/mode.rs). */
#ifndef M2C_TEST_H
#define M2C_TEST_H

#include <stddef.h>

#define M2C_MODE_MEMTRACK 1
#define M2C_MODE_TARGET 5

#ifdef M2C_DEVELOP
/* develop: Map2CheckFunctions.h, NonDetGenerator.h, NonDetLog.c,
 * AnalysisModeMemtrack.c */
void map2check_init(int isSvComp);
void map2check_success(void);
void map2check_target_function(const char *func_name, int scope, int line);
void map2check_malloc(void *ptr, int size);
void map2check_load(void *ptr, int size);
void map2check_check_deref(int line, const char *function_name);
void map2check_add_store_pointer(void *var, void *value, unsigned scope,
                                 const char *name, int line,
                                 const char *function_name);
void map2check_free(const char *name, void *ptr, unsigned scope, unsigned line,
                    const char *function_name);
#define M2C_DECL(t, ct)                                                       \
  ct map2check_non_det_##t(void);                                             \
  void map2check_nondet_##t(unsigned line, unsigned scope, int value,         \
                            const char *function_name);
M2C_DECL(int, int)
M2C_DECL(char, char)
M2C_DECL(short, short)
M2C_DECL(ushort, unsigned short)
M2C_DECL(uchar, unsigned char)
M2C_DECL(long, long)
M2C_DECL(ulong, unsigned long)
M2C_DECL(uint, unsigned)
M2C_DECL(bool, int)
#define M2C_START(mode) map2check_init(0)
/* NonDetPass: the call is renamed to map2check_non_det_<t>, and its value,
 * cast to int, is logged with map2check_nondet_<t> right after. */
#define NONDET(t, ct, line)                                                   \
  ({                                                                          \
    ct v_ = map2check_non_det_##t();                                          \
    map2check_nondet_##t(line, 0, (int)v_, "main");                           \
    v_;                                                                       \
  })
#define REACH_ERROR(line) map2check_target_function("reach_error", 0, line)
#define TRACK_MALLOC(var, size, line)                                         \
  do {                                                                        \
    map2check_malloc((var), (size));                                          \
    map2check_add_store_pointer(&(var), (var), 0, #var, line, "main");        \
  } while (0)
#define CHECK_LOAD(addr, size, line)                                          \
  do {                                                                        \
    map2check_load((void *)(addr), (size));                                   \
    map2check_check_deref(line, "main");                                      \
  } while (0)
#define TRACK_FREE(var, line) map2check_free(#var, &(var), 0, line, "main")
#else
/* Rust runtime: include/map2check.h and docs/cutover/symbol-matrix.tsv */
void map2check_set_mode(int mode);
void map2check_enable_witness(void);
void map2check_init(void);
void map2check_success(void);
void map2check_reach_target(const char *func, int scope, int line);
void map2check_map_malloc(const void *ptr_address, int size);
void map2check_map_store_pointer(const void *var_address, const void *value,
                                 unsigned scope, const char *var_name,
                                 int line_number, const char *funct_name);
void map2check_check_load(const void *ptr, int line, unsigned scope, int size,
                          const char *function_name);
void map2check_check_free(const char *name, const void *var_address,
                          const void *ptr, unsigned scope, unsigned line,
                          const char *function_name);
void map2check_map_free(const char *var_name, const void *var_address,
                        const void *ptr_address, unsigned scope,
                        unsigned line_number, const char *function_name);
#define M2C_DECL(t, ct)                                                       \
  ct __VERIFIER_nondet_##t(void);                                             \
  void *map2check_save_nondet_log_##t(int line, int scope, int type_var,      \
                                      ct *value, const char *function_name);
M2C_DECL(int, int)
M2C_DECL(char, char)
M2C_DECL(short, short)
M2C_DECL(ushort, unsigned short)
M2C_DECL(uchar, unsigned char)
M2C_DECL(long, long)
M2C_DECL(ulong, unsigned long)
M2C_DECL(uint, unsigned)
_Bool __VERIFIER_nondet_bool(void);
void *map2check_save_nondet_log_bool(int line, int scope, int type_var,
                                     int *value, const char *function_name);
#define M2C_START(mode)                                                       \
  do {                                                                        \
    map2check_set_mode(mode);                                                 \
    map2check_enable_witness();                                               \
    map2check_init();                                                         \
  } while (0)
#define NONDET(t, ct, line)                                                   \
  ({                                                                          \
    ct v_ = __VERIFIER_nondet_##t();                                          \
    map2check_save_nondet_log_##t(line, 0, 0, &v_, "main");                  \
    v_;                                                                       \
  })
#define REACH_ERROR(line) map2check_reach_target("reach_error", 0, line)
#define TRACK_MALLOC(var, size, line)                                         \
  do {                                                                        \
    map2check_map_malloc((var), (size));                                      \
    map2check_map_store_pointer(&(var), (var), 0, #var, line, "main");        \
  } while (0)
#define CHECK_LOAD(addr, size, line)                                          \
  map2check_check_load((const void *)(addr), line, 0, (size), "main")
#define TRACK_FREE(var, line)                                                 \
  do {                                                                        \
    map2check_check_free(#var, &(var), (var), 0, line, "main");               \
    map2check_map_free(#var, &(var), (var), 0, line, "main");                 \
  } while (0)
#endif

#endif
