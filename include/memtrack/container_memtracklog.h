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
  
typedef struct greaterSmaller Struct; 

TAILQ_HEAD(memtracklog_list, _memtrack_log);
struct memtracklog_list container_memtracklog;

void map2check_init_container_memtracklog();

void map2check_save_in_tail_container_memtracklog(memtrack_log_t *objmemtrack);

void map2check_print_all_memtracklog_as_json();

memtrack_log_t * search_in_container_by_address(long address);

void map2check_map_alloca(const char *var_name, void *ptr_addres, int size,
                          int size_primitive, int line_number, int scope);

void map2check_map_non_static_alloca(const char *var_name, void *ptr_address,
                                     int size, int size_primitive,
                                     int line_number, int scope);

void map2check_map_funct_address(const char *var_name, void *ptr_address);

void map2check_map_store_pointer(void *var_address, void *value, unsigned scope,
                                 const char *var_name, int line_number,
                                 const char *funct_name);

void map2check_map_free(const char *var_name, void *ptr_addres, unsigned scope,
                        unsigned line_number, const char *funct_name);

void map2check_map_malloc(void *ptr_address, int size);

void map2check_map_calloc(void *ptr_address, int quantity, int size);

// Function from AnalysisModeMemory that handle with container_memtracklog

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

/// @brief This replaced the old is_memcleanup_error function.
/// A memcleanup error occurs when a memory leak happens but we still have
/// a pointer that points to the leaked location, so to verify we:
/// 1. From last element to the first check if some variable points to the
/// location
/// 2. If found, iterates from the found element to the last and check if the
/// pointer does not change.
/// 3a. If it doesn't change, then it is a memcleanup error
/// 3b. Else, go on 1 loop.
/// 4. If loop ends without finding leaked address, then it isn't a memcleanup
/// error.
/// @param memory_address to be searched in the list
/// @return bool, TRUE is invalid (BUG was found) and FALSE is valid.
bool is_addr_a_memcleanup_error_in_cntr(long memory_address);

/// @brief This replaced the old is_valid_heap_address function.
/// Checking if a given Address is valid in the Heap Address.
/// It is called heap because it is a pile of memory space available to
/// programmers to allocated and de-allocate. We iterate over all elements,
/// beggining from back, if the address that we are looking for is in the range
/// of the element address memory space, different from Alloca here we do not
/// check if the element is not free.
/// @param address Address to set up as alloca
/// @param size    Size memory
/// @return bool, TRUE is invalid (BUG was found) and FALSE is valid.
bool is_addr_valid_heap_in_cntr(long address, int size);

/// @brief This replaced the old valid_allocation_log function.
/// It is to check if all address allocated and tracked
/// were released at the end of the program, to check this, we iterate
/// over all elements starting from bottom of allocation log, if the
/// address of the current item is not Free, we iterate from the top
/// if we find that the address was released.
/// @return map<bool,Address>, TRUE is invalid (BUG was found) and FALSE is valid; 
/// and the invalid Address.
map_result_mem_ar is_all_address_valid_in_cntr();

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
bool is_a_valid_address_in_cntr(long address, int size);

/// @brief old map2check_free_resolved_address function. 
/// Check if a given address is valid to be dealallocated.
/// @param address to be analyzed
/// @return bool, TRUE is invalid (BUG was found) and FALSE is valid.
bool free_resolved_address_in_cntr(long address, bool is_null_valid);

#endif // __CONTAINERMEMTRACKLOG_H_INCLUDED__