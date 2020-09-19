//===-- include/CallerLibraryCheckReach.hpp - class definition -------*- C++
//-*-===//
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
/// This file contains the declaration of the CallerLibraryCheckReach.hpp class,
/// which modelling the programa analysis to validate an assert by map2check tool.
///
//===----------------------------------------------------------------------===//

#include "../include/CallerLibraryResult.hpp"


extern "C" void map2check_assert(int Condition, int LineNumber, const char *FunctionName);