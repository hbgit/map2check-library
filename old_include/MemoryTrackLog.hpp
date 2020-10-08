//===-- include/MemoryTrackLog.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the MemoryTrackLog.hpp class, which
/// modelling the MemoryTrackLog object.
///
//===----------------------------------------------------------------------===//

#ifndef __MEMORYTRACKLOG_H_INCLUDED__
#define __MEMORYTRACKLOG_H_INCLUDED__

#include <string>

#include "../lib/json.hpp"
using json = nlohmann::json;

using namespace std;

class MemoryTrackLog {
public:
  long Step = -1;
  long VarMemoryAddress = 0;
  long MemoryAddressPointsTo = 0;
  int Scope = -1;
  bool IsDynamic = false;
  bool IsFree = false;
  unsigned LineNumber = -1;
  string PointerName = "NONE";
  string FunctionName = "NONE";
  int SizeToDestiny = -1;
  int SizeOfPrimitive = -1;
  short int IsNullValid = 0;

  void setMalloc();
  void setCalloc(int Quantity);
  // NOTE: realloc is modelling by set free and then execute a new malloc  
  void setFree();
  bool isEqualMemoryTrackObj(MemoryTrackLog ObjMemory1,
                             MemoryTrackLog ObjMemory2);
};


// string printJsonObj(MemoryTrackLog ObjModelIn);
// Based on https://github.com/nlohmann/json/issues/2175
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(MemoryTrackLog, Step, VarMemoryAddress,
                                   MemoryAddressPointsTo, Scope, IsDynamic,
                                   IsFree, LineNumber, PointerName,
                                   FunctionName, SizeToDestiny,
                                   SizeOfPrimitive, IsNullValid);

#endif // __MEMORYTRACKLOG_H_INCLUDED__