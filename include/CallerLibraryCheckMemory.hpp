//===-- include/CallerLibraryCheckMemory.hpp - class definition -------*- C++
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
/// This file contains the declaration of the CallerLibraryCheckMemory.hpp
/// class, which modelling the programa analysis to validate memory safety 
/// verification condition by map2check tool.
///
//===----------------------------------------------------------------------===//

#include "../include/CallerLibraryResult.hpp"
#include "../include/AnalysisModeMemory.hpp"


extern "C" void map2check_set_memcleanup();

extern "C" void map2check_check_load(void *ptr, int size);

extern "C" void map2check_check_free_resolved_address(void *ptr, unsigned line,
                                     const char *function_name,
                                     short int isNullValid);

extern "C" void map2check_check_deref(int line, const char *function_name);

extern "C" void map2check_check_free(const char *name, void *ptr, unsigned scope, unsigned line,
                    const char *function_name);

extern "C" void map2check_check_mem_endprog();