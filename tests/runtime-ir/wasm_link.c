/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Link test of the generated WasmRuntimeStubs.ll (Task 2.9, D7 A-fwd): built
 * from the .ll and target/release/libmap2check.a, it calls the C names that
 * only the IR defines, as the wasm2c output does. Each must reach its
 * __m2c_rt_wasm_* entry point in the Rust core and behave as
 * WasmRuntimeStubs.c of Map2Check develop (the line cited per check).
 * Run by scripts/runtime-ir/test-wasm-link.sh, one scenario per process
 * (argv[1]); a scenario exits 0 when every check holds, or with the number of
 * the failing check. The trap scenarios are checked by the script (abort
 * status and the files written).
 *
 * wasm_rt_memory_t and wasm_rt_funcref_table_t are the wabt 1.0.41 layouts
 * (wasm-rt.h:437-529); rust/src/wasm.rs checks the Rust mirror against the
 * real header.
 */
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef struct {
  uint8_t *data;
  uint8_t *data_end;
  uint32_t page_size;
  uint64_t pages, max_pages;
  uint64_t size;
  bool is64;
} wasm_rt_memory_t;

typedef struct {
  const char *func_type;
  void (*func)(void);
  void *func_tailcallee;
  void *module_instance;
} wasm_rt_funcref_t;

typedef struct {
  wasm_rt_funcref_t *data;
  uint32_t max_size;
  uint32_t size;
} wasm_rt_funcref_table_t;

/* WasmRuntimeStubs.c. */
void wasm_rt_allocate_memory(wasm_rt_memory_t *mem, uint64_t initial_pages, uint64_t max_pages,
                             bool is64, uint32_t page_size);
uint64_t wasm_rt_grow_memory(wasm_rt_memory_t *mem, uint64_t pages);
void wasm_rt_free_memory(wasm_rt_memory_t *mem);
void wasm_rt_allocate_funcref_table(wasm_rt_funcref_table_t *table, uint32_t elements,
                                    uint32_t max_elements);
void wasm_rt_free_funcref_table(wasm_rt_funcref_table_t *table);
void w2c_wasi__snapshot__preview1_proc_exit(void *instance, uint32_t code);
bool wasm_rt_is_initialized(void);
void wasm_rt_init(void);
void wasm_rt_free(void);
void wasm_rt_trap(int code);
/* Rust core. */
void map2check_init(int);
void __m2c_rt_memtrack_analysis_init(void);

int __map2check_main__(void) { return 0; }

#define CHECK(n, cond) \
  do {                 \
    if (!(cond)) {     \
      fprintf(stderr, "check %d failed: %s\n", (n), #cond); \
      return (n);      \
    }                  \
  } while (0)

int main(int argc, char **argv) {
  const char *c = argc > 1 ? argv[1] : "";
  const uint64_t fail = UINT32_MAX;
  if (!strcmp(c, "memory")) {
    wasm_rt_memory_t m;
    memset(&m, 0, sizeof m);
    m.is64 = true;
    /* :22-35 calloc(1, page_size * initial_pages), every field but is64 set. */
    wasm_rt_allocate_memory(&m, 2, 5, false, 65536);
    CHECK(1, m.data != NULL);
    CHECK(2, m.size == 2 * 65536 && m.pages == 2 && m.max_pages == 5 && m.page_size == 65536);
    CHECK(3, m.data_end == m.data + m.size);
    CHECK(4, m.is64 == true); /* :34 is commented out */
    for (uint64_t i = 0; i < m.size; i++) CHECK(5, m.data[i] == 0);
    /* :66-70 */
    wasm_rt_free_memory(&m);
    CHECK(6, m.data == NULL && m.size == 0 && m.pages == 2 && m.max_pages == 5);
  } else if (!strcmp(c, "grow")) {
    wasm_rt_memory_t m;
    memset(&m, 0, sizeof m);
    wasm_rt_allocate_memory(&m, 1, 3, false, 65536);
    m.data[0] = 0xAA;
    CHECK(1, wasm_rt_grow_memory(&m, 0) == 1);          /* :47-49 */
    CHECK(2, wasm_rt_grow_memory(&m, 1) == 1);          /* :62 */
    CHECK(3, m.pages == 2 && m.size == 2 * 65536 && m.data_end == m.data + m.size);
    CHECK(4, m.data[0] == 0xAA && m.data[65536] == 0 && m.data[2 * 65536 - 1] == 0); /* :53-57 */
    CHECK(5, wasm_rt_grow_memory(&m, 2) == fail);       /* :44-46 past max_pages */
    CHECK(6, wasm_rt_grow_memory(&m, UINT64_MAX) == fail); /* :44 wrap */
    CHECK(7, m.pages == 2);
    m.page_size = 0;
    CHECK(8, wasm_rt_grow_memory(&m, 1) == 2 && m.size == 3 * 65536); /* :50 */
    wasm_rt_free_memory(&m);
  } else if (!strcmp(c, "table")) {
    wasm_rt_funcref_table_t t;
    memset(&t, 0, sizeof t);
    /* :73-78; max_size is not written. The element size is SD-19. */
    wasm_rt_allocate_funcref_table(&t, 4, 10);
    CHECK(1, t.data != NULL && t.size == 4 && t.max_size == 0);
    CHECK(2, t.data[3].module_instance == NULL && t.data[3].func == NULL);
    wasm_rt_free_funcref_table(&t); /* :81-84 */
    CHECK(3, t.data == NULL && t.size == 4);
  } else if (!strcmp(c, "init")) {
    /* :96-108: initialised from the start. */
    CHECK(1, wasm_rt_is_initialized() == true);
    wasm_rt_free();
    wasm_rt_free();
    CHECK(2, wasm_rt_is_initialized() == false);
    wasm_rt_init();
    wasm_rt_init();
    CHECK(3, wasm_rt_is_initialized() == true);
  } else if (!strcmp(c, "proc_exit")) {
    /* :90-93: does nothing, returns. */
    int x = 0;
    w2c_wasi__snapshot__preview1_proc_exit(NULL, 0);
    w2c_wasi__snapshot__preview1_proc_exit(&x, 7);
    CHECK(1, x == 0);
  } else if (!strcmp(c, "trap")) {
    /* :110-116: map2check_error() aborts. */
    wasm_rt_trap(0);
    return 99; /* not reached */
  } else if (!strcmp(c, "trap-mode")) {
    map2check_init(0);
    __m2c_rt_memtrack_analysis_init(); /* memtrack: the first violation writes the files */
    wasm_rt_trap(3);
    return 99;
  } else {
    fprintf(stderr, "unknown scenario '%s'\n", c);
    return 2;
  }
  return 0;
}
