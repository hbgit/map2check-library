/* ===----------- include/bbtrack/trackbblog.h - definition -------*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the declaration of the trackbblog object,
/// which modelling the trackbblog object.
///
//===----------------------------------------------------------------------===//

#ifndef __TRACKBBLOG_H_INCLUDED__
#define __TRACKBBLOG_H_INCLUDED__

#include <sys/queue.h>

typedef struct _bbtrack_log {
  TAILQ_ENTRY(_bbtrack_log) pointers;
  long step;
  int line;
  const char *function_name;

} bbtrack_log_t;

char *print_trackbb_as_json(bbtrack_log_t *obj);

bbtrack_log_t *map2check_save_basic_block_log(long step, int line,
                                              const char *function_name);

#endif // __TRACKBBLOG_H_INCLUDED__