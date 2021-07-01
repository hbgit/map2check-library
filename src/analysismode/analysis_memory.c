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
#include "../../include/analysismode/analysis_memory.h"
#include "../../include/memtrack/container_memtracklog.h"
#include "../../include/caller/caller_lib_result.h"

bool is_null_valid = false;
bool is_check_memcleanup = false;
bool debug_analysis_mem = false;

typedef enum v_type {  
  FREE,
  DEREF,
  MEMTRACK,
  MEMCLEANUP  
} violated_mem_type;

void debug_analysis_mem_set_only_test(){
    debug_analysis_mem = true;
}

void map2check_set_memcleanup(){
    is_check_memcleanup = true;
}

void map2check_set_null_is_valid(){
    is_null_valid = true;
}


void vcc_memcheck_failed(bool vcc_result, unsigned line, unsigned scope, 
                        const char *function_name, long address, violated_mem_type type){ 
    if (vcc_result) {
        // TODO: add other data in the json result
        if(type == FREE){
            set_false_result(MEMSAFETY_FREE, line, function_name);
        }else if(type == DEREF){
            set_false_result(MEMSAFETY_DEREF, line, function_name);
        }else if(type == MEMTRACK){
            set_false_result(MEMSAFETY_MEMTRACK, line, function_name);
        }else if(type == MEMCLEANUP){
            set_false_result(MEMSAFETY_MEMCLEANUP, line, function_name);
        }
         
        print_all_containers_as_json();
        if (!debug_analysis_mem) {
            abort();
        }
    }
}

void map2check_check_load(void *ptr, int line, unsigned scope, int size, const char *function_name){
    vcc_reset_meta_data();

    if(!is_check_memcleanup){
        if(!(is_a_invalid_address_in_cntr((long)ptr, size))){
            vcc_memcheck_failed(true, line, scope, function_name, (long)ptr, DEREF);
        }
    }
}

void map2check_check_free_resolved_address(void *ptr, unsigned line,
                                     const char *function_name,
                                     short int isNullValid){
    vcc_reset_meta_data();

    if(!is_check_memcleanup){
        if(free_resolved_address_in_cntr((long) ptr, is_null_valid)){
            vcc_memcheck_failed(true, line, 0, function_name, (long)ptr, FREE);
        }
    }
}

void map2check_check_free(const char *name, void *ptr, unsigned scope, unsigned line,
                    const char *function_name){
    vcc_reset_meta_data();

    if(!is_check_memcleanup){
        if((long) ptr == (long)NULL && is_null_valid){
            vcc_memcheck_failed(true, line, scope, function_name, (long)ptr, FREE); 
        }
        if(is_addr_a_invalid_free_in_cntr((long) ptr)){
           vcc_memcheck_failed(true, line, scope, function_name, (long)ptr, FREE); 
        }
    }
}

void map2check_check_deref(void *ptr, unsigned scope, unsigned line,
                    const char *function_name){
    vcc_reset_meta_data();

    if(!is_check_memcleanup){
        if(is_addr_a_deref_error_in_cntr((long) ptr)){
            vcc_memcheck_failed(true, line, scope, function_name, (long)ptr, DEREF); 
        }
    }
}

//TODO: review this vcc
void map2check_check_mem_endprog(){
    vcc_reset_meta_data();
    
    if(is_check_memcleanup){
        if(is_addr_a_memcleanup_error_in_cntr()){
            vcc_memcheck_failed(true, -1, -1, "main", 0, MEMCLEANUP); 
        }
    }else{
        vcc_memcheck_failed(true, -1, -1, "main", 0, MEMTRACK);
    }
  
}


#endif // __ANALYSISMODEMEMORY_H_INCLUDED__ 