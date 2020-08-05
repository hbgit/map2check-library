/**
 * Copyright (C) 2014 - 2020 Map2Check tool
 * This file is part of the Map2Check tool, and is made available under
 * the terms of the GNU General Public License version 2.
 *
 * SPDX-License-Identifier: (GPL-2.0)
 **/

#include "../header/NonDetGenerator.h"
#include "../header/NonDetLog.h"

#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <signal.h>

/* Logic used for cases generation:
   1 - main function of original program is changed to _map2check_main
   2 - Fuzzer is used as a circular list
 */

extern int __map2check_main__();

#include "../header/Map2CheckFunctions.h"

void *fuzzer_execution_function(void *args) {
  __map2check_main__();
  return NULL;
}

pthread_t fuzzer_execution;

void nondet_init() { nondet_log_init(); }

void nondet_destroy() { nondet_log_destroy(); }

void nondet_cancel() { pthread_exit(NULL); } // TODO: checkout that

void nondet_assume(int expr) {
  if (!expr) {
    nondet_cancel();
  }
}

void nondet_generate_aux_witness_files() {
  nondet_log_to_file(map2check_nondet_get_log());
}

const uint8_t *map2check_fuzzer_data;

size_t map2check_fuzzer_size;

uint8_t get_next_input_from_fuzzer() {
  static int i = 0;
  if (i < map2check_fuzzer_size) {
    return map2check_fuzzer_data[i++];
  }

  i = 0;
  return map2check_fuzzer_data[i];
}

int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
  map2check_fuzzer_data = Data;
  map2check_fuzzer_size = Size;

  int prevType;
  // int currentProccess = getpid();
  // printf("Creating %d\n", currentProccess);
  pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, &prevType);
  pthread_cleanup_push(map2check_destroy, NULL);
  pthread_create(&fuzzer_execution, NULL, fuzzer_execution_function, NULL);
  pthread_join(fuzzer_execution, NULL);
  pthread_cleanup_pop(0);
  // map2check_destroy();
  return 0;
}

#define MAP2CHECK_NON_DET_GENERATOR(type)                                      \
  type map2check_non_det_##type() { return (type)get_next_input_from_fuzzer(); }

MAP2CHECK_NON_DET_GENERATOR(char)
MAP2CHECK_NON_DET_GENERATOR(pointer)
MAP2CHECK_NON_DET_GENERATOR(ushort)
MAP2CHECK_NON_DET_GENERATOR(short)
MAP2CHECK_NON_DET_GENERATOR(long)
// MAP2CHECK_NON_DET_GENERATOR(unsigned)
MAP2CHECK_NON_DET_GENERATOR(ulong)
MAP2CHECK_NON_DET_GENERATOR(bool)
MAP2CHECK_NON_DET_GENERATOR(uchar)
MAP2CHECK_NON_DET_GENERATOR(size_t)
#ifndef __INTELLISENSE__
MAP2CHECK_NON_DET_GENERATOR(loff_t)
#endif
MAP2CHECK_NON_DET_GENERATOR(sector_t)
MAP2CHECK_NON_DET_GENERATOR(double)
// MAP2CHECK_NON_DET_GENERATOR(uint)

// Considering an int on a x64, then a 64 bit integer is 8 times a 8 bit integer
int map2check_non_det_int() {
  uint64_t result = 0;
  int i = 0;
  for (; i < 8; i++)
    result |= get_next_input_from_fuzzer() << (8 * i);

  return (int)result;
}

uint map2check_non_det_uint() { return (uint)map2check_non_det_int(); }

unsigned map2check_non_det_unsigned() {
  return (unsigned)map2check_non_det_int();
}

char *map2check_non_det_pchar() {
  unsigned length = map2check_non_det_unsigned();
  if (length == 0)
    return NULL;
  char string[length];
  unsigned i = 0;
  for (i = 0; i < (length - 1); i++) {
    string[i] = map2check_non_det_char();
  }
  string[i] = '\0';
  return string;
}
