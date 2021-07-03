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

/// @brief mem_type_track is a enum to identify the type of the data
/// to be tracked.
typedef enum tt_type {  
  INST_ALLOCA,
  INST_NON_STATIC_ALLOCA,
  INST_FUNCTION,
  INST_STORE,
  INST_FREE,
  INST_MALLOC,
  INST_CALLOC  
} mem_type_track;

/// @brief memtrack_log_t is a struct that define our object that 
/// has all attributes, i.e., data to be tracked in the analyzed program.
typedef struct _memtrack_log {
  TAILQ_ENTRY(_memtrack_log) pointers;
  long step;
  // attributes that are tracked
  int line;  
  const char *var_name;
  long var_mem_address; // variable memory address 
  long mem_address_points_to; // memory address that the tracked variable points to
  int scope_from_mem_address_points_to;
  bool is_dynamic;
  bool is_free;
  int scope;  
  const char *function_name;
  int size_destiny;
  int size_primitive;
  bool is_ptr;
  mem_type_track type_track;
} memtrack_log_t;


/// Functions to handle with memory track log
/// @brief Print the data object tracked in json format.
char *print_memtrack_obj_as_json(memtrack_log_t *obj);

/// @brief Collect all data to create a memory track object
/// according memtrack_log_t type structure
memtrack_log_t *
create_memtrack_object_log(int line,
                            const char *var_name,
                            long var_mem_address, 
                            long mem_address_points_to,
                            int scope_from_mem_address_points_to,
                            bool is_dynamic, 
                            bool is_free, 
                            int scope,
                            const char *function_name, 
                            int size_destiny,
                            int size_primitive, 
                            bool is_ptr,
                            mem_type_track type_track);

/// @brief Check if two memory track object are equals
bool is_equal_memtrack_obj(memtrack_log_t *obj1, memtrack_log_t *obj2);

/// @brief Set attribute is_dynamic in a memory track object
void set_malloc(memtrack_log_t *obj);

/// @brief Set attribute is_dynamic and size_destiny in a memory track object
void set_calloc(int quantity, memtrack_log_t *obj);

/// @brief Set attributes related to free instruction in a memory track object
// NOTE: realloc is modelling by set free and then execute a new malloc
void set_free(memtrack_log_t *obj);


#endif // __MEMTRACKLOG_H_INCLUDED__