#include "../include/Nondetlog.hpp"

#include "gtest/gtest.h"
#include <boost/integer_fwd.hpp>
#include <boost/variant/get.hpp>
#include <boost/variant.hpp>
#include <iostream>


TEST(NonDetLog, NonDetLog_int)
{
    NonDetLog nondet;
    nondet.Line = 12;
    EXPECT_EQ(nondet.Line, 12);
    nondet.Scope = 0;
    EXPECT_EQ(nondet.Scope, 0);
    nondet.Value = 7;
    EXPECT_TRUE(boost::get<int>(nondet.Value) == 7);   
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
    nondet.Value = 1.2512333;
    EXPECT_TRUE(boost::get<double>(nondet.Value) == 1.2512333);   
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
    nondet.Value = 1.2512333f;
    EXPECT_TRUE(boost::get<float>(nondet.Value) == 1.2512333f);   
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
    nondet.Value = 'x';
    EXPECT_TRUE(boost::get<char>(nondet.Value) == 'x');   
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
    unsigned k = boost::static_min_max_unsigned_type();
    nondet.Value = k;
    EXPECT_TRUE(boost::get<unsigned>(nondet.Value) == k);   
    EXPECT_EQ (nondet.getTypeValue(nondet.Value), "unsigned");   
    nondet.FunctionName = "test";
    EXPECT_EQ (nondet.FunctionName, "test");
}

