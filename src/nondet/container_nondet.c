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

#include <string.h>
#include <sys/queue.h>
#include <stdlib.h>
#include <stdio.h>



//TAILQ_HEAD(nondet_list, _non_det_log);
//struct nondet_list container_nondet;

//struct nondet_list container_nondets;
//TAILQ_HEAD(nondet_list, _non_det_log);



//for TAILQ_INIT(&container_nondet);
void map2check_init_container_nondet(){
    //container_nondets.tqh_last
    //struct nondet_list container_nondets;
    TAILQ_INIT(&container_nondets);
    //printf("IO \n");
}

void map2check_save_in_tail_container_nondet(non_det_log_t *objnondet){
    TAILQ_INSERT_TAIL(&container_nondets, objnondet, pointers);
}

void map2check_print_all_nondetlog_as_json(){
    non_det_log_t * tmp_nondet;

    // We avoid to save into char cuz the allocation size
    
    //char * result = (char *)malloc(sizeof(char)*512); // 512 number of char
    //strcpy(result, "\"container_nondet_log\":[");
    //FILE *fp;
    //fp = fopen("result_map2check_json.json", "w+");
    //fputs("\"container_nondet_log\":[", fp);
    //int count = 1;

    printf("%s", "\"container_nondet_log\":[");

    TAILQ_FOREACH(tmp_nondet, &container_nondets, pointers){        
        // printf(">>> %s\n", print_obj_as_json(tmp_nondet));        
        //fputs(print_obj_as_json(tmp_nondet), fp);
        //strcat(result, print_obj_as_json(tmp_nondet));
        //strcat(result, );
        printf("%s", print_obj_as_json(tmp_nondet));
        if(tmp_nondet->pointers.tqe_next != NULL){
            printf(",");
        }
    }

    printf("]");

    //fputs("]", fp);
    //fclose(fp);
}
