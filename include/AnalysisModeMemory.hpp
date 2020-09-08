//===-- include/AnalysisModeMemory.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the AnalysisModeMemory.hpp class, which 
/// modelling the programa analysis to check memory operation in a given C code.
///
//===----------------------------------------------------------------------===//

#ifndef __ANALYSISMODEMEMORY_H_INCLUDED__
#define __ANALYSISMODEMEMORY_H_INCLUDED__

#include "../include/ContainerMemoryTrackLog.hpp"

#include <string>

using namespace std;

class AnalysisModeOverflow {
    public:
        unsigned LineNumber;
        string FunctName;
        void * VarAddress;
        void * PtrAddress;
        void * ValueAddress;
        string VarName;
        unsigned long SizeAddress;
        unsigned long SizeOfPrimitive;
        int QuantityAlloc;
        int Scope;
        string PtrFunctName;
        bool IsNullValid;
        bool IsCheckMemCleanUp;

        bool freeResolvedAddress(ContainerMemoryTrackLog CntrMemTrkLog);
        void updateReferenceListLog(long Address, MemoryAddressStatus Status, unsigned LineNumber);
        void memAddStorePointer(ContainerMemoryTrackLog CntrMemTrkLog);
        void memFunction();
        void memAlloca();
        void memNonStaticAlloca();
        bool memFree(ContainerMemoryTrackLog CntrMemTrkLog);
        void memCalloc();
        void memPosix();
        bool memMalloc();
        bool memIsMemCleanUpError();
        bool memLoad(void * PtrAddress, int SizeAddress);
};

#endif // __ANALYSISMODEMEMORY_H_INCLUDED__ 