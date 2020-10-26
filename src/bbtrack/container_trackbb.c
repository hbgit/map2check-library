/* ===----------- src/bbtrack/container_trackbb.c - definition -------*- C -*-===

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

#include <sys/queue.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "../../include/bbtrack/trackbblog.h"
#include "../../include/bbtrack/container_trackbb.h"


void map2check_init_container_trackbb(){
    TAILQ_INIT(&container_trackbbs);
}

void map2check_save_in_tail_container_trackbb(bbtrack_log_t *objtrackbb){
    TAILQ_INSERT_TAIL(&container_trackbbs, objtrackbb, pointers); 
}

int map2check_is_in_trackbb_container(int line_to_check){
    bbtrack_log_t * tmp_trackbb;

    TAILQ_FOREACH(tmp_trackbb, &container_trackbbs, pointers){        
        
       if(tmp_trackbb->line == line_to_check){
           return 1;
       }

    }
    return 0;
}

void map2check_print_all_trackbblog_as_json(){
    bbtrack_log_t * tmp_trackbb;

    printf("%s", "\"container_trackbb_log\":[");
    TAILQ_FOREACH(tmp_trackbb, &container_trackbbs, pointers){        
        
        printf("%s", print_trackbb_as_json(tmp_trackbb));
        if(tmp_trackbb->pointers.tqe_next != NULL){
            printf(",");
        }

    }

    printf("]");
}