/* ===----------- include/memtrack/container_memtracklog.c - definition
-------*- C
-*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the declaration of the Container to the
/// container_memtracklog object, which performing the Container to storage a
/// list with container_memtracklog objects.
///
//===----------------------------------------------------------------------===//

#include "../../include/memtrack/container_memtracklog.h"
#include "../../include/memtrack/memtracklog.h"

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/queue.h>

void map2check_init_container_memtracklog() {
  TAILQ_INIT(&container_memtracklog);
}

void map2check_save_in_tail_container_memtracklog(memtrack_log_t *objmemtrack) {
  TAILQ_INSERT_TAIL(&container_memtracklog, objmemtrack, pointers);
}

void map2check_print_all_memtracklog_as_json() {
  memtrack_log_t *tmp_memtrack;

  printf("%s", "\"container_memtrack_log\":[");
  TAILQ_FOREACH(tmp_memtrack, &container_memtracklog, pointers) {

    printf("%s", print_memtrack_obj_as_json(tmp_memtrack));
    if (tmp_memtrack->pointers.tqe_next != NULL) {
      printf(",");
    }
  }

  printf("]");
}

memtrack_log_t *search_in_container_by_address(long address) {
  memtrack_log_t *tmp_memtrack;

  TAILQ_FOREACH(tmp_memtrack, &container_memtracklog, pointers) {

    if (tmp_memtrack->var_mem_address == address) {
      return tmp_memtrack;
    }
  }

  return tmp_memtrack;
}

void map2check_map_alloca(const char *var_name, void *ptr_address, int size,
                          int size_primitive, int line_number, int scope) {

  memtrack_log_t *obj = map2check_save_memtrack_log(
      line_number, scope, (long)ptr_address, 0, false, false, var_name,
      "none", size, size_primitive, false);

  map2check_save_in_tail_container_memtracklog(obj);
}

void map2check_map_non_static_alloca(const char *var_name, void *ptr_address,
                                     int size, int size_primitive,
                                     int line_number, int scope) {
  memtrack_log_t *obj = map2check_save_memtrack_log(
      line_number, scope, (long)ptr_address, 0, false, false, var_name,
      "none", size, size_primitive, false);

  map2check_save_in_tail_container_memtracklog(obj);
}

void map2check_map_funct_address(const char *var_name, void *ptr_address) {
  memtrack_log_t *obj =
      map2check_save_memtrack_log(-1, -1, (long)ptr_address, 0, false,
                                  false, var_name, "none", -1, -1, false);

  map2check_save_in_tail_container_memtracklog(obj);
}

void map2check_map_store_pointer(void *var_address, void *value, unsigned scope,
                                 const char *var_name, int line_number,
                                 const char *funct_name) {
  memtrack_log_t *obj = map2check_save_memtrack_log(
      line_number, scope, (long)var_address, 0, false, false, var_name,
      "none", -1, -1, false);

  map2check_save_in_tail_container_memtracklog(obj);
}

void map2check_map_free(const char *var_name, void *ptr_address, unsigned scope,
                        unsigned line_number, const char *funct_name) {
  memtrack_log_t *obj = map2check_save_memtrack_log(
      line_number, scope, (long)ptr_address, 0, false, false, var_name,
      "none", -1, -1, false);
  set_free(obj);

  map2check_save_in_tail_container_memtracklog(obj);
}

void map2check_map_malloc(void *ptr_address, int size) {
  memtrack_log_t *obj =
      map2check_save_memtrack_log(-1, -1, (long)ptr_address, 0, false,
                                  false, "none", "none", -1, -1, false);
  set_malloc(obj);

  map2check_save_in_tail_container_memtracklog(obj);
}

void map2check_map_calloc(void *ptr_address, int quantity, int size) {
  memtrack_log_t *obj =
      map2check_save_memtrack_log(-1, -1, (long)ptr_address, 0, false,
                                  false, "none", "none", size, -1, false);
  set_calloc(quantity, obj);

  map2check_save_in_tail_container_memtracklog(obj);
}

/*
* Function from AnalysisModeMemory that handle with container_memtracklog
*/

