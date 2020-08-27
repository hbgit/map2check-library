//===-- include/NonDetGenLibFuzzer.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the NonDetGenLibFuzzer.hpp class, which 
/// modelling the generation of nondet values using LibFuzzer.
///
//===----------------------------------------------------------------------===//

#ifndef __NONDETGENLIBFUZZER_H_INCLUDED__
#define __NONDETGENLIBFUZZER_H_INCLUDED__

#include <stdint.h>
#include <cstdint>
#include <string>

using namespace std;

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

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size);

void nondetAssume(int Expr);

bool libFuzzerNonDetBool();
char libFuzzerNonDetChar();
short libFuzzerNonDetShort();
unsigned libFuzzerNonDetUnsigned();
int32_t libFuzzerNonDetInt32_t();
char * libFuzzerNonDetPChar();
long libFuzzerNonDetLong();
int64_t libFuzzerNonDetInt64_t();
unsigned long libFuzzerNonDetULong();
unsigned int libFuzzerNonDetUint();
unsigned short libFuzzerNonDetUshort();
float libFuzzerNonDetFloat();
double libFuzzerNonDetDouble();





#endif // __NONDETGENLIBFUZZER_H_INCLUDED__ 