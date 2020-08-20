#include "../include/Nondetlog.hpp"

#include "gtest/gtest.h"
#include <boost/integer_fwd.hpp>
#include <boost/variant/get.hpp>
#include <boost/variant.hpp>
#include <iostream>
#include <limits>

TEST(NonDetLog, NonDetLog_int)
{
    NonDetLog nondet;
    nondet.Line = 12;
    EXPECT_EQ(nondet.Line, 12);
    nondet.Scope = 0;
    EXPECT_EQ(nondet.Scope, 0);
    nondet.Value = INT_MAX;
    EXPECT_TRUE(boost::get<int>(nondet.Value) == INT_MAX);   
    EXPECT_EQ (nondet.getTypeValue(nondet.Value), "int");   
    nondet.FunctionName = "test";
    EXPECT_EQ (nondet.FunctionName, "test");
}

TEST(NonDetLog, NonDetLog_double)
{
    NonDetLog nondet;
    nondet.Line = 1;
    EXPECT_EQ(nondet.Line, 1);
    nondet.Scope = 0;
    EXPECT_EQ(nondet.Scope, 0);
    nondet.Value = std::numeric_limits<double>::max();
    EXPECT_TRUE(boost::get<double>(nondet.Value) == std::numeric_limits<double>::max());   
    EXPECT_EQ (nondet.getTypeValue(nondet.Value), "double");   
    nondet.FunctionName = "test";
    EXPECT_EQ (nondet.FunctionName, "test");
}

TEST(NonDetLog, NonDetLog_float)
{
    NonDetLog nondet;
    nondet.Line = 1;
    EXPECT_EQ(nondet.Line, 1);
    nondet.Scope = 0;
    EXPECT_EQ(nondet.Scope, 0);
    nondet.Value = std::numeric_limits<float>::max();
    EXPECT_TRUE(boost::get<float>(nondet.Value) == std::numeric_limits<float>::max());   
    EXPECT_EQ (nondet.getTypeValue(nondet.Value), "float");   
    nondet.FunctionName = "test";
    EXPECT_EQ (nondet.FunctionName, "test");
}

TEST(NonDetLog, NonDetLog_char)
{
    NonDetLog nondet;
    nondet.Line = 1;
    EXPECT_EQ(nondet.Line, 1);
    nondet.Scope = 0;
    EXPECT_EQ(nondet.Scope, 0);
    nondet.Value = std::numeric_limits<char>::max();
    EXPECT_TRUE(boost::get<char>(nondet.Value) == std::numeric_limits<char>::max());   
    //EXPECT_EQ (nondet.getTypeValue(nondet.Value), "unsigned");   
    nondet.FunctionName = "test";
    EXPECT_EQ (nondet.FunctionName, "test");
}

TEST(NonDetLog, NonDetLog_unsigned)
{
    NonDetLog nondet;
    nondet.Line = 1;
    EXPECT_EQ(nondet.Line, 1);
    nondet.Scope = 0;
    EXPECT_EQ(nondet.Scope, 0);
    unsigned k = std::numeric_limits<unsigned>::max();
    nondet.Value = k;
    EXPECT_TRUE(boost::get<unsigned>(nondet.Value) == k);   
    EXPECT_EQ (nondet.getTypeValue(nondet.Value), "unsigned");   
    nondet.FunctionName = "test";
    EXPECT_EQ (nondet.FunctionName, "test");
}

TEST(NonDetLog, NonDetLog_long)
{
    NonDetLog nondet;
    nondet.Line = 1;
    EXPECT_EQ(nondet.Line, 1);
    nondet.Scope = 0;
    EXPECT_EQ(nondet.Scope, 0);
    nondet.Value = std::numeric_limits<long>::max();
    EXPECT_TRUE(boost::get<long>(nondet.Value) == std::numeric_limits<long>::max());   
    //EXPECT_EQ (nondet.getTypeValue(nondet.Value), "unsigned");   
    nondet.FunctionName = "test";
    EXPECT_EQ (nondet.FunctionName, "test");
}

