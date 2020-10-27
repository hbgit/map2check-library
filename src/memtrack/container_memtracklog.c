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