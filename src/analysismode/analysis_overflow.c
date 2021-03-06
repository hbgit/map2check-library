//===-- src/analysismode/analysis_overflow.c - class definition -------*- C
//-*-===//
//
// Copyright (C) 2014 - 2020 Map2Check tool
// This file is part of the Map2Check tool, and is made available under
// the terms of the GNU General Public License version 3.
//
// SPDX-License-Identifier: (GPL-3.0)
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file contains the declaration of the analysis_overflow.c, which
/// performs the programa analysis to validate overflow verification conditions
/// in the analyzed C code.
///
//===----------------------------------------------------------------------===//

#include "../../include/caller/caller_lib_result.h"

#include <limits.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

int debug_overflow = 1;

void debug_overflow_set_only_test() { debug_overflow = 0; }

// https://wiki.sei.cmu.edu/confluence/display/c/INT35-C.+Use+correct+integer+precisions
/* Returns the number of set bits */
// This compliant solution uses a popcount() function, which counts the number
// of bits set on any unsigned integer, allowing this code to determine the
// precision of any integer type, signed or unsigned.
size_t popcount(uintmax_t num) {
  size_t precision = 0;
  while (num != 0) {
    if (num % 2 == 1) {
      precision++;
    }
    num >>= 1;
  }
  return precision;
}

void vcc_nooverflow_failed(bool vcc_result, unsigned line, unsigned scope,
                           char *function_name) {
  if (vcc_result) {
    set_false_result(OVERFLOW, line, function_name);
    print_all_containers_as_json();
    if (debug_overflow) {
      abort();
    }
  }
}

// For int

/// @brief SIGNED CHECK over Add operation:
/// Checks ADD (on two integers) operations and adds cases where operation
/// would fail.
/// @return bool check overflow
void map2check_binop_add_int(int param1, int param2, unsigned line,
                             unsigned scope, char *function_name) {
  vcc_reset_meta_data();
  /// based on Wietz Understanding Integer Overflow in C/C++
  /// ((s1 > 0) ∧ (s2 > 0) ∧ (s1 > (INT_MAX − s2 ))) ∨
  /// ((s1 < 0) ∧ (s2 < 0) ∧ (s1 < (INT_MIN − s2 )))

  if (param1 > 0 && param2 > 0) {
    if (param1 > (INT_MAX - param2)) {
      vcc_nooverflow_failed(true, line, scope, function_name);
    }
  } else if (param1 < 0 && param2 < 0) {
    if (param1 < (INT_MIN - param2)) {
      vcc_nooverflow_failed(true, line, scope, function_name);
    }
  }

  // Next check based on operation
  if ((param1 + param2) > INT_MAX) {
    vcc_nooverflow_failed(true, line, scope, function_name);
  } else if ((param1 + param2) < INT_MIN) {
    vcc_nooverflow_failed(true, line, scope, function_name);
  }

  vcc_nooverflow_failed(false, line, scope, function_name);
}

void map2check_binop_sub_int(int param1, int param2, unsigned line,
                             unsigned scope, char *function_name) {
  vcc_reset_meta_data();
  param2 = -param2;
  map2check_binop_add_int(param1, param2, line, scope, function_name);
}

void map2check_binop_mul_int(int param1, int param2, unsigned line,
                             unsigned scope, char *function_name) {
  vcc_reset_meta_data();
  signed int result;
  signed int si_a = param1;
  signed int si_b = param2;

  if (si_a > 0) {   /* si_a is positive */
    if (si_b > 0) { /* si_a and si_b are positive */
      if (si_a > (INT_MAX / si_b)) {
        /* Handle error */
        vcc_nooverflow_failed(true, line, scope, function_name);
      }
    } else { /* si_a positive, si_b nonpositive */
      if (si_b < (INT_MIN / si_a)) {
        /* Handle error */
        vcc_nooverflow_failed(true, line, scope, function_name);
      }
    }               /* si_a positive, si_b nonpositive */
  } else {          /* si_a is nonpositive */
    if (si_b > 0) { /* si_a is nonpositive, si_b is positive */
      if (si_a < (INT_MIN / si_b)) {
        /* Handle error */
        vcc_nooverflow_failed(true, line, scope, function_name);
      }
    } else { /* si_a and si_b are nonpositive */
      if ((si_a != 0) && (si_b < (INT_MAX / si_a))) {
        /* Handle error */
        vcc_nooverflow_failed(true, line, scope, function_name);
      }
    } /* End if si_a and si_b are nonpositive */
  }   /* End if si_a is nonpositive */

  // Next check based on operation
  if ((param1 * param2) > INT_MAX) {
    vcc_nooverflow_failed(true, line, scope, function_name);
  }
  vcc_nooverflow_failed(false, line, scope, function_name);
}

/// based on
/// https://wiki.sei.cmu.edu/confluence/display/c/INT32-C.+Ensure+that+operations+on+signed+integers+do+not+result+in+overflow
void map2check_binop_div_int(int param1, int param2, unsigned line,
                             unsigned scope, char *function_name) {
  vcc_reset_meta_data();
  signed int s_a = param1;
  signed int s_b = param2;
  if ((s_b == 0) || ((s_a == INT_MIN) && (s_b == -1))) {
    /* Handle error */
    vcc_nooverflow_failed(true, line, scope, function_name);
  }

  vcc_nooverflow_failed(false, line, scope, function_name);
}

/// based on
/// https://wiki.sei.cmu.edu/confluence/display/c/INT32-C.+Ensure+that+operations+on+signed+integers+do+not+result+in+overflow
#define PRECISION(umax_value) popcount(umax_value)

