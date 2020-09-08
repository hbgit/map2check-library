//===-- include/ContainerAllocaLog.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the ContainerAllocaLog.hpp class, which 
/// modelling the Container to storage a list with AllocaLog objects.
///
//===----------------------------------------------------------------------===//


#ifndef __CONTAINERALLOCLOG_H_INCLUDED__
#define __CONTAINERALLOCLOG_H_INCLUDED__

#include "AllocaLog.hpp"
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

class ContainerAllocaLog {
    public:
        list<map<long, AllocaLog>> ContainerLog_;
        string printJsonObj(AllocaLog ObjModelIn);
        map<bool,long> allocaLogIsValid();
        bool isValidAllocaAddress(long Address, int Size);        
        enum MemoryAddressStatus getAddressTypeInLog(long Address);
        void setDealallocInAddress(long Step, long Address);
        void setAllocInAddress(long Step, long Address);
        void setMalloc(long Step, long Address, int Size);
        void setCalloc(long Step, long Address, int Quantity, int Size);

        AllocaLog searchContainerAllocaLog(long Address);
        AllocaLog getDataFromLog(long Address);
};

#endif // __CONTAINERALLOCLOG_H_INCLUDED__ 