bool is_addr_a_invalid_free_in_cntr(long memory_address){
  if(memory_address == (long)NULL){
    return false;
  }

  memtrack_log_t *item_memtrack;

  TAILQ_FOREACH_REVERSE(item_memtrack, &container_memtracklog, memtracklog_list, pointers) {
    if (item_memtrack->mem_address_points_to == memory_address) {
      if(item_memtrack->is_free || !item_memtrack->is_dynamic){
        return true;
      }else{
        return false;
      }
    }
  }

  return true;
}


bool is_addr_a_deref_error_in_cntr(long memory_address){
  memtrack_log_t *item_memtrack;

  TAILQ_FOREACH_REVERSE(item_memtrack, &container_memtracklog, memtracklog_list, pointers) {
    if(item_memtrack->var_mem_address ==  memory_address){
      return false;
    }

    if(item_memtrack->mem_address_points_to == memory_address){
      if(item_memtrack->is_free || !item_memtrack->is_dynamic){
        return true;
      }else{
        return false;
      }
    }
  }

  return true;
}

bool is_addr_a_memcleanup_error_in_cntr(long memory_address){
  memtrack_log_t *item_memtrack;

  TAILQ_FOREACH_REVERSE(item_memtrack, &container_memtracklog, memtracklog_list, pointers) {
    if(item_memtrack->mem_address_points_to == memory_address){
      bool error = true;

      memtrack_log_t *aux_item_memtrack = item_memtrack;
      TAILQ_FOREACH_REVERSE(aux_item_memtrack, &container_memtracklog, memtracklog_list, pointers) {
        if(item_memtrack->var_mem_address == aux_item_memtrack->var_mem_address){
          error = aux_item_memtrack->mem_address_points_to == memory_address ? true : false;
          break;
        }
      }

      if(error){
        return true;
      }

    }
  }

  return false;
}

bool is_addr_invalid_heap_in_cntr(long address, int size){
  memtrack_log_t *item_memtrack;

  TAILQ_FOREACH_REVERSE(item_memtrack, &container_memtracklog, memtracklog_list, pointers) {
    long range_addr = (long)item_memtrack->var_mem_address + 
                      (item_memtrack->size_destiny - size) + 1;

    if(item_memtrack->var_mem_address <= address && (long)address < range_addr){
      return true;
    }
  }

  return false;
}

map_result_mem_ar has_a_invalid_address_in_cntr(){
  long mem_track_addr_error = 0;
  map_result_mem_ar result_check;

  //add a list to use as cache to avoid check duplicated addr
  memtrack_log_t *item_memtrack;

  TAILQ_FOREACH_REVERSE(item_memtrack, &container_memtracklog, memtracklog_list, pointers) {
    if(item_memtrack->is_free){
      bool released_checked = false;

      memtrack_log_t *tmp_memtrack;
      TAILQ_FOREACH(tmp_memtrack, &container_memtracklog, pointers) {
        if(item_memtrack->var_mem_address == tmp_memtrack->var_mem_address && tmp_memtrack->is_free){
          released_checked = true;
        }
      }

      if(released_checked == false){
        result_check.result = true;
        result_check.addr = item_memtrack->var_mem_address;
      }
    }
  }

  result_check.result = false;
  result_check.addr = 0;
  return result_check;
}

bool is_a_invalid_address_in_cntr(long address, int size){
  memtrack_log_t *item_memtrack;

  TAILQ_FOREACH_REVERSE(item_memtrack, &container_memtracklog, memtracklog_list, pointers) {
    long range_addr = (long)item_memtrack->var_mem_address + 
                      (item_memtrack->size_destiny - size) + 1;

    if(item_memtrack->var_mem_address <= address && (long)address < range_addr){
      if(item_memtrack->is_free){
        return false;
      }else{
        return true;
      }
    }
  }

  return false;
}

bool free_resolved_address_in_cntr(long address, bool is_null_valid){
  if(address == (long)NULL && is_null_valid){
    return false;
  }

  if(is_addr_a_invalid_free_in_cntr(address)){
    return true;
  }
  
  return false;
}