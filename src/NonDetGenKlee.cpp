//===-- include/NonDetGenKlee.cpp - class definition -------*- C++ -*-===//
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
/// This file contains the NonDetGenKlee.cpp class, which 
/// modelling the generation of nondet values using KLEE.
///
//===----------------------------------------------------------------------===//

#include "../include/NonDetGenKlee.hpp"
#include <cstdlib>
#include <string>

using namespace std;

// This to avoid that Clang mangles the name https://groups.google.com/g/llvm-dev/c/31ImqM_DVIs?pli=1
// https://en.wikipedia.org/wiki/Name_mangling#Name_mangling_in_C.2B.2B
//extern "C" int __map2check_main__();
extern "C" void klee_assume(int);
extern "C" void klee_make_symbolic(void *addr, size_t nbytes, const char *name);

void kleeNondetAssume(int Expr){
    klee_assume(Expr);
}


template <typename T>
T genericKleeNonDetGen(){
    T non_det;
    
    /*string NameDefault = "non_det_";
    string IdTypeVar = typeid(T).name();
    NameDefault += IdTypeVar;
    const char *FullName = NameDefault.c_str();*/
    
    klee_make_symbolic(&non_det, sizeof(non_det), "non_det_");
    return non_det;  
}

// Here is the explicit instanciation
template bool genericKleeNonDetGen(); 
template char genericKleeNonDetGen(); 
template short genericKleeNonDetGen(); 
template unsigned genericKleeNonDetGen(); 
template int genericKleeNonDetGen(); 
template char * genericKleeNonDetGen(); 
template long genericKleeNonDetGen(); 
template unsigned long genericKleeNonDetGen(); 
template unsigned short genericKleeNonDetGen(); 
template float genericKleeNonDetGen(); 
template double genericKleeNonDetGen(); 
