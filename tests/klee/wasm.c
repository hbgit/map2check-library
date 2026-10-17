/* SPDX-License-Identifier: GPL-3.0-only
 * The --wasm mode of Map2Check: wasm.wat lifted by wasm2c (tests/klee_paths.sh
 * generates t.h/t.c), driven like the wrapper of caller.cpp
 * generateWasmWrapperStatic (wasm_rt_init, instantiate, _start, free). The
 * runtime must supply the wasm_rt_* stubs (KLEE: "failed external call:
 * wasm_rt_is_initialized" without them) and the map2check_wasm_* checks.
 * Expected: the write one int past the 40-byte block is OVERFLOW at line 0
 * (SD-19), found by KLEE as an abort, in both runtimes. */
#include <stdint.h>
#include <stdlib.h>
#include "m2c.h"
#include "t.h"

void map2check_wasm_malloc(uint64_t offset, uint64_t size);
void map2check_wasm_check_access(uint64_t offset, uint64_t access_size);

/* The two calls MemoryTrackPass -wasm-mode inserts, as the module's imports. */
void w2c_env_track(struct w2c_env *env, u64 offset, u64 size) {
  (void)env;
  map2check_wasm_malloc(offset, size);
}
void w2c_env_check(struct w2c_env *env, u64 offset, u64 size) {
  (void)env;
  map2check_wasm_check_access(offset, size);
}

int __map2check_main__(void) {
  M2C_START(M2C_MODE_MEMTRACK);
  w2c_t instance;
  wasm_rt_init();
  wasm2c_t_instantiate(&instance, NULL);
  w2c_t_0x5Fstart(&instance);
  wasm2c_t_free(&instance);
  wasm_rt_free();
  map2check_success();
  return 0;
}
