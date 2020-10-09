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
#include "../../include/nondet/nondetlog.h"
#include "../../include/nondet/container_nondet.h"

#include <sys/queue.h>
#include <stdlib.h>
#include <stdio.h>



//TAILQ_HEAD(nondet_list, _non_det_log);
//struct nondet_list container_nondet;

//struct nondet_list container_nondets;
//TAILQ_HEAD(nondet_list, _non_det_log);



//for TAILQ_INIT(&container_nondet);
void init_container_nondet(){
    //container_nondets.tqh_last
    //struct nondet_list container_nondets;
    TAILQ_INIT(&container_nondets);
    printf("IO \n");
}

void insert_tail_container_nondet(non_det_log_t *objnondet){
    TAILQ_INSERT_TAIL(&container_nondets, objnondet, pointers);
}

const char * print_all_nondet_as_json(){
    non_det_log_t * tmp_nondet;

    TAILQ_FOREACH(tmp_nondet, &container_nondets, pointers){
        printf("LINE = %d \n", tmp_nondet->line);        
    }

    return "asd";
}
