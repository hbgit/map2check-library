//===-- include/AnalysisModeAssert.cpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the AnalysisModeAssert.cpp class, which 
/// execute the programa analysis to validate an given assert in the C code.
///
//===----------------------------------------------------------------------===//

#include "../include/AnalysisModeAssert.hpp"

bool AnalysisModeAssert::checkAssert(int Expression){
    if(!Expression){
        return false;
    }
    return true;
}