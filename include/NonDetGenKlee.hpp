//===-- include/NonDetGenKlee.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the NonDetGenKlee.hpp class, which 
/// modelling the generation of nondet values using KLEE.
///
//===----------------------------------------------------------------------===//

#ifndef __NONDETGENKLEE_H_INCLUDED__
#define __NONDETGENKLEE_H_INCLUDED__

#include <stdint.h>
#include <cstdint>
#include <string>

using namespace std;

void kleeNondetAssume(int Expr);

template <typename T>
T genericKleeNonDetGen();

#endif // __NONDETGENKLEE_H_INCLUDED__ 