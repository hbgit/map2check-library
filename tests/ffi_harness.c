#include <stdint.h>
#include <stddef.h>

extern void map2check_init(void);
extern void map2check_reset(void);
extern void map2check_success(void);

extern void map2check_map_alloca(const char *var_name,
                                 const void *ptr_address,
                                 int size,
                                 int size_primitive,
                                 int line_number,
                                 int scope);

extern void map2check_map_malloc(const void *ptr_address, int size);
extern void map2check_map_calloc(const void *ptr_address, int quantity, int size);
extern void map2check_map_free(const char *var_name,
                              const void *ptr_address,
                              unsigned int scope,
                              unsigned int line_number,
                              const char *function_name);

extern void map2check_map_store_pointer(const void *var_address,
                                        const void *value,
                                        unsigned int scope,
                                        const char *var_name,
                                        int line_number,
                                        const char *funct_name);

extern void map2check_check_load(const void *ptr,
                                 int line,
                                 unsigned int scope,
                                 int size,
                                 const char *function_name);

extern void map2check_check_free(const char *name,
                                 const void *ptr,
                                 unsigned int scope,
                                 unsigned int line,
                                 const char *function_name);

extern void map2check_check_deref(const void *ptr,
                                  unsigned int scope,
                                  unsigned int line,
                                  const char *function_name);

extern void map2check_is_valid_assert(int line_number,
                                      const char *function_name,
                                      int expression);

extern void map2check_binop_add_int(int lhs,
                                    int rhs,
                                    unsigned int line,
                                    unsigned int scope,
                                    const char *function_name);

extern void map2check_binop_neg_int(int value,
                                    unsigned int line,
                                    unsigned int scope,
                                    const char *function_name);

extern int __VERIFIER_nondet_int(void);
extern unsigned int __VERIFIER_nondet_uint(void);
extern int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size);

int __map2check_main__(void) {
    return 0;
}

static void run_bad_inputs(void) {
    /* chamadas antes do init() */
    map2check_check_load(NULL, 1, 0, 8, NULL);
    map2check_check_deref(NULL, 0, 2, NULL);
    map2check_check_free(NULL, NULL, 0, 3, NULL);

    /* strings vazias e nulas */
    map2check_map_alloca(NULL, NULL, 4, 4, 4, 1);
    map2check_map_alloca("", NULL, 4, 4, 5, 1);
    map2check_map_store_pointer(NULL, NULL, 0, NULL, 6, NULL);
    map2check_map_free(NULL, NULL, 0, 7, NULL);

    /* assert e overflow com entradas hostis */
    map2check_is_valid_assert(10, NULL, 0);
    map2check_binop_add_int(2147483647, 1, 10, 0, NULL);
    map2check_binop_neg_int(-2147483648, 11, 0, NULL);

    /* geradores nondet */
    (void)__VERIFIER_nondet_int();
    (void)__VERIFIER_nondet_uint();
}

int main(void) {
    /* rodada 1: entradas adversas antes do init */
    run_bad_inputs();

    /* rodada 2: uso válido após init */
    map2check_init();
    map2check_map_malloc(NULL, 16);
    map2check_map_calloc(NULL, 4, 8);
    map2check_map_alloca("buf", NULL, 8, 8, 20, 1);
    map2check_map_store_pointer((void *)0x1, (void *)0x2, 1, "buf", 21, "main");
    map2check_map_free("buf", (void *)0x1, 1, 22, "main");

    /* reset explícito entre execuções */
    map2check_reset();

    /* rodada 3: segunda rodada hostil */
    run_bad_inputs();

    /* duas iteracoes consecutivas devem iniciar com estado independente */
    {
        const uint8_t first_input[] = {0x01, 0x02, 0x03, 0x04};
        const uint8_t second_input[] = {0xa0, 0xb0};
        if (LLVMFuzzerTestOneInput(first_input, sizeof(first_input)) != 0 ||
            LLVMFuzzerTestOneInput(second_input, sizeof(second_input)) != 0) {
            return 1;
        }
    }

    map2check_success();
    return 0;
}
