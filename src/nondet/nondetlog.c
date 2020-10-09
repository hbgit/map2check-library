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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

const char *print_obj_as_json(non_det_log_t obj) {

  int a;
  if (obj.type_var == INT_ID) {
    a = (int)(size_t)obj.value;
    printf("a = %d \n", a);
  }
  return "asd";
}

non_det_log_t *create_nondet(long step, int line, int scope,
                             enum var_type_t type_var, void *value,
                             char function_name) {

  non_det_log_t *obj = (non_det_log_t *)malloc(sizeof(non_det_log_t));
  //strcpy(obj->function_name, function_name);
  //obj->function_name = (const char *)"foo";
  obj->line = line;
  obj->step = step;
  obj->scope = scope;
  obj->type_var = type_var;
  obj->value = value;

  return obj;
}