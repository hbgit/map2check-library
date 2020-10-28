//===-- include/analysismode/analysis_assert.h - class definition -------*- C -*-===//
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
/// This file contains the declaration of the analysis_assert.h class, which 
/// modelling the programa analysis to validate an given assert in the C code.
///
//===----------------------------------------------------------------------===//

#ifndef __ANALYSISMODEASSERT_H_INCLUDED__
#define __ANALYSISMODEASSERT_H_INCLUDED__

void debug_assert_set_only_test();

void map2check_is_valid_assert(int line_number, const char *function_name, int Expression);

#endif // __ANALYSISMODEASSERT_H_INCLUDED__ 