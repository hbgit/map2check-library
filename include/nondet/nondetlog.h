/* ===----------- include/nondet/nondet.h - definition -------*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the declaration of the nondet object,  
/// which modelling the nondet object.
///
//===----------------------------------------------------------------------===//


#ifndef __NONDETLOG_H_INCLUDED__
#define __NONDETLOG_H_INCLUDED__

#include <sys/queue.h>

enum var_type_t { INT_ID, UNIT_ID, LONG_ID, CHAR_ID, DOUBLE_ID, FLOAT_ID };

/**
 * @brief Modelling the object to store the data from
 * nondet function calls in the program analysis.
 */

typedef struct _non_det_log {
  TAILQ_ENTRY(_non_det_log) pointers;
  long step;
  int line;
  int scope;
  enum var_type_t type_var;
  void *value;
  char function_name[255];
  
} non_det_log_t;

const char *print_obj_as_json(non_det_log_t obj);

non_det_log_t * create_nondet(long step,
  int line,
  int scope,
  enum var_type_t type_var,
  void *value,
  char function_name);

#endif // __NONDETLOG_H_INCLUDED__