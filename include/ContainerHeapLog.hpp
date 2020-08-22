//===-- include/ContainerHeapLog.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the ContainerHeapLog.hpp class, which 
/// modelling the Container to storage a list with HeapLog objects.
///
//===----------------------------------------------------------------------===//


#ifndef __CONTAINERHEAPLOG_H_INCLUDED__
#define __CONTAINERHEAPLOG_H_INCLUDED__

#include "HeapLog.hpp"
#include <map>
#include <list>

using namespace std;

class ContainerHeapLog {
    public:
        list<map<long, HeapLog>> ContainerLog_;
        string printJsonObj(HeapLog ObjModelIn);
        bool isValidHeapAddress(void * Address, int Size);
};

#endif // __CONTAINERHEAPLOG_H_INCLUDED__ 