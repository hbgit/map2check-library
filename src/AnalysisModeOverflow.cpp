//===-- include/AnalysisModeOverflow.cpp - class definition -------*- C++
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
/// This file contains the declaration of the AnalysisModeOverflow.cpp class,
/// which execute programa analysis to check overflow operation in a given C
/// code.
///
//===----------------------------------------------------------------------===//

#include "../include/AnalysisModeOverflow.hpp"

#include <boost/variant/get.hpp>
#include <boost/variant/variant.hpp>
#include <climits>
#include <limits>

/// @brief SIGNED CHECK over Add operation:
/// Checks ADD (on two integers) operations and adds cases where operation
/// would fail.
/// @return bool check overflow
bool AnalysisModeOverflow::checkOverBinopAddInt() {

  /// based on Wietz Understanding Integer Overflow in C/C++
  /// ((s1 > 0) ∧ (s2 > 0) ∧ (s1 > (INT_MAX − s2 ))) ∨
  /// ((s1 < 0) ∧ (s2 < 0) ∧ (s1 < (INT_MIN − s2 )))

  if (boost::get<int>(this->ValueParam1) > 0 &&
      boost::get<int>(this->ValueParam2) > 0) {
    if (boost::get<int>(this->ValueParam1) >
        (INT_MAX - boost::get<int>(this->ValueParam2))) {
      return true;
    }
  } else if (boost::get<int>(this->ValueParam1) < 0 &&
             boost::get<int>(this->ValueParam2) < 0) {
    if (boost::get<int>(this->ValueParam1) <
        (INT_MIN - boost::get<int>(this->ValueParam2))) {
      return true;
    }
  }

  // Next check based on operation
  if ((boost::get<int>(this->ValueParam1) +
       boost::get<int>(this->ValueParam2)) > INT_MAX) {
    return true;
  } else if ((boost::get<int>(this->ValueParam1) +
              boost::get<int>(this->ValueParam2)) < INT_MIN) {
    return true;
  }

  return false;
}

bool AnalysisModeOverflow::checkOverBinopSubInt() {
  this->ValueParam2 = -boost::get<int>(this->ValueParam2);
  return this->checkOverBinopAddInt();
}

/// based on
/// https://wiki.sei.cmu.edu/confluence/display/c/INT32-C.+Ensure+that+operations+on+signed+integers+do+not+result+in+overflow
bool AnalysisModeOverflow::checkOverBinopMulInt() {

  signed int result;
  signed int si_a = boost::get<int>(this->ValueParam1);
  signed int si_b = boost::get<int>(this->ValueParam2);

  if (si_a > 0) {   /* si_a is positive */
    if (si_b > 0) { /* si_a and si_b are positive */
      if (si_a > (INT_MAX / si_b)) {
        /* Handle error */
        return true;
      }
    } else { /* si_a positive, si_b nonpositive */
      if (si_b < (INT_MIN / si_a)) {
        /* Handle error */
        return true;
      }
    }               /* si_a positive, si_b nonpositive */
  } else {          /* si_a is nonpositive */
    if (si_b > 0) { /* si_a is nonpositive, si_b is positive */
      if (si_a < (INT_MIN / si_b)) {
        /* Handle error */
        return true;
      }
    } else { /* si_a and si_b are nonpositive */
      if ((si_a != 0) && (si_b < (INT_MAX / si_a))) {
        /* Handle error */
        return true;
      }
    } /* End if si_a and si_b are nonpositive */
  }   /* End if si_a is nonpositive */

  // Next check based on operation
  if ((boost::get<int>(this->ValueParam1) *
       boost::get<int>(this->ValueParam2)) > INT_MAX) {
    return true;
  }
  return false;
}

/// based on
/// https://wiki.sei.cmu.edu/confluence/display/c/INT32-C.+Ensure+that+operations+on+signed+integers+do+not+result+in+overflow
bool AnalysisModeOverflow::checkOverBinopDivInt() {  
  signed int s_a = boost::get<int>(this->ValueParam1);
  signed int s_b = boost::get<int>(this->ValueParam2);
  if ((s_b == 0) || ((s_a == INT_MIN) && (s_b == -1))) {
    /* Handle error */
    return true;
  }

  return false;
}

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

