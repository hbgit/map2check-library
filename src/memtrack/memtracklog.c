/* ===----------- src/memtrack/memtracklog.c - definition -------*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the declaration of the memtracklog object,
/// which performing the memtracklog object.
///
//===----------------------------------------------------------------------===//

#include "../../include/memtrack/memtracklog.h"
#include "../../include/caller/caller_lib_result.h"
#include "../../lib/json-maker.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char *print_memtrack_obj_as_json(memtrack_log_t *obj) {
  char buff[1024];
  char *dest = buff;

  dest = json_objOpen(dest, NULL);
  dest = json_long(dest, "step", obj->step);
  dest = json_int(dest, "line", obj->line);
  dest = json_int(dest, "scope", obj->scope);
  dest = json_long(dest, "var_mem_address", obj->var_mem_address);
  dest = json_long(dest, "mem_address_points_to", obj->mem_address_points_to);
  dest = json_int(dest, "is_dynamic", obj->is_dynamic);
  dest = json_int(dest, "is_free", obj->is_free);
  dest = json_str(dest, "ptr_name", obj->ptr_name);
  dest = json_str(dest, "function_name", obj->function_name);
  dest = json_int(dest, "size_destiny", obj->size_destiny);
  dest = json_int(dest, "size_primitive", obj->size_primitive);
  dest = json_int(dest, "is_null_valid", obj->is_null_valid);
  dest = json_int(dest, "mem_type_track", obj->type_track);

  // Close json and check generation
  dest = json_objClose(dest);
  char *p;
  p = json_end(dest);

  int len = (int)(size_t)(p - dest);

  if (len >= (int)(size_t)sizeof(buff)) {
    fprintf(stderr, "%s%d%s%d\n", "Error. Len: ", len,
            " Max: ", (int)sizeof buff - 1);
    exit(1);
  }

  char *r = malloc(sizeof(buff));
  strcpy(r, buff);
  return r;
}

memtrack_log_t *
map2check_save_memtrack_log(int line, int scope,
                            long var_mem_address, long mem_address_points_to,
                            bool is_dynamic, bool is_free, const char *ptr_name,
                            const char *function_name, int size_destiny,
                            int size_primitive, bool is_null_valid, mem_type_track type_track) {

  memtrack_log_t *obj = (memtrack_log_t *)malloc(sizeof(memtrack_log_t));

  obj->line = line;
  obj->step = get_next_step();
  obj->scope = scope;
  obj->var_mem_address = var_mem_address;
  obj->mem_address_points_to = mem_address_points_to;
  obj->is_dynamic = is_dynamic;
  obj->is_free = is_free;
  obj->ptr_name = ptr_name;
  obj->function_name = function_name;
  obj->size_destiny = size_destiny;
  obj->size_primitive = size_primitive;
  obj->is_null_valid = is_null_valid;
  obj->type_track = type_track;

  return obj;
}

bool is_equal_memtrack_obj(memtrack_log_t *obj1, memtrack_log_t *obj2) {

  if (obj1->var_mem_address == obj2->var_mem_address &&
      obj1->mem_address_points_to == obj2->mem_address_points_to &&
      obj1->scope == obj2->scope && obj1->is_dynamic == obj2->is_dynamic &&
      obj1->is_free == obj2->is_free && obj1->line == obj2->line) {
    return true;
  }

  return false;
}


void set_malloc(memtrack_log_t *obj) {
  if (obj->var_mem_address != 0) {
    obj->is_free = false;
    obj->is_dynamic = true;
  } else {
    obj->is_free = false;
    obj->is_dynamic = true;
  }

  obj->step = ++obj->step;
}

void set_calloc(int quantity, memtrack_log_t *obj){
  obj->size_destiny = quantity * obj->size_destiny;
  set_malloc(obj);
}

// NOTE: realloc is modelling by set free and then execute a new malloc
void set_free(memtrack_log_t *obj){
  if(obj->var_mem_address == (long)NULL && obj->is_null_valid){
    return;
  }

  obj->size_destiny = 0;
  obj->is_free = true;
  obj->is_dynamic = false;
  obj->step = ++obj->step;
}
