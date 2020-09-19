//===-- include/CallerLibraryNonDetLog.hpp - class definition -------*- C++
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
/// This file contains the declaration of the CallerLibraryNonDetLog.hpp class,
/// which modelling the generation and storage of the nondet values 
/// generated by map2check tool.
///
//===----------------------------------------------------------------------===//

#include "../include/ContainerNonDetLog.hpp"
#include "../include/CallerLibraryResult.hpp"
#include "../include/Nondetlog.hpp"

#include <bits/c++config.h>
#include <boost/variant.hpp>

enum TypeNonDetGen {
  KLEE,
  LIBFUZZER
};

TypeNonDetGen TypeGenValue;

extern "C" void map2checkSetNonDetGenKlee();

extern "C" void map2checkSetNonDetGenLibFuzzer();

extern "C" void map2checkStoreNonDetLog(int Line, unsigned Scope, boost::variant<int, unsigned int, long, char, double, float> Value, const char *FunctionName);

extern "C" int map2checkGenNonDet_int();

extern "C" unsigned int map2checkGenNonDet_uint();

extern "C" char map2checkGenNonDet_char();

extern "C" unsigned char map2checkGenNonDet_uchar();

extern "C" short map2checkGenNonDet_short();

extern "C" unsigned short map2checkGenNonDet_ushort();

extern "C" void * map2checkGenNonDet_pointer();

extern "C" long map2checkGenNonDet_long();

extern "C" unsigned long map2checkGenNonDet_ulong();

extern "C" bool map2checkGenNonDet_bool();

extern "C" unsigned map2checkGenNonDet_unsigned();

extern "C" char * map2checkGenNonDet_pchar();

extern "C" size_t map2checkGenNonDet_size_t();

extern "C" unsigned long map2checkGenNonDet_sector_t();

extern "C" loff_t map2checkGenNonDet_loff_t();

extern "C" double map2checkGenNonDet_double();

extern "C" float map2checkGenNonDet_float();