/// based on
/// https://wiki.sei.cmu.edu/confluence/display/c/INT32-C.+Ensure+that+operations+on+signed+integers+do+not+result+in+overflow

#define PRECISION(umax_value) popcount(umax_value)
bool AnalysisModeOverflow::checkOverBinopShlInt() {
  signed long si_a = boost::get<int>(this->ValueParam1);
  signed long si_b = boost::get<int>(this->ValueParam2);
  if ((si_a < 0) || (si_b < 0) || (si_b >= PRECISION(ULONG_MAX)) ||
      (si_a > (LONG_MAX >> si_b))) {
    /* Handle error */
    return true;
  }
  return false;
}

/// based on
/// https://wiki.sei.cmu.edu/confluence/display/c/INT32-C.+Ensure+that+operations+on+signed+integers+do+not+result+in+overflow
/// The unary negation operator takes an operand of arithmetic type. Overflow
/// can occur during two's complement unary negation when the operand is equal
/// to the minimum (negative) value for the signed integer type.
bool AnalysisModeOverflow::checkOverBinopNegInt() {
  int s_a = boost::get<int>(this->ValueParam1);
  if (s_a == INT_MIN) {
    /* Handle error */
    return true;
  }

  return false;
}

// --------------------------------------------------------------
// Based on https://wiki.sei.cmu.edu/confluence/display/c/INT30-C.+Ensure+that+unsigned+integer+operations+do+not+wrap
// A computation involving unsigned operands can never overflow, because a result that cannot be represented by the resulting unsigned integer type is reduced modulo the number that is one greater than the largest value that can be represented by the resulting type.
// Unsigned operations

/// based on Cordeiro SMT-Based Bounded Model Checking for Embedded ANSI-C Software
/// l_unsigned_overflow <-> (r − (r mod 2^w )) < 2^w
bool AnalysisModeOverflow::checkOverBinopAddUint(){
    unsigned u_a = boost::get<unsigned>(this->ValueParam1);
    unsigned u_b = boost::get<unsigned>(this->ValueParam2);
    unsigned l_unsigned_overflow = ( (u_a+u_b) - ((u_a+u_b) % UINT_MAX));
    if( l_unsigned_overflow < UINT_MAX){
        return true;
    }

    if (UINT_MAX - u_a < u_b) {
        /* Handle error */
        return true;
    }else if ((u_a+u_b) < u_a) {
        /* Handle error */
        return true;
    }

    return false;
}


bool AnalysisModeOverflow::checkOverBinopSubUint(){
    unsigned u_a = boost::get<unsigned>(this->ValueParam1);
    unsigned u_b = boost::get<unsigned>(this->ValueParam2);
    unsigned l_unsigned_overflow = ( (u_a-u_b) - ((u_a-u_b) % UINT_MAX));
    if( l_unsigned_overflow < UINT_MAX){
        return true;
    }

    if (u_a < u_b){
        /* Handle error */
        return true;
    }else if ((u_a-u_b) > u_a) {
        /* Handle error */
        return true;
    }

    return false;

}


bool AnalysisModeOverflow::checkOverBinopMulUint(){
    unsigned u_a = boost::get<unsigned>(this->ValueParam1);
    unsigned u_b = boost::get<unsigned>(this->ValueParam2);
    unsigned l_unsigned_overflow = ( (u_a*u_b) - ((u_a*u_b) % UINT_MAX));
    if( l_unsigned_overflow < UINT_MAX){
        return true;
    }

    return false;
}


bool AnalysisModeOverflow::checkOverBinopDivUint(){
    unsigned u_a = boost::get<unsigned>(this->ValueParam1);
    unsigned u_b = boost::get<unsigned>(this->ValueParam2);
    unsigned l_unsigned_overflow = ( (u_a/u_b) - ((u_a/u_b) % UINT_MAX));
    if( l_unsigned_overflow < UINT_MAX){
        return true;
    }

    return false;
}


bool AnalysisModeOverflow::checkOverBinopShlUint(){
    unsigned u_a = boost::get<unsigned>(this->ValueParam1);
    unsigned u_b = boost::get<unsigned>(this->ValueParam2);
    unsigned l_unsigned_overflow = ( (u_a << u_b) - ((u_a << u_b) % UINT_MAX));
    if( l_unsigned_overflow < UINT_MAX){
        return true;
    }

    return false;
}