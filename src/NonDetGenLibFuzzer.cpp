//===-- src/NonDetGenLibFuzzer.hpp - class definition -------*- C++ -*-===//
//
// Copyright (C) 2014 - 2020 Map2Check tool
// This file is part of the Map2Check tool, and is made available under
// the terms of the GNU General Public License version 3.
//
// SPDX-License-Identifier: (GPL-3.0)
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file contains the declaration of the NonDetGenLibFuzzer.cpp class,
/// which modelling the rules to generate nondet values using LibFuzzer.
///
//===----------------------------------------------------------------------===//

#include "../include/NonDetGenLibFuzzer.hpp"

#include <assert.h>
#include <bits/stdint-intn.h>
#include <cmath>
#include <cstdint>
#include <iostream>
#include <limits.h>
#include <limits>
#include <stdint.h>
#include <string>

#include <bitset>

using namespace std;

const uint8_t *Map2checkFuzzerData;
size_t Map2checkFuzzerSize;

unsigned long countString = 1;

int MaxNumSlotData = 57;

extern int __map2check_main__();

/// @brief Modelling an assume function to be adopted by LibFuzzer
/// @param int an expression to be analyzed
/// @return void
void nondetAssume(int Expr) {
  if (!Expr) {
    // pthread_exit(NULL);
  }
}

/// @brief This functions starts the main function of the program,
///        since in the program transformation was renamed to
///        __map2check_main__(), this beacause LLVMFuzzerTestOneInput
///        has its main function in the libfuzzer
/// @param args as input to libfuzzer or analyzed program
/// @return void
void *fuzzerExecutionFunction(void *args) {
  __map2check_main__();
  return NULL;
}

int numberOfPosInData = 25;

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
  Map2checkFuzzerData = Data;
  Map2checkFuzzerSize = Size;

  // cout << sizeof(unsigned long);

  // if(Size >= numberOfPosInData){
  __map2check_main__();
  //}

  return 0;
}

bool flagTimes = true;

// 0..1
bool libFuzzerNonDetBool() {
  // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // sizeof(bool) = 1 bytes * 8bits = 8

  if (Map2checkFuzzerSize == MaxNumSlotData) {

    bool result = 0;

    if (flagTimes) {
      result = bool(Map2checkFuzzerData[0]);
      flagTimes = false;
      // cout << "TRUE \n";
    } else {
      // cout << "FALSE \n";
      result = !bool(Map2checkFuzzerData[1]);
      flagTimes = true;
    }

    // cout << ":::::" << result << endl;
    return result;
  }

  return 0;
}

bool flagTimesC = true;

// 2..3
char libFuzzerNonDetChar() {
  // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 8bits/8 = 1byte
  // ASCII table = 0..255

  char result;

  if (Map2checkFuzzerSize == MaxNumSlotData) {

    if (flagTimesC) {
      result = char(Map2checkFuzzerData[2]);
      // cout << "0::" << result << endl;
      flagTimesC = false;
      // cout << "TRUE \n";
    } else {
      // cout << "FALSE \n";
      result = char(Map2checkFuzzerData[3]);
      // cout << "1::" << result << endl;
      flagTimesC = true;
    }

    return result;
  }

  return 0;
}

// 4..5
// 32767
short libFuzzerNonDetShort() {
  // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 2 bytes * 8 = 16/8 slots from data

  short result = 0;
  // cout << sizeof(short);

  if (Map2checkFuzzerSize == MaxNumSlotData) {

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
      result = result | short(Map2checkFuzzerData[cnt]);
    }

    // cout << ":::::" << result << endl;

    return result;
  }

  return 0;
}

// 6..9
unsigned libFuzzerNonDetUnsigned() {
  // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 4 bytes * 8 = 32/8 = 4 slots from data

  unsigned result = 0;
  // cout << sizeof(unsigned);

  if (Map2checkFuzzerSize == MaxNumSlotData) {

    for (size_t cnt = 6; cnt < 10; cnt++) {
      result = result << 8;
      // uint8_t is indeed an alias of unsigned char
      result = result | unsigned(Map2checkFuzzerData[cnt]);
    }

    // cout << ":::::" << result << endl;

    return result;
  }

  return 0;
}

// 10..13
int32_t libFuzzerNonDetInt32_t() {
  // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 32bits/8 = 4
  // 4 bytes * 8 =  32/8 = 4 slots from data

  int32_t result = 0;
  // cout << sizeof(int32_t);

  if (Map2checkFuzzerSize == MaxNumSlotData) {
    for (size_t cnt = 10; cnt < 14; cnt++) {
      result = result << 8;
      // uint8_t is indeed an alias of unsigned char
      result = result | int32_t(Map2checkFuzzerData[cnt]);
    }
    // cout << ":::::" << result << endl;

    return result;
  }

  return 0;
}

