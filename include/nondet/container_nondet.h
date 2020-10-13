/* ===----------- include/container_nondet.h - definition -------*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the declaration of the Container to the nondet object,  
/// which modelling the Container to storage a list with nondet objects.
///
//===----------------------------------------------------------------------===//

#ifndef __CONTAINERNONDETLOG_H_INCLUDED__
#define __CONTAINERNONDETLOG_H_INCLUDED__

#include <sys/queue.h>

#include "nondetlog.h"

TAILQ_HEAD(nondet_list, _non_det_log);
struct nondet_list container_nondets;

//for TAILQ_INIT(&container_nondet);
void map2check_init_container_nondet();

void map2check_save_in_tail_container_nondet(non_det_log_t * objnondet);

void map2check_print_all_nondetlog_as_json();



#endif // __CONTAINERNONDETLOG_H_INCLUDED__ 