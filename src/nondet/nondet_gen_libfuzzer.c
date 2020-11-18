/* ===----------- src/nondet/nondet_gen_libfuzzer.c - definition -------*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the performing the nondet genarator data using 
/// libfuzzer.
///
//===----------------------------------------------------------------------===//

#include "../../include/nondet/nondet_gen_libfuzzer.h"

#include <bits/stdint-intn.h>
#include <bits/stdint-uintn.h>
#include <stddef.h>
#include <stdbool.h>
#include <sys/types.h>
#include <stdio.h>

const uint8_t * map2check_fuzzer_data;
size_t map2check_fuzzer_size;

unsigned long count_string = 1;
int max_num_slot_data = 57;

void map2check_fuzzer_assume(int Expr){
   printf("Not implemented yet :(\n");
}


extern int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
  map2check_fuzzer_data = Data;
  map2check_fuzzer_size = Size;

  __map2check_main__();

  return 0;
}

bool flag_times = true;
// 0..1
bool map2check_gen_data_fuzzer_bool(){
   // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // sizeof(bool) = 1 bytes * 8bits = 8

  if (map2check_fuzzer_size == max_num_slot_data) {

    bool result = 0;

    if (flag_times) {
      result = (bool) map2check_fuzzer_data[0];
      flag_times = false;      
    } else {  
      result = !(bool) map2check_fuzzer_data[1];
      flag_times = true;
    }

    return result;
  }

  return 0;
}

bool flag_times_c = true;
// 2..3
char map2check_gen_data_fuzzer_char(){
   // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 8bits/8 = 1byte
  // ASCII table = 0..255

  char result;

  if (map2check_fuzzer_size == max_num_slot_data) {

    if (flag_times_c) {
      result = (char) (map2check_fuzzer_data[2]);
      flag_times_c = false;
    } else {
      result = (char) (map2check_fuzzer_data[3]);
      flag_times_c = true;
    }

    return result;
  }

  return 0;
}

// 4..5
short map2check_gen_data_fuzzer_short(){
   // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 2 bytes * 8 = 16/8 slots from data

  short result = 0;
  // cout << sizeof(short);

  if (map2check_fuzzer_size == max_num_slot_data) {

    for (size_t cnt = 4; cnt < 6; cnt++) {
      // as result is a 16 bits in every time to combine the next 8 bits,
      // we first shift 8 bits, e.g.:
      // 1 ite:
      // result = 0000000000000000 << 8 = 0
      // result = 0 | 11111111 = 11111111
      // 2 ite and last in this case:
      // result = 11111111 << 8 = 1111111100000000 <- 16bits
      // result = 1111111100000000 | 11111111 = 1111111111111111 <- max bits =
      // 65535
      result = result << 8;
      //
      // uint8_t is indeed an alias of unsigned char
      result = result | (short)(map2check_fuzzer_data[cnt]);
    }

    return result;
  }

  return 0;
}

// 6..9
unsigned map2check_gen_data_fuzzer_unsigned(){
   // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 4 bytes * 8 = 32/8 = 4 slots from data

  unsigned result = 0;
  //cout << sizeof(unsigned int);

  if (map2check_fuzzer_size == max_num_slot_data) {

    for (size_t cnt = 6; cnt < 10; cnt++) {
      result = result << 8;
      // uint8_t is indeed an alias of unsigned char
      result = result | (unsigned)(map2check_fuzzer_data[cnt]);
    }

    // cout << ":::::" << result << endl;

    return result;
  }

  return 0;
}

// 10..13
int32_t map2check_gen_data_fuzzer_int32_t(){
   // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 32bits/8 = 4
  // 4 bytes * 8 =  32/8 = 4 slots from data

  int32_t result = 0;
  // cout << sizeof(int32_t);

  if (map2check_fuzzer_size == max_num_slot_data) {
    for (size_t cnt = 10; cnt < 14; cnt++) {
      result = result << 8;
      // uint8_t is indeed an alias of unsigned char
      result = result | (int32_t)(map2check_fuzzer_data[cnt]);
    }

    return result;
  }

  return 0;
}

// 14..21
char * map2check_gen_data_fuzzer_pchar(){
   // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 8 * 8 = 64 bits /8 = 8 slots from data

  //string strchar;
  char ResultDefault[1] = "";
  // cout << sizeof(unsigned long);

//   if (Map2checkFuzzerSize == MaxNumSlotData) {
//     for (size_t cnt = 14; cnt < 22; cnt++) {
//       strchar += (char)(Map2checkFuzzerData[cnt]);
//     }

//     // strchar = string(result);
//     // cout << "::::" << strchar << endl;
//     char result[strchar.size()];
//     int i;
//     for (i = 0; i < sizeof(result); i++) {
//       result[i] = strchar[i];
//     }

//     return result;
//   }

  return ResultDefault;
}

// 22..29
long map2check_gen_data_fuzzer_long(){
   // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 8 bytes * 8 = 64  /8 = 8 slots from data

  long result = 0;
  // cout << sizeof(long);

  if (map2check_fuzzer_size == max_num_slot_data) {

    for (size_t cnt = 22; cnt < 30; cnt++) {
      result = result << 8;
      // uint8_t is indeed an alias of unsigned char
      result = result | (long)(map2check_fuzzer_data[cnt]);
    }

    return result;
  }

  return 0;
}

// 30..37
int64_t map2check_gen_data_fuzzer_int64_t(){
   // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 64bits/8 = 8
  // 8 bytes * 8 = 64  /8 = 8 slots from data

  // uint8_t is indeed an alias of unsigned char
  int64_t result = 0;
  // cout << sizeof(int64_t);

  if (map2check_fuzzer_size == max_num_slot_data) {

    for (int cnt = 30; cnt < 38; cnt++) {
      result = result << 8;
      // cout << ">> CNT" << cnt << endl;
      result = result | (int)(map2check_fuzzer_data[cnt]);
    }

    return result;
  }

  return 0;
}

// 38..45
unsigned long map2check_gen_data_fuzzer_ulong(){
   // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 64bits/8 = 8
  // 8 bytes * 8 = 64  /8 = 8 slots from data

  unsigned long result = 0;
  // cout << sizeof(unsigned long);

  if (map2check_fuzzer_size == max_num_slot_data) {

    for (size_t cnt = 38; cnt < 46; cnt++) {
      result = result << 8;
      // uint8_t is indeed an alias of unsigned char
      result = result | (unsigned long)(map2check_fuzzer_data[cnt]);
    }

    // cout << ":::::" << result << endl;
    return result;
  }

  return 0;
}

// 46..49
unsigned int map2check_gen_data_fuzzer_uint(){
   // 4 bytes * 8 = 32  /8 = 4 slots from data
  //cout << sizeof(unsigned int);
  unsigned int result = 0;
  // cout << sizeof(unsigned long);

  if (map2check_fuzzer_size == max_num_slot_data) {

    for (size_t cnt = 46; cnt < 50; cnt++) {
      result = result << 8;
      // uint8_t is indeed an alias of unsigned char
      result = result | (unsigned int)(map2check_fuzzer_data[cnt]);
    }

    // cout << ":::::" << result << endl;
    return result;
  }

  return 0;
}

//50..51
unsigned short map2check_gen_data_fuzzer_ushort(){
   // 2 bytes * 8 = 16  /8 = 2 slots from data
  unsigned short result = 0;
  // cout << sizeof(unsigned long);

  if (map2check_fuzzer_size == max_num_slot_data) {

    for (size_t cnt = 50; cnt < 52; cnt++) {
      result = result << 8;
      // uint8_t is indeed an alias of unsigned char
      result = result | (unsigned short)(map2check_fuzzer_data[cnt]);
    }

    return result;
  }

  return 0;
}

// 52..55
float map2check_gen_data_fuzzer_float(){
   // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 4bytes * 8bits = 32bits/8 = 4 slots from data

  float result;
  union FloatPattern fp;
  // cout << sizeof(float);

  // All four bytes represent a 32 bit float in the reality (byte order little
  // endian).
  // 4 bytes - 0..3

  if (map2check_fuzzer_size == max_num_slot_data) {

    fp.byte[0] = (int)map2check_fuzzer_data[52];
    fp.byte[1] = (int)map2check_fuzzer_data[53];
    fp.byte[2] = (int)map2check_fuzzer_data[54];
    fp.byte[3] = (int)map2check_fuzzer_data[55];

    // 0.0302548

    return fp.real;
  }

  return 0.0f;
}

// 56..63
double map2check_gen_data_fuzzer_double(){
   // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 8bytes * 8bits = 64bits/8 = 8 slots from data

  double result;
  union DoublePattern dp;
  // cout << sizeof(unsigned long long);
  // cout << sizeof(double);

  // All four bytes represent a 32 bit float in the reality (byte order little
  // endian).
  // 4 bytes - 0..3

  if (map2check_fuzzer_size == max_num_slot_data) {

    dp.byte[0] = (int)map2check_fuzzer_data[56];
    dp.byte[1] = (int)map2check_fuzzer_data[57];
    dp.byte[2] = (int)map2check_fuzzer_data[58];
    dp.byte[3] = (int)map2check_fuzzer_data[59];
    dp.byte[4] = (int)map2check_fuzzer_data[60];
    dp.byte[5] = (int)map2check_fuzzer_data[61];
    dp.byte[6] = (int)map2check_fuzzer_data[62];
    dp.byte[7] = (int)map2check_fuzzer_data[63];
    return dp.real;
  }

  return 0;
}

char map2check_gen_data_fuzzer_uchar(){
   char c;
   return c;
}











size_t map2check_gen_data_fuzzer_size_t();

unsigned long map2check_gen_data_fuzzer_sector_t();

loff_t map2check_gen_data_fuzzer_loff_t();


