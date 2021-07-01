/* ===---- include/memtrack/container_memtracklog.c - definition -----*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the declaration of the Container to the container_memtracklog object,
/// which performing the Container to storage a list with container_memtracklog objects.
///
//===----------------------------------------------------------------------===//

#ifndef __CONTAINERMEMTRACKLOG_H_INCLUDED__
#define __CONTAINERMEMTRACKLOG_H_INCLUDED__

#include "memtracklog.h"

#include <sys/queue.h> 
#include <stdbool.h>

typedef struct { 
    long addr;
    bool result;
} map_result_mem_ar; 
  
TAILQ_HEAD(memtracklog_list, _memtrack_log);
struct memtracklog_list container_memtracklog;

void map2check_init_container_memtracklog();

void map2check_save_in_tail_container_memtracklog(memtrack_log_t *objmemtrack);

void map2check_print_all_memtracklog_as_json();

memtrack_log_t * search_in_container_by_address(long address);

void map2check_track_data_in_cntr(const char *var_name, 
                                  void *ptr_addres, 
                                  int size,
                                  int size_primitive, 
                                  int line_number,                                   
                                  int scope,                                  
                                  int type_track,
                                  int quantity_calloc);


// Function from AnalysisModeMemory that handle with container_memtracklog
//
// VCCs for memory safety, here we have the rule in the analysis mode
// we just have a caller, this to avoid conflicts because the container_memtracklog 
// list

/// @brief This replaced the old is_invalid_free function.
/// Checking in the container memory if a given address
/// execute an invalid free, when that given address was released.
/// @param memory_address to be searched in the list
/// @return bool, TRUE is invalid (BUG was found) and FALSE is valid.
bool is_addr_a_invalid_free_in_cntr(long memory_address);

// TODO(hbgit): Could be removed?
/// @brief This replaced the old is_deref_error function.
/// Checking in the container memory if a given address
/// execute an operation with derefence error:
/// 1. Where the var memory address is not in the container
/// 2. If the address already executed an dealallocation - free
/// @param memory_address to be searched in the list
/// @return bool, TRUE is invalid (BUG was found) and FALSE is valid.
bool is_addr_a_deref_error_in_cntr(long memory_address);

/// @brief 
/// A memcleanup error occurs when a memory leak happens but we still have
/// a pointer that points to the leaked location. According to SV-COMP, 
/// All allocated memory is deallocated before the program terminates. 
/// In addition to valid-memtrack: There exists no finite execution of the 
/// program on which the program terminates but still points to allocated memory. 
/// (Comparison to Valgrind: This property can be violated even if Valgrind 
/// reports 'still reachable'.). This way, map2check consider that the  
/// memory was allocated and was not subsequently freed before the program terminated. 
/// Thus, the blocks were not freed, but they could have been freed (if the programmer 
/// had wanted to) because the program still was keeping track of pointers to those 
/// memory blocks.
/// Map2Check VCC check:
/// 1. From last element to the first, we check if some POINTED MEMORY ADDRESS 
///    is a dynamic memory
/// 2. TODO: DOING after change track memory
/// 2. If found, iterates from the found element to the last and check if the
/// pointer does not change.
/// 3a. If it doesn't change, then it is a memcleanup error
/// 3b. Else, go on 1 loop.
/// 4. If loop ends without finding leaked address, then it isn't a memcleanup
/// error.
/// @param memory_address to be searched in the list
/// @return bool, TRUE is invalid (BUG was found) and FALSE is valid.
/// TODO: The verification rules is incomplete !
bool has_a_memcleanup_error_in_cntr();

/// @brief This replaced the old is_valid_allocation_address function.
/// Checking if a given Address is valid in the Alloca Addresses tracked.
/// We iterate over all elements of the allocation log,
/// beggining from back, if the address that we are looking for is in the range
/// of the element address memory space and the element is not free, then it's
/// TRUE otherwise FALSE and we set last_address to the address of last memory
/// address of the current heap space i.e. a int on space 0x10 on a 32bit would
/// set the var to 0x13 (if the int has 4 bytes)
/// @param address Address to set up as alloca
/// @param step Current step of the program analysis
/// @return bool, TRUE is invalid (BUG was found) and FALSE is valid.
bool is_a_invalid_address_in_cntr(long address, int size);

#endif // __CONTAINERMEMTRACKLOG_H_INCLUDED__