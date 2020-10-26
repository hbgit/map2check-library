/* ===----------- include/caller/caller_lib_result.h - definition -------*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the declaration of the caller_lib_result object,
/// which modelling the caller_lib_result object.
///
//===----------------------------------------------------------------------===//

#ifndef __CALLERLIBRESULT_H_INCLUDED__
#define __CALLERLIBRESULT_H_INCLUDED__

#include <stdbool.h>

enum violated_property_t {
  OVERFLOW,
  MEMSAFETY_FREE,
  MEMSAFETY_DEREF,
  MEMSAFETY_MEMTRACK,
  MEMSAFETY_MEMCLEANUP,
  REACHABILITY,
  CONCURRENCY,
  NONE
};


typedef struct _caller_result {
  long current_step;
  int line_number;
  const char *function_name;
  // UNKNOWN is checked outside from library, in this case we have a chrash
  bool verification_result; 
  enum violated_property_t violated_property;
} caller_result_t;

void map2check_init();

void map2check_success();

void next_current_step();

long get_current_step();

void set_false_result(enum violated_property_t prp, int line_number, const char *function_name);

enum violated_property_t get_current_property();

void print_all_containers_as_json();

#endif // __CALLERLIBRESULT_H_INCLUDED__