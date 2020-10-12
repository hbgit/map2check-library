/* ===----------- include/nondet/nondet.h - definition -------*- C -*-===

 Copyright (C) 2014 - 2020 Map2Check tool
 This file is part of the Map2Check tool, and is made available under
 the terms of the GNU General Public License version 3.

 SPDX-License-Identifier: (GPL-3.0)

===----------------------------------------------------------------------=== */
///
/// \file
/// This file contains the declaration of the nondet object,
/// which performing the nondet object.
///
//===----------------------------------------------------------------------===//

#include "../../include/nondet/nondetlog.h"
#include "../../lib/json-maker.h"

#include <bits/stdint-uintn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

const char *print_obj_as_json(non_det_log_t obj) {

  // buff
  // Initial setting up to generate json
  char buff[512];
  char *dest = buff;

  dest = json_objOpen(dest, NULL);
  dest = json_long(dest, "step", obj.step);
  dest = json_int(dest, "line", obj.line);
  dest = json_int(dest, "scope", obj.scope);
  dest = json_str(dest, "function_name", obj.function_name);
  dest = json_int(dest, "type", obj.type_var);
  
  if (obj.type_var == INT_ID) {
    //uint32_t myInt1 = (uint8_t)obj.value.i[0] + (uint8_t)(obj.value.i[1] << 8) + (uint8_t)(obj.value.i[2] << 16) + (uint8_t)(obj.value.i[3] << 24);
    //int myInt1 = (int)obj.value.i[0] | ( (int)obj.value.i[1] << 8 ) | ( (int)obj.value.i[2] << 16 ) | ( (int)obj.value.i[3] << 24 );
    //int v = *(char *)obj.value.i;
    dest = json_int(dest, "value", *(char *)obj.value.i);
  } else if (obj.type_var == UNIT_ID) {
    dest = json_uint(dest, "value", *obj.value.u);
  } else if (obj.type_var == LONG_ID) {
    dest = json_long(dest, "value", *obj.value.l);
  } else if (obj.type_var == CHAR_ID) {
    const char * result = obj.value.c;
    dest = json_str(dest, "value", result);
  } else if (obj.type_var == FLOAT_ID) {
    dest = json_double(dest, "value", *obj.value.f);
  }else if (obj.type_var == DOUBLE_ID) {    
    dest = json_double(dest, "value", *obj.value.d);
  }

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
  puts(buff);

  FILE *fp;
  fp = fopen("result_map2check_json.json", "w+");
  fputs(buff, fp);
  //fprintf(fp,"%s",buff);
  fclose(fp);

  const char *result = buff;
  return result;
}


non_det_log_t *map2check_save_nondet_log_int(long step, int line, int scope,
                             enum var_type_t type_var, int *value,
                             const char *function_name) {

  non_det_log_t *obj = (non_det_log_t *)malloc(sizeof(non_det_log_t));
  
  obj->line = line;
  obj->step = step;
  obj->scope = scope;
  obj->type_var = type_var;
  obj->value.i = value;
  obj->function_name = function_name;

  return obj;
}

non_det_log_t *map2check_save_nondet_log_uint(long step, int line, int scope,
                             enum var_type_t type_var, unsigned int *value,
                             const char *function_name) {

  non_det_log_t *obj = (non_det_log_t *)malloc(sizeof(non_det_log_t));
  
  obj->line = line;
  obj->step = step;
  obj->scope = scope;
  obj->type_var = type_var;
  obj->value.u = value;
  obj->function_name = function_name;

  return obj;
}

non_det_log_t *map2check_save_nondet_log_long(long step, int line, int scope,
                             enum var_type_t type_var, long *value,
                             const char *function_name) {

  non_det_log_t *obj = (non_det_log_t *)malloc(sizeof(non_det_log_t));
  
  obj->line = line;
  obj->step = step;
  obj->scope = scope;
  obj->type_var = type_var;
  obj->value.l = value;
  obj->function_name = function_name;

  return obj;
}

non_det_log_t *map2check_save_nondet_log_char(long step, int line, int scope,
                             enum var_type_t type_var, char *value,
                             const char *function_name) {

  non_det_log_t *obj = (non_det_log_t *)malloc(sizeof(non_det_log_t));
  
  obj->line = line;
  obj->step = step;
  obj->scope = scope;
  obj->type_var = type_var;
  obj->value.c = value;
  obj->function_name = function_name;

  return obj;
}

non_det_log_t *map2check_save_nondet_log_float(long step, int line, int scope,
                             enum var_type_t type_var, float *value,
                             const char *function_name) {

  non_det_log_t *obj = (non_det_log_t *)malloc(sizeof(non_det_log_t));
  
  obj->line = line;
  obj->step = step;
  obj->scope = scope;
  obj->type_var = type_var;
  obj->value.f = value;
  obj->function_name = function_name;

  return obj;
}


non_det_log_t *map2check_save_nondet_log_double(long step, int line, int scope,
                             enum var_type_t type_var, double *value,
                             const char *function_name) {

  non_det_log_t *obj = (non_det_log_t *)malloc(sizeof(non_det_log_t));
  
  obj->line = line;
  obj->step = step;
  obj->scope = scope;
  obj->type_var = type_var;
  obj->value.d = value;
  obj->function_name = function_name;

  return obj;
}



// const char *map2check_convert_double_to_string(double d) {
//   char buffer[255];
//   // //int status;
//   // // itoa (d,buffer,2);
//   // //atof(d, buffer, 2);

//   // // double e float
//   // int decimal, sign;
//   // //
//   // https://www.codecogs.com/library/computing/c/stdlib.h/ecvt.php?alias=fcvt
//   // char *buffer = ecvt(d, 11, &decimal, &sign);
//   // //printf("string: %c\n", buffer[0]);
//   // //printf("pi = %c.%s\n", buffer[0], buffer + 1);
//   // //char * t = buffer[0];

//   // const char * result = strcat(strcat((buffer+0), "."), buffer + 1);
//   // printf("string: %s\n", result);

//   // // Convert string to value
//   // //https://www.codecogs.com/library/computing/c/stdlib.h/atol.php
//   // //https://www.ibm.com/support/knowledgecenter/SSLTBW_2.2.0/com.ibm.zos.v2r2.bpxbd00/strtod.htm

//   // //printf("\n");
//   const char *result = ftoa(d, buffer, 3);
//   printf("string: %s\n", result);
//   return result;
// }

// const char *map2check_convert_float_to_string(float d) {
//   return map2check_convert_double_to_string(d);
// }

// /* reverse:  reverse string s in place */
// void reverse(char s[]) {
//   int i, j;
//   char c;

//   for (i = 0, j = strlen(s) - 1; i < j; i++, j--) {
//     c = s[i];
//     s[i] = s[j];
//     s[j] = c;
//   }
// }

// // https://en.wikibooks.org/wiki/C_Programming/stdlib.h/itoa
// const char *map2check_convert_int_to_string(int n) {
//   char s[255];
//   int i, sign;

//   if ((sign = n) < 0) /* record sign */
//     n = -n;           /* make n positive */
//   i = 0;
//   do {                     /* generate digits in reverse order */
//     s[i++] = n % 10 + '0'; /* get next digit */
//   } while ((n /= 10) > 0); /* delete it */
//   if (sign < 0)
//     s[i++] = '-';
//   s[i] = '\0';
//   reverse(s);

//   const char *result = s;
//   //printf("string: %s\n", result);
//   return result; 
// }
