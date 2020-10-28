//===-- src/analysismode/analysis_assert.c - class definition -------*- C -*-===//
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
/// This file contains the declaration of the analysis_assert.c class, which 
/// performing the programa analysis to validate an given assert in the C code.
///
//===----------------------------------------------------------------------===//

#include "../../include/caller/caller_lib_result.h"

#include <stdlib.h>

int flag_is_not_test = 1;

void debug_assert_set_only_test(){
    flag_is_not_test = 0;
}

void map2check_is_valid_assert(int line_number, const char *function_name, int expression){
    if(!expression){
        set_false_result(REACHABILITY, line_number, function_name);
        print_all_containers_as_json();
        if(flag_is_not_test){
            abort();
        }        
    }
}