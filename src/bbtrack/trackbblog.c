/* ===----------- include/bbtrack/trackbblog.c - definition -------*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the declaration of the trackbblog object,
/// which performing the trackbblog object actions.
///
//===----------------------------------------------------------------------===//

#include "../../include/bbtrack/trackbblog.h"
#include "../../lib/json-maker.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/queue.h>

char *print_trackbb_as_json(bbtrack_log_t *obj) {

  // buff
  // Initial setting up to generate json
  char buff[512];
  char *dest = buff;

  dest = json_objOpen(dest, NULL);
  dest = json_long(dest, "step", obj->step);
  dest = json_int(dest, "line", obj->line);
  dest = json_str(dest, "function_name", obj->function_name);

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
  // puts(buff);

  // const char *result = buff;
  // return result;
  char *r = malloc(sizeof(buff));
  strcpy(r, buff);
  return r;
}

bbtrack_log_t *map2check_save_basic_block_log(long step, int line,
                                              const char *function_name) {
  bbtrack_log_t *obj = (bbtrack_log_t *)malloc(sizeof(bbtrack_log_t));

  obj->line = line;
  obj->step = step;
  obj->function_name = function_name;

  return obj;
}