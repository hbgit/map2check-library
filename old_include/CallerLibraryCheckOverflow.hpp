//===-- include/CallerLibraryCheckOverflow.hpp - class definition -------*- C++
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
/// This file contains the declaration of the CallerLibraryCheckOverflow.hpp
/// class, which modelling the programa analysis to validate overflow
/// verification condition by map2check tool.
///
//===----------------------------------------------------------------------===//

#include "../include/CallerLibraryResult.hpp"
#include "../include/AnalysisModeOverflow.hpp"


// For int
extern "C" void map2check_binop_add_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name);

extern "C" void map2check_binop_sub_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name);

extern "C" void map2check_binop_mul_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name);

extern "C" void map2check_binop_div_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name);

extern "C" void map2check_binop_shl_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name);

extern "C" void map2check_binop_shr_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name);

extern "C" void map2check_binop_neg_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name);

// For unsigned
extern "C" void map2check_binop_add_unsigned(unsigned param1, unsigned param2,
                                             unsigned line, unsigned scope,
                                             char *function_name);

extern "C" void map2check_binop_sub_unsigned(unsigned param1, unsigned param2,
                                             unsigned line, unsigned scope,
                                             char *function_name);

extern "C" void map2check_binop_mul_unsigned(unsigned param1, unsigned param2,
                                             unsigned line, unsigned scope,
                                             char *function_name);

extern "C" void map2check_binop_div_unsigned(unsigned param1, unsigned param2,
                                             unsigned line, unsigned scope,
                                             char *function_name);

extern "C" void map2check_binop_shr_unsigned(unsigned param1, unsigned param2,
                                             unsigned line, unsigned scope,
                                             char *function_name);