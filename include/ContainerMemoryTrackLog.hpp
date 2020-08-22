//===-- include/ContainerMemoryTrackLog.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the ContainerMemoryTrackLog.hpp class, which 
/// modelling the Container to storage a list with MemoryTrackLog objects.
///
//===----------------------------------------------------------------------===//


#ifndef __CONTAINERMEMORYTRACKLOG_H_INCLUDED__
#define __CONTAINERMEMORYTRACKLOG_H_INCLUDED__

#include "MemoryTrackLog.hpp"
#include <map>
#include <list>

using namespace std;

#include "../lib/json.hpp"
using json = nlohmann::json;

enum MemoryAddressStatus {
  STATIC = 0,
  FREE = 1,
  DYNAMIC = 2
  //  INVALID = 3
};

class ContainerMemoryTrackLog {
    public:
        list<map<long, MemoryTrackLog>> ContainerLog_;
        string printJsonObj(MemoryTrackLog ObjModelIn);
        long getLastReference(long MemoryAddress);
        bool isMemCleanUpError(long MemoryAddress);
        bool isDerefError(long MemoryAddress);
        bool isInvalidFree(long MemoryAddress);
        enum MemoryAddressStatus getMemoryAddressStatus(MemoryTrackLog ObjectMemory);
};

#endif // __CONTAINERMEMORYTRACKLOG_H_INCLUDED__ 