/* ===----------- include/memtrack/memtracklog.h - definition -------*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the declaration of the memtracklog object,
/// which modelling the memtracklog object.
///
//===----------------------------------------------------------------------===//

#ifndef __MEMTRACKLOG_H_INCLUDED__
#define __MEMTRACKLOG_H_INCLUDED__

#include <stdbool.h>
#include <sys/queue.h>

typedef unsigned int BYTE;

typedef enum v_type {  
  ALLOCA,
  NON_STATIC_ALLOCA,
  FUNCTION,
  STORE_PTR,
  FREE,
  MALLOC,
  CALLOC  
} mem_type_track;

typedef struct _memtrack_log {
  TAILQ_ENTRY(_memtrack_log) pointers;
  long step;
  int line;
  int scope;
  long var_mem_address;
  long mem_address_points_to;
  bool is_dynamic;
  bool is_free;
  const char *ptr_name;
  const char *function_name;
  int size_destiny;
  int size_primitive;
  bool is_null_valid;
  mem_type_track type_track;
} memtrack_log_t;

char *print_memtrack_obj_as_json(memtrack_log_t *obj);

memtrack_log_t *
map2check_save_memtrack_log(int line, int scope,
                            long var_mem_address, long mem_address_points_to,
                            bool is_dynamic, bool is_free, const char *ptr_name,
                            const char *function_name, int size_destiny,
                            int size_primitive, bool is_null_valid, mem_type_track type_track);

bool is_equal_memtrack_obj(memtrack_log_t *obj1, memtrack_log_t *obj2);

void set_malloc(memtrack_log_t *obj);
void set_calloc(int quantity, memtrack_log_t *obj);
// NOTE: realloc is modelling by set free and then execute a new malloc
void set_free(memtrack_log_t *obj);


#endif // __MEMTRACKLOG_H_INCLUDED__