// 14..21
char *libFuzzerNonDetPChar() {
  // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 8 * 8 = 64 bits /8 = 8 slots from data

  string strchar;
  char ResultDefault[1] = "";
  // cout << sizeof(unsigned long);

  if (Map2checkFuzzerSize == MaxNumSlotData) {
    for (size_t cnt = 14; cnt < 22; cnt++) {
      strchar += (char)(Map2checkFuzzerData[cnt]);
    }

    // strchar = string(result);
    // cout << "::::" << strchar << endl;
    char result[strchar.size()];
    int i;
    for (i = 0; i < sizeof(result); i++) {
      result[i] = strchar[i];
    }

    return result;
  }

  return ResultDefault;
}

// 22..29
long libFuzzerNonDetLong() {
  // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 8 bytes * 8 = 64  /8 = 8 slots from data

  long result = 0;
  // cout << sizeof(long);

  if (Map2checkFuzzerSize == MaxNumSlotData) {

    for (size_t cnt = 22; cnt < 30; cnt++) {
      result = result << 8;
      // uint8_t is indeed an alias of unsigned char
      result = result | long(Map2checkFuzzerData[cnt]);
    }

    // cout << ":::::" << result << endl;

    return result;
  }

  return 0;
}

// 30..37
int64_t libFuzzerNonDetInt64_t() {
  // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 64bits/8 = 8
  // 8 bytes * 8 = 64  /8 = 8 slots from data

  // uint8_t is indeed an alias of unsigned char
  int64_t result = 0;
  // cout << sizeof(int64_t);

  if (Map2checkFuzzerSize == MaxNumSlotData) {

    for (int cnt = 30; cnt < 38; cnt++) {
      result = result << 8;
      // cout << ">> CNT" << cnt << endl;
      result = result | int(Map2checkFuzzerData[cnt]);
    }

    // cout << ":::::" << result << endl;

    return result;
  }

  return 0;
}

// 38..45
unsigned long libFuzzerNonDetULong() {
  // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 64bits/8 = 8
  // 8 bytes * 8 = 64  /8 = 8 slots from data

  unsigned long result = 0;
  // cout << sizeof(unsigned long);

  if (Map2checkFuzzerSize == MaxNumSlotData) {

    for (size_t cnt = 38; cnt < 46; cnt++) {
      result = result << 8;
      // uint8_t is indeed an alias of unsigned char
      result = result | (unsigned long)(Map2checkFuzzerData[cnt]);
    }

    // cout << ":::::" << result << endl;
    return result;
  }

  return 0;
}

// 46..49
float libFuzzerNonDetFloat() {
  // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 4bytes * 8bits = 32bits/8 = 4 slots from data

  float result;
  FloatPattern fp;
  // cout << sizeof(float);

  // All four bytes represent a 32 bit float in the reality (byte order little
  // endian).
  // 4 bytes - 0..3

  if (Map2checkFuzzerSize == MaxNumSlotData) {

    fp.byte[0] = (int)Map2checkFuzzerData[46];
    fp.byte[1] = (int)Map2checkFuzzerData[47];
    fp.byte[2] = (int)Map2checkFuzzerData[48];
    fp.byte[3] = (int)Map2checkFuzzerData[49];

    // cout << ":::::" << fp.real << endl;
    // cout << ":::::" << (float)*Map2checkFuzzerData << endl;

    // 0.0302548

    return fp.real;
  }

  return 0.0f;
}

// 50..57
double libFuzzerNonDetDouble() {
  // each value from const uint8_t has 8 bits
  // 1 byte = 8 bits
  // 8bytes * 8bits = 64bits/8 = 8 slots from data

  double result;
  DoublePattern dp;
  // cout << sizeof(unsigned long long);
  // cout << sizeof(double);

  // All four bytes represent a 32 bit float in the reality (byte order little
  // endian).
  // 4 bytes - 0..3

  if (Map2checkFuzzerSize == MaxNumSlotData) {

    dp.byte[0] = (int)Map2checkFuzzerData[50];
    dp.byte[1] = (int)Map2checkFuzzerData[51];
    dp.byte[2] = (int)Map2checkFuzzerData[52];
    dp.byte[3] = (int)Map2checkFuzzerData[53];
    dp.byte[4] = (int)Map2checkFuzzerData[54];
    dp.byte[5] = (int)Map2checkFuzzerData[55];
    dp.byte[6] = (int)Map2checkFuzzerData[56];
    dp.byte[7] = (int)Map2checkFuzzerData[57];
    return dp.real;
  }

  return 0;
}
