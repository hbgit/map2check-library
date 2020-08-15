#include "../include/Nondetlog.hpp"

#include "gtest/gtest.h"

TEST(Model, NonDetLog)
{
    NonDetLog nondet;
    nondet.Line = 12;
    EXPECT_EQ (nondet.Line, 12);
    /*nondet.Scope = 0;
    EXPECT_EQ (nondet.Scope, 0);
    nondet.Value = 7;
    EXPECT_EQ (nondet.Value, 7);   
    EXPECT_EQ (nondet.getTypeValue(nondet.Value), "int");   
    nondet.FunctionName = "test";
    EXPECT_EQ (nondet.FunctionName, "test"); */      
}