void map2check_binop_shl_int(int param1, int param2, unsigned line,
                             unsigned scope, char *function_name) {
  vcc_reset_meta_data();
  signed int si_a = param1;
  signed int si_b = param2;
  if ((si_a < 0) || (si_b < 0) || (si_b >= PRECISION(UINT_MAX)) ||
      (si_a > (INT_MAX >> si_b))) {
    /* Handle error */
    vcc_nooverflow_failed(true, line, scope, function_name);
  } else if ((si_a << si_b) > INT_MAX) {
    vcc_nooverflow_failed(true, line, scope, function_name);
  }
  vcc_nooverflow_failed(false, line, scope, function_name);
}

void map2check_binop_shr_int(int param1, int param2, unsigned line,
                             unsigned scope, char *function_name) {
  vcc_reset_meta_data();
  signed int si_a = param1;
  signed int si_b = param2;

  if (si_b >= PRECISION(UINT_MAX)) {
    /* Handle error */
    vcc_nooverflow_failed(true, line, scope, function_name);
  } else if ((si_a << si_b) > INT_MAX) {
    vcc_nooverflow_failed(true, line, scope, function_name);
  }
  vcc_nooverflow_failed(false, line, scope, function_name);
}

/// based on
/// https://wiki.sei.cmu.edu/confluence/display/c/INT32-C.+Ensure+that+operations+on+signed+integers+do+not+result+in+overflow
/// The unary negation operator takes an operand of arithmetic type. Overflow
/// can occur during two's complement unary negation when the operand is equal
/// to the minimum (negative) value for the signed integer type.
void map2check_binop_neg_int(int param1, int param2, unsigned line,
                             unsigned scope, char *function_name) {
  vcc_reset_meta_data();
  int s_a = param1;
  if (s_a == INT_MIN) {
    /* Handle error */
    vcc_nooverflow_failed(true, line, scope, function_name);
  }

  vcc_nooverflow_failed(false, line, scope, function_name);
}

// For unsigned
// --------------------------------------------------------------
// Based on
// https://wiki.sei.cmu.edu/confluence/display/c/INT30-C.+Ensure+that+unsigned+integer+operations+do+not+wrap
// A computation involving unsigned operands can never overflow, because a
// result that cannot be represented by the resulting unsigned integer type is
// reduced modulo the number that is one greater than the largest value that can
// be represented by the resulting type. Unsigned operations

/// based on Cordeiro SMT-Based Bounded Model Checking for Embedded ANSI-C
/// Software l_unsigned_overflow <-> (r − (r mod 2^w )) < 2^w
void map2check_binop_add_unsigned(unsigned param1, unsigned param2,
                                  unsigned line, unsigned scope,
                                  char *function_name) {
  vcc_reset_meta_data();
  unsigned u_a = param1;
  unsigned u_b = param2;

  // cout << l_unsigned_overflow << endl;

  if (((u_a + u_b) - ((u_a + u_b) % UINT_MAX)) > UINT_MAX) {
    vcc_nooverflow_failed(true, line, scope, function_name);
  }

  if (UINT_MAX - u_a < u_b) {
    /* Handle error */
    vcc_nooverflow_failed(true, line, scope, function_name);
  } else if ((u_a + u_b) < u_a) {
    /* Handle error */
    vcc_nooverflow_failed(true, line, scope, function_name);
  }

  vcc_nooverflow_failed(false, line, scope, function_name);
}

void map2check_binop_sub_unsigned(unsigned param1, unsigned param2,
                                  unsigned line, unsigned scope,
                                  char *function_name) {
  vcc_reset_meta_data();
  unsigned u_a = param1;
  unsigned u_b = param2;
  // unsigned l_unsigned_overflow = ( (u_a-u_b) - ((u_a-u_b) % UINT_MAX));
  if (((u_a - u_b) - ((u_a - u_b) % UINT_MAX)) > UINT_MAX) {
    vcc_nooverflow_failed(true, line, scope, function_name);
  }

  if (u_a < u_b) {
    /* Handle error */
    vcc_nooverflow_failed(true, line, scope, function_name);
  } else if ((u_a - u_b) > u_a) {
    /* Handle error */
    vcc_nooverflow_failed(true, line, scope, function_name);
  }

  vcc_nooverflow_failed(false, line, scope, function_name);
}

/// https://wiki.sei.cmu.edu/confluence/display/c/INT30-C.+Ensure+that+unsigned+integer+operations+do+not+wrap
void map2check_binop_mul_unsigned(unsigned param1, unsigned param2,
                                  unsigned line, unsigned scope,
                                  char *function_name) {
  vcc_reset_meta_data();
  unsigned int u_a = param1;
  unsigned int u_b = param2;

  if (u_a > UINT_MAX / u_b) {
    vcc_nooverflow_failed(true, line, scope, function_name);
  }

  vcc_nooverflow_failed(false, line, scope, function_name);
}

void map2check_binop_div_unsigned(unsigned param1, unsigned param2,
                                  unsigned line, unsigned scope,
                                  char *function_name) {
  vcc_reset_meta_data();
  if (param2 == 0) {
    vcc_nooverflow_failed(true, line, scope, function_name);
  }

  vcc_nooverflow_failed(false, line, scope, function_name);
}

/// https://wiki.sei.cmu.edu/confluence/display/c/INT30-C.+Ensure+that+unsigned+integer+operations+do+not+wrap
void map2check_binop_shr_unsigned(unsigned param1, unsigned param2,
                                  unsigned line, unsigned scope,
                                  char *function_name) {
  vcc_reset_meta_data();
  if (!(param2 >= 0 && param2 < 32)) { // 32 bits
    vcc_nooverflow_failed(true, line, scope, function_name);
  }

  vcc_nooverflow_failed(false, line, scope, function_name);
}