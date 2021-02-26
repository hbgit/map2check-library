//===-- include/analysismode/analysis_memory.h - class definition -------*- C -*-===//
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
/// This file contains the declaration of the analysis_memory.h file, which 
/// modelling the programa analysis to validate safety memory properties in 
/// a given C code.
///
//===----------------------------------------------------------------------===//

#ifndef __ANALYSISMODEMEMORY_H_INCLUDED__
#define __ANALYSISMODEMEMORY_H_INCLUDED__

#include <stdbool.h>
//#include "../memtrack/container_memtracklog.h"

// Call container_memtracklog and analyze the result

void debug_analysis_mem_set_only_test();

void map2check_set_memcleanup();

void map2check_set_null_is_valid();

void vcc_memcheck_failed(bool vcc_result, unsigned line, unsigned scope,
                           char *function_name, long address);

// This functions are from CallerLibraryCheckMemory.cpp

void map2check_check_load(void *ptr, int line, unsigned scope, int size, const char *function_name);

void map2check_check_free_resolved_address(void *ptr, unsigned line,
                                     const char *function_name,
                                     short int isNullValid);

void map2check_check_free(const char *name, void *ptr, unsigned scope, unsigned line,
                    const char *function_name);

void map2check_check_deref(void *ptr, unsigned scope, unsigned line,
                    const char *function_name);

void map2check_check_mem_endprog();

#endif // __ANALYSISMODEMEMORY_H_INCLUDED__ 