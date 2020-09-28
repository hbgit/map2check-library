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

#include "../include/CallerLibraryNonDetLog.hpp"
#include "../include/NonDetGenKlee.hpp"
#include "../include/NonDetGenLibFuzzer.hpp"

#include "../include/CallerLibraryResult.hpp"

#include <cstddef>
#include <sys/types.h>

NonDetLog GlobalNonDetLog;

/// @brief Set nondet values generation using KLEE
/// @return Void
extern "C" void map2checkSetNonDetGenKlee() { TypeGenValue = KLEE; }


/// @brief Set nondet values generation using LibFuzzer
/// @return Void
extern "C" void map2checkSetNonDetGenLibFuzzer() { TypeGenValue = LIBFUZZER; }


extern "C" void map2checkStoreNonDetLog(
    int Line, unsigned Scope,
    boost::variant<int, unsigned int, long, char, double, float> Value,
    const char *FunctionName) {
  incrCurrentStep();
  GlobalNonDetLog.Step = getCurrentStep();
  GlobalNonDetLog.Line = Line;
  GlobalNonDetLog.Scope = Scope;
  GlobalNonDetLog.Value = Value;
  GlobalNonDetLog.FunctionName = *FunctionName;

  ResultCntrNonDetLog.ContainerLog_.push_back(GlobalNonDetLog);
}


void nondet_assume(int expr){
  if (TypeGenValue == KLEE) {
    kleeNondetAssume(expr);
  }else if (TypeGenValue == LIBFUZZER) {
    libFuzzerNonDetAssume(expr);
  }
}

extern "C" void map2check_assume(int expr){
  nondet_assume(expr);
}


extern "C" void map2check_crab_assume(char expr){
  nondet_assume((int)expr);
}


extern "C" void map2check_assume_loop(char expr){
  nondet_assume((int)expr);
}


extern "C" int map2checkGenNonDet_int() {
  if (TypeGenValue == LIBFUZZER) {
    return genericKleeNonDetGen<int>();
  } else if (TypeGenValue == KLEE) {
    return libFuzzerNonDetInt64_t();
  }

  return 0;
}

extern "C" unsigned int map2checkGenNonDet_uint() {
  if (TypeGenValue == LIBFUZZER) {
    return genericKleeNonDetGen<unsigned>();
  } else if (TypeGenValue == KLEE) {
    return libFuzzerNonDetUnsigned();
  }

  return 0;
}

extern "C" char map2checkGenNonDet_char() {
  if (TypeGenValue == LIBFUZZER) {
    return genericKleeNonDetGen<char>();
  } else if (TypeGenValue == KLEE) {
    return libFuzzerNonDetChar();
  }

  return 0;
}

extern "C" unsigned char map2checkGenNonDet_uchar() {
  unsigned char t;
  return t;
}

extern "C" short map2checkGenNonDet_short() {
  if (TypeGenValue == LIBFUZZER) {
    return genericKleeNonDetGen<short>();
  } else if (TypeGenValue == KLEE) {
    return libFuzzerNonDetShort();
  }

  return 0;
}

extern "C" unsigned short map2checkGenNonDet_ushort() {
  if (TypeGenValue == LIBFUZZER) {
    return genericKleeNonDetGen<unsigned short>();
  } else if (TypeGenValue == KLEE) {
    return libFuzzerNonDetUshort();
  }

  return 0;
}

extern "C" void *map2checkGenNonDet_pointer() {
  void *p;
  return p;
}

extern "C" long map2checkGenNonDet_long() {
  if (TypeGenValue == LIBFUZZER) {
    return genericKleeNonDetGen<long>();
  } else if (TypeGenValue == KLEE) {
    return libFuzzerNonDetLong();
  }

  return 0;
}

extern "C" unsigned long map2checkGenNonDet_ulong() {
  if (TypeGenValue == LIBFUZZER) {
    return genericKleeNonDetGen<unsigned long>();
  } else if (TypeGenValue == KLEE) {
    return libFuzzerNonDetULong();
  }

  return 0;
}

extern "C" bool map2checkGenNonDet_bool() {
  if (TypeGenValue == LIBFUZZER) {
    return genericKleeNonDetGen<bool>();
  } else if (TypeGenValue == KLEE) {
    return libFuzzerNonDetBool();
  }
  return 0;
}

extern "C" unsigned map2checkGenNonDet_unsigned() {
  if (TypeGenValue == LIBFUZZER) {
    return genericKleeNonDetGen<unsigned>();
  } else if (TypeGenValue == KLEE) {
    return libFuzzerNonDetUnsigned();
  }
  return 0;
}

extern "C" char *map2checkGenNonDet_pchar() {
  if (TypeGenValue == LIBFUZZER) {
    return genericKleeNonDetGen<char *>();
  } else if (TypeGenValue == KLEE) {
    return libFuzzerNonDetPChar();
  }
  return 0;
}

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
  if (TypeGenValue == LIBFUZZER) {
    return genericKleeNonDetGen<double>();
  } else if (TypeGenValue == KLEE) {
    return libFuzzerNonDetDouble();
  }
  return 0.0;
}

extern "C" float map2checkGenNonDet_float() {
  if (TypeGenValue == LIBFUZZER) {
    return genericKleeNonDetGen<float>();
  } else if (TypeGenValue == KLEE) {
    return libFuzzerNonDetFloat();
  }
  return 0;
}