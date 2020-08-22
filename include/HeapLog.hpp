//===-- include/HeapLog.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the HeapLog.hpp class, which 
/// modelling the HeapLog object.
///
//===----------------------------------------------------------------------===//

#ifndef __HEAPLOG_H_INCLUDED__
#define __HEAPLOG_H_INCLUDED__

#include <string>

using namespace std;

class HeapLog {
    public:
        void * Address;
        int SizeToLoad;
        unsigned LineNumber;
        int Scope;
        int Size;
        int SizeOfPrimitive;
        string FunctName;
};

#endif // __HEAPLOG_H_INCLUDED__ 