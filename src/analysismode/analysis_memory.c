//===-- include/analysismode/analysis_memory.c - class definition -------*- C -*-===//
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
/// This file contains the declaration of the analysis_memory.c file, which 
/// performs the programa analysis to validate safety memory properties in 
/// a given C code.
///
//===----------------------------------------------------------------------===//

#ifndef __ANALYSISMODEMEMORY_H_INCLUDED__
#define __ANALYSISMODEMEMORY_H_INCLUDED__

#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include "../../include/memtrack/container_memtracklog.h"

bool is_null_valid = false;
bool is_check_memcleanup = false;
bool debug_analysis_mem = false;

void debug_analysis_mem_set_only_test(){
    debug_analysis_mem = true;
    // functions that handle with container_memtracklog
    // should write in the container memtrack
    printf("]");
}

void map2check_set_memcleanup(){
    is_check_memcleanup = true;
}

void map2check_set_null_is_valid(){
    is_null_valid = true;
}

// TODO: This functions are from CallerLibraryCheckMemory.cpp

void map2check_check_load(void *ptr, int size);

void map2check_check_free_resolved_address(void *ptr, unsigned line,
                                     const char *function_name,
                                     short int isNullValid);

void map2check_check_deref(int line, const char *function_name);

void map2check_check_free(const char *name, void *ptr, unsigned scope, unsigned line,
                    const char *function_name);

void map2check_check_mem_endprog();

// TODO: add functions from AnalysisModeMemory.hpp

bool is_valid_alloca_address(long address, int size);

#endif // __ANALYSISMODEMEMORY_H_INCLUDED__ 