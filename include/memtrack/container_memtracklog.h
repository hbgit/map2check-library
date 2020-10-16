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

#endif // __CONTAINERMEMTRACKLOG_H_INCLUDED__