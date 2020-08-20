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

class ContainerAllocaLog {
    public:
        list<map<long, AllocaLog>> ContainerLog_;
        string printJsonObj(AllocaLog ObjModelIn);
        map<bool,long> allocaLogIsValid();
        bool isValidAllocaAddress(long Address, int Size);
        AllocaLog getDataFromLog(long Address);
        bool hasAddressInLog(long Address);
        void setDealallocInAddress(long Step, long Address);
        void setAllocInAddress(long Step, long Address);

        AllocaLog searchContainerAllocaLog(long Address);
};

#endif // __CONTAINERALLOCLOG_H_INCLUDED__ 