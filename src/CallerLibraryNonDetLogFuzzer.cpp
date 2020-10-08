//===-- include/CallerLibraryNonDetLog.cpp - class definition -------*- C++
//-*-===//
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
/// This file contains the declaration of the CallerLibraryNonDetLog.cpp class,
/// which performs the generation and storage of the nondet values
/// generated by map2check tool.
///
//===----------------------------------------------------------------------===//

#include "../include/CallerLibraryNonDetLogFuzzer.hpp"
#include "../include/NonDetGenLibFuzzer.hpp"

#include "../include/CallerLibraryResult.hpp"

#include <cstddef>
#include <sys/types.h>
#include <string>


template <typename T>
void storeNonDetLog(int Line, unsigned Scope, T Value,
                    const char *FunctionName) {

  NonDetLog NonDetLogObj; 

  incrCurrentStep();
  NonDetLogObj.Step = getCurrentStep();
  NonDetLogObj.Line = Line;
  NonDetLogObj.Scope = Scope;  
  NonDetLogObj.Value = Value; 
  NonDetLogObj.FunctionName = FunctionName;


  ResultCntrNonDetLog.ContainerLog_.push_back(NonDetLogObj);
  
}


// extern "C" void map2checkStoreNonDetLogInt(
//     int Line, unsigned Scope,
//     int Value,
//     const char *FunctionName) {
  
//   storeNonDetLog(Line, Scope, Value, FunctionName);
// }

extern "C" void map2checkStoreNonDetLogUnsignedInt(
    int Line, unsigned Scope,
    unsigned int Value,
    const char *FunctionName) {
  
  storeNonDetLog<unsigned int>(Line, Scope, Value, FunctionName);
}

// extern "C" void map2checkStoreNonDetLogLong(
//     int Line, unsigned Scope,
//     long Value,
//     const char *FunctionName) {
  
//   storeNonDetLog(Line, Scope, Value, FunctionName);
// }

// extern "C" void map2checkStoreNonDetLogChar(
//     int Line, unsigned Scope,
//     char Value,
//     const char *FunctionName) {
  
//   storeNonDetLog(Line, Scope, Value, FunctionName);
// }

// extern "C" void map2checkStoreNonDetLogDouble(
//     int Line, unsigned Scope,
//     double Value,
//     const char *FunctionName) {
  
//   storeNonDetLog(Line, Scope, Value, FunctionName);
// }

// extern "C" void map2checkStoreNonDetLogFloat(
//     int Line, unsigned Scope,
//     float Value,
//     const char *FunctionName) {
  
//   storeNonDetLog(Line, Scope, Value, FunctionName);
// }

void nondet_assume(int expr) { libFuzzerNonDetAssume(expr); }

extern "C" void map2check_assume(int expr) { nondet_assume(expr); }

extern "C" void map2check_crab_assume(char expr) { nondet_assume((int)expr); }

extern "C" void map2check_assume_loop(char expr) { nondet_assume((int)expr); }

extern "C" int map2checkGenNonDet_int() { return libFuzzerNonDetInt64_t(); }

extern "C" unsigned int map2checkGenNonDet_uint() {
  return libFuzzerNonDetUnsigned();
}

extern "C" char map2checkGenNonDet_char() { return libFuzzerNonDetChar(); }

extern "C" unsigned char map2checkGenNonDet_uchar() {
  unsigned char t;
  return t;
}

extern "C" short map2checkGenNonDet_short() { return libFuzzerNonDetShort(); }

extern "C" unsigned short map2checkGenNonDet_ushort() {
  return libFuzzerNonDetUshort();
}

extern "C" void *map2checkGenNonDet_pointer() {
  void *p;
  return p;
}

extern "C" long map2checkGenNonDet_long() { return libFuzzerNonDetLong(); }

extern "C" unsigned long map2checkGenNonDet_ulong() {
  return libFuzzerNonDetULong();
}

extern "C" bool map2checkGenNonDet_bool() { return libFuzzerNonDetBool(); }

extern "C" unsigned map2checkGenNonDet_unsigned() {
  return libFuzzerNonDetUnsigned();
}

extern "C" char *map2checkGenNonDet_pchar() { return libFuzzerNonDetPChar(); }

extern "C" size_t map2checkGenNonDet_size_t() {
  size_t t;
  return t;
}

extern "C" unsigned long map2checkGenNonDet_sector_t() {
  return map2checkGenNonDet_long();
}

extern "C" loff_t map2checkGenNonDet_loff_t() {
  loff_t f;
  return f;
}

extern "C" double map2checkGenNonDet_double() {
  return libFuzzerNonDetDouble();
}

extern "C" float map2checkGenNonDet_float() { return libFuzzerNonDetFloat(); }