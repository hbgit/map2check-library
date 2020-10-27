/* ===----------- include/nondet/nondet.h - definition -------*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the declaration of the nondet object,
/// which performing the nondet object.
///
//===----------------------------------------------------------------------===//

#include "../../include/nondet/nondetlog.h"
#include "../../include/caller/caller_lib_result.h"
#include "../../lib/json-maker.h"

#include <bits/stdint-uintn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char * print_obj_as_json(non_det_log_t *obj) {

  // buff
  // Initial setting up to generate json
  char buff[512];
  char *dest = buff;

  dest = json_objOpen(dest, NULL);
  dest = json_long(dest, "step", obj->step);
  dest = json_int(dest, "line", obj->line);
  dest = json_int(dest, "scope", obj->scope);
  dest = json_str(dest, "function_name", obj->function_name);
  dest = json_int(dest, "type", obj->type_var);
  
  if (obj->type_var == INT_ID) {
    //uint32_t myInt1 = (uint8_t)obj.value.i[0] + (uint8_t)(obj.value.i[1] << 8) + (uint8_t)(obj.value.i[2] << 16) + (uint8_t)(obj.value.i[3] << 24);
    //int myInt1 = (int)obj.value.i[0] | ( (int)obj.value.i[1] << 8 ) | ( (int)obj.value.i[2] << 16 ) | ( (int)obj.value.i[3] << 24 );
    //int v = *(char *)obj.value.i;
    dest = json_int(dest, "value", *obj->value.i);
  } else if (obj->type_var == UNIT_ID) {
    dest = json_uint(dest, "value", *obj->value.u);
  } else if (obj->type_var == LONG_ID) {
    dest = json_long(dest, "value", *obj->value.l);
  } else if (obj->type_var == CHAR_ID) {
    const char * result = obj->value.c;
    dest = json_str(dest, "value", result);
  } else if (obj->type_var == FLOAT_ID) {
    dest = json_double(dest, "value", *obj->value.f);
  }else if (obj->type_var == DOUBLE_ID) {    
    dest = json_double(dest, "value", *obj->value.d);
  }

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
  //puts(buff);

  //const char *result = buff;
  //return result;
  char * r = malloc(sizeof(buff));
  strcpy(r, buff);
  return r;
}


non_det_log_t *map2check_save_nondet_log_int(int line, int scope,
                             enum var_type_t type_var, int *value,
                             const char *function_name) {

  non_det_log_t *obj = (non_det_log_t *)malloc(sizeof(non_det_log_t));
  
  obj->line = line;  
  obj->step = get_next_step();
  obj->scope = scope;
  obj->type_var = type_var;
  obj->value.i = value;
  obj->function_name = function_name;

  return obj;
}

non_det_log_t *map2check_save_nondet_log_uint(int line, int scope,
                             enum var_type_t type_var, unsigned int *value,
                             const char *function_name) {

  non_det_log_t *obj = (non_det_log_t *)malloc(sizeof(non_det_log_t));
  
  obj->line = line;
  obj->step = get_next_step();
  obj->scope = scope;
  obj->type_var = type_var;
  obj->value.u = value;
  obj->function_name = function_name;

  return obj;
}

non_det_log_t *map2check_save_nondet_log_long(int line, int scope,
                             enum var_type_t type_var, long *value,
                             const char *function_name) {

  non_det_log_t *obj = (non_det_log_t *)malloc(sizeof(non_det_log_t));
  
  obj->line = line;
  obj->step = get_next_step();
  obj->scope = scope;
  obj->type_var = type_var;
  obj->value.l = value;
  obj->function_name = function_name;

  return obj;
}

non_det_log_t *map2check_save_nondet_log_char(int line, int scope,
                             enum var_type_t type_var, char *value,
                             const char *function_name) {

  non_det_log_t *obj = (non_det_log_t *)malloc(sizeof(non_det_log_t));
  
  obj->line = line;
  obj->step = get_next_step();
  obj->scope = scope;
  obj->type_var = type_var;
  obj->value.c = value;
  obj->function_name = function_name;

  return obj;
}

non_det_log_t *map2check_save_nondet_log_float(int line, int scope,
                             enum var_type_t type_var, float *value,
                             const char *function_name) {

  non_det_log_t *obj = (non_det_log_t *)malloc(sizeof(non_det_log_t));
  
  obj->line = line;
  obj->step = get_next_step();
  obj->scope = scope;
  obj->type_var = type_var;
  obj->value.f = value;
  obj->function_name = function_name;

  return obj;
}


non_det_log_t *map2check_save_nondet_log_double(int line, int scope,
                             enum var_type_t type_var, double *value,
                             const char *function_name) {

  non_det_log_t *obj = (non_det_log_t *)malloc(sizeof(non_det_log_t));
  
  obj->line = line;
  obj->step = get_next_step();
  obj->scope = scope;
  obj->type_var = type_var;
  obj->value.d = value;
  obj->function_name = function_name;

  return obj;
}


