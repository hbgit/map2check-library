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

using namespace std;

class MemoryTrackLog {
public:
  long VarMemoryAddress;
  long MemoryAddressPointsTo;
  int Scope;
  bool IsDynamic;
  bool IsFree;
  unsigned LineNumber;
  string PointerName;
  string FunctionName;
  int SizeToDestiny;
  int SizeOfPrimitive;
};

#endif // __MEMORYTRACKLOG_H_INCLUDED__