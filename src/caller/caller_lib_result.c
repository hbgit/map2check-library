/* ===----------- src/caller/caller_lib_result.c - definition -------*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the declaration of the caller_lib_result object,
/// which performing the caller_lib_result object.
///
//===----------------------------------------------------------------------===//

#include "../../include/caller/caller_lib_result.h"
#include "../../include/bbtrack/container_trackbb.h"
#include "../../include/memtrack/container_memtracklog.h"
#include "../../include/nondet/container_nondet.h"

#include <stdio.h>
#include <stdlib.h>

caller_result_t caller_obj;
const char *ToEnum_ViolatedProperty[] = {"OVERFLOW",
                                         "MEMSAFETY_FREE",
                                         "MEMSAFETY_DEREF",
                                         "MEMSAFETY_MEMTRACK",
                                         "MEMSAFETY_MEMCLEANUP",
                                         "REACHABILITY",
                                         "CONCURRENCY",
                                         "NONE"};

void map2check_init() {
  // Initialize object
  caller_obj.current_step = 0;
  caller_obj.function_name = "NONE";
  caller_obj.line_number = -1;
  caller_obj.verification_result = false;
  caller_obj.violated_property = NONE;
}

void map2check_success() {
  caller_obj.verification_result = true;
  print_all_containers_as_json();
  //abort();
}

void next_current_step() { caller_obj.current_step += 1; }

long get_current_step() { return caller_obj.current_step; }

void set_false_result(enum violated_property_t prp, int line_number,
                      const char *function_name) {
  caller_obj.violated_property = prp;
  caller_obj.function_name = function_name;
  caller_obj.line_number = line_number;
}

enum violated_property_t get_current_property(){
  return caller_obj.violated_property;
}

void print_all_containers_as_json() {
  printf("{%s", "\"map2check_log\":{");

  // print TRUE or FALSE
  if (caller_obj.verification_result) {
    printf("\"result\":\"TRUE\",");
  } else {
    printf("\"result\":\"FALSE\",");
    // print violated property
    printf("\"property\":\"%s\",",
           ToEnum_ViolatedProperty[caller_obj.violated_property]);
    printf("\"line_number\":%d,", caller_obj.line_number);
  }

  map2check_print_all_trackbblog_as_json();
  printf(",");

  if (caller_obj.violated_property == MEMSAFETY_FREE ||
      caller_obj.violated_property == MEMSAFETY_DEREF ||
      caller_obj.violated_property == MEMSAFETY_MEMTRACK ||
      caller_obj.violated_property == MEMSAFETY_MEMCLEANUP) {
    map2check_print_all_memtracklog_as_json();
    printf(",");
  }

  map2check_print_all_nondetlog_as_json();

  printf("}}\n");
}