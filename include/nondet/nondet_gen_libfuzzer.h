/* ===----------- include/nondet/nondet_gen_libfuzzer.h - definition -------*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the modelling of the nondet genarator data using 
/// libfuzzer.
///
//===----------------------------------------------------------------------===//

#ifndef __NONDETGENLIBFUZZER_H_INCLUDED__
#define __NONDETGENLIBFUZZER_H_INCLUDED__

#include <bits/stdint-intn.h>
#include <bits/stdint-uintn.h>
#include <stddef.h>
#include <stdbool.h>
#include <sys/types.h>

union FloatPattern
{
   unsigned char byte[4];
   float real;
};

union DoublePattern
{
   unsigned char byte[8];
   double real;
};

extern int __map2check_main__();

extern int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size);

void map2check_fuzzer_assume(int Expr);

bool map2check_gen_data_fuzzer_bool();

int32_t map2check_gen_data_fuzzer_int32_t();

int64_t map2check_gen_data_fuzzer_int64_t();

unsigned map2check_gen_data_fuzzer_unsigned();

unsigned int map2check_gen_data_fuzzer_uint();

char map2check_gen_data_fuzzer_char();

char map2check_gen_data_fuzzer_uchar();

char * map2check_gen_data_fuzzer_pchar();

short map2check_gen_data_fuzzer_short();

unsigned short map2check_gen_data_fuzzer_ushort();

long map2check_gen_data_fuzzer_long();

unsigned long map2check_gen_data_fuzzer_ulong();

size_t map2check_gen_data_fuzzer_size_t();

unsigned long map2check_gen_data_fuzzer_sector_t();

loff_t map2check_gen_data_fuzzer_loff_t();

float map2check_gen_data_fuzzer_float();

double map2check_gen_data_fuzzer_double();


#endif // __NONDETGENLIBFUZZER_H_INCLUDED__