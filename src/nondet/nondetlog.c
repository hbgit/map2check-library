/**
 * Copyright (C) 2014 - 2020 Map2Check tool
 * This file is part of the Map2Check tool, and is made available under
 * the terms of the GNU General Public License version 3.
 *
 * SPDX-License-Identifier: (GPL-3.0)
 *
 * Abstract: This file has NonDetLog object model.
 **/

 #include "../../include/nondet/nondetlog.h"

 const char *print_obj_as_json(non_det_log_t obj) { 
    
    int a;
    if(obj.type_var == INT_ID){
        a = *(int*) obj.value;
    }
    return "asd"; 
}