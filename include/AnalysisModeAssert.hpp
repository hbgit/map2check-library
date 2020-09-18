//===-- include/AnalysisModeAssert.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the AnalysisModeAssert.hpp class, which 
/// modelling the programa analysis to validate an given assert in the C code.
///
//===----------------------------------------------------------------------===//

#ifndef __ANALYSISMODEASSERT_H_INCLUDED__
#define __ANALYSISMODEASSERT_H_INCLUDED__

#include <string>

using namespace std;

class AnalysisModeAssert {
    public:
        unsigned LineNumber = -1;
        string FunctionName = "";

        bool checkAssert(int Expression);
};

#endif // __ANALYSISMODEASSERT_H_INCLUDED__ 