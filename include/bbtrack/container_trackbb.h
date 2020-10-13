/* ===----------- include/bbtrack/container_trackbb.h - definition -------*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the declaration of the Container to the trackbb object,  
/// which performing the Container to storage a list with trackbb objects.
///
//===----------------------------------------------------------------------===//

#ifndef __CONTAINERTRACKBBLOG_H_INCLUDED__
#define __CONTAINERTRACKBBLOG_H_INCLUDED__

#include <sys/queue.h>

#include "trackbblog.h"

TAILQ_HEAD(trackbb_list, _bbtrack_log);
struct trackbb_list container_trackbbs;

//for TAILQ_INIT(&container_nondet);
void map2check_init_container_trackbb();

void map2check_save_in_tail_container_trackbb(bbtrack_log_t * objtrackbb);

int map2check_is_in_trackbb_container(int line_to_check);

void map2check_print_all_trackbblog_as_json();



#endif // __CONTAINERTRACKBBLOG_H_INCLUDED__ 