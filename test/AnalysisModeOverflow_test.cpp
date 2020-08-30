#include "../include/AnalysisModeOverflow.hpp"
#include "gtest/gtest.h"

#include <climits>
#include <limits>

TEST(AnalysisModeOverflow, checkOverBinopAddInt)
{
    AnalysisModeOverflow Amo;
    Amo.LineNumber = 12;
    Amo.FunctionName = "foo";
    Amo.Scope = 0;

    Amo.ValueParam1 = INT_MAX;
    Amo.ValueParam2 = INT_MAX;
    
    bool Ans = Amo.checkOverBinopAddInt();
    
    EXPECT_EQ(Ans, true);

    Amo.ValueParam1 = 4;
    Amo.ValueParam2 = 1728;
    
    bool Ans1 = Amo.checkOverBinopAddInt();
    
    EXPECT_EQ(Ans1, false);
}

TEST(AnalysisModeOverflow, checkOverBinopSubInt)
{
    AnalysisModeOverflow Amo;
    Amo.LineNumber = 12;
    Amo.FunctionName = "foo";
    Amo.Scope = 0;

    Amo.ValueParam1 = INT_MIN;
    Amo.ValueParam2 = INT_MIN;
    
    bool Ans = Amo.checkOverBinopSubInt();
    
    EXPECT_EQ(Ans, true);

    Amo.ValueParam1 = 4;
    Amo.ValueParam2 = 1728;
    
    bool Ans1 = Amo.checkOverBinopSubInt();
    
    EXPECT_EQ(Ans1, false);
}

TEST(AnalysisModeOverflow, checkOverBinopMulInt)
{
    AnalysisModeOverflow Amo;
    Amo.LineNumber = 12;
    Amo.FunctionName = "foo";
    Amo.Scope = 0;

    Amo.ValueParam1 = INT_MAX;
    Amo.ValueParam2 = INT_MAX;
    
    bool Ans = Amo.checkOverBinopMulInt();
    
    EXPECT_EQ(Ans, true);

    Amo.ValueParam1 = 4;
    Amo.ValueParam2 = 1728;
    
    bool Ans1 = Amo.checkOverBinopMulInt();
    
    EXPECT_EQ(Ans1, false);
}

TEST(AnalysisModeOverflow, checkOverBinopDivInt)
{
    AnalysisModeOverflow Amo;
    Amo.LineNumber = 12;
    Amo.FunctionName = "foo";
    Amo.Scope = 0;

    Amo.ValueParam1 = INT_MAX;
    Amo.ValueParam2 = 0;
    
    bool Ans = Amo.checkOverBinopDivInt();
    
    EXPECT_EQ(Ans, true);

    Amo.ValueParam1 = 1728;
    Amo.ValueParam2 = 12;
    
    bool Ans1 = Amo.checkOverBinopDivInt();
    
    EXPECT_EQ(Ans1, false);
}

TEST(AnalysisModeOverflow, checkOverBinopShlInt)
{
    AnalysisModeOverflow Amo;
    Amo.LineNumber = 12;
    Amo.FunctionName = "foo";
    Amo.Scope = 0;

    Amo.ValueParam1 = 1024;
    Amo.ValueParam2 = 30;
    
    bool Ans = Amo.checkOverBinopShlInt();
    
    EXPECT_EQ(Ans, true);

    Amo.ValueParam1 = 12;
    Amo.ValueParam2 = 2;
    
    bool Ans1 = Amo.checkOverBinopShlInt();
    
    EXPECT_EQ(Ans1, false);
}


TEST(AnalysisModeOverflow, checkOverBinopShRInt)
{
    AnalysisModeOverflow Amo;
    Amo.LineNumber = 12;
    Amo.FunctionName = "foo";
    Amo.Scope = 0;

    Amo.ValueParam1 = 1024;
    Amo.ValueParam2 = 32;
    
    bool Ans = Amo.checkOverBinopShRInt();
    
    EXPECT_EQ(Ans, true);

    Amo.ValueParam1 = 12;
    Amo.ValueParam2 = 2;
    
    bool Ans1 = Amo.checkOverBinopShRInt();
    
    EXPECT_EQ(Ans1, false);
}


TEST(AnalysisModeOverflow, checkOverBinopNegInt)
{
    AnalysisModeOverflow Amo;
    Amo.LineNumber = 12;
    Amo.FunctionName = "foo";
    Amo.Scope = 0;

    Amo.ValueParam1 = INT_MIN;
    //Amo.ValueParam2 = 30;
    
    bool Ans = Amo.checkOverBinopNegInt();
    
    EXPECT_EQ(Ans, true);

    Amo.ValueParam1 = 12;
    //Amo.ValueParam2 = 2;
    
    bool Ans1 = Amo.checkOverBinopNegInt();
    
    EXPECT_EQ(Ans1, false);
}


TEST(AnalysisModeOverflow, checkOverBinopAddUint)
{
    AnalysisModeOverflow Amo;
    Amo.LineNumber = 12;
    Amo.FunctionName = "foo";
    Amo.Scope = 0;

    Amo.ValueParam1 = UINT_MAX;
    Amo.ValueParam2 = UINT_MAX;
    
    bool Ans = Amo.checkOverBinopAddUint();
    
    EXPECT_EQ(Ans, true);

    Amo.ValueParam1 = (unsigned)12;
    Amo.ValueParam2 = (unsigned)2;
    
    bool Ans1 = Amo.checkOverBinopAddUint();
    
    EXPECT_EQ(Ans1, false);
}


TEST(AnalysisModeOverflow, checkOverBinopSubUint)
{
    AnalysisModeOverflow Amo;
    Amo.LineNumber = 12;
    Amo.FunctionName = "foo";
    Amo.Scope = 0;

    Amo.ValueParam1 = (unsigned)8;
    Amo.ValueParam2 = UINT_MAX;
    
    bool Ans = Amo.checkOverBinopSubUint();
    
    EXPECT_EQ(Ans, true);

    Amo.ValueParam1 = (unsigned)12;
    Amo.ValueParam2 = (unsigned)2;
    
    bool Ans1 = Amo.checkOverBinopSubUint();
    
    EXPECT_EQ(Ans1, false);
}


TEST(AnalysisModeOverflow, checkOverBinopMulUint)
{
    AnalysisModeOverflow Amo;
    Amo.LineNumber = 12;
    Amo.FunctionName = "foo";
    Amo.Scope = 0;

    Amo.ValueParam1 = (unsigned)UINT_MAX;
    Amo.ValueParam2 = (unsigned)UINT_MAX;
    
    bool Ans = Amo.checkOverBinopMulUint();
    
    EXPECT_EQ(Ans, true);

    Amo.ValueParam1 = (unsigned)12;
    Amo.ValueParam2 = (unsigned)2;
    
    bool Ans1 = Amo.checkOverBinopMulUint();
    
    EXPECT_EQ(Ans1, false);
}

TEST(AnalysisModeOverflow, checkOverBinopDivUint)
{
    AnalysisModeOverflow Amo;
    Amo.LineNumber = 12;
    Amo.FunctionName = "foo";
    Amo.Scope = 0;

    Amo.ValueParam1 = (unsigned)UINT_MAX;
    Amo.ValueParam2 = (unsigned)0;
    
    bool Ans = Amo.checkOverBinopDivUint();
    
    EXPECT_EQ(Ans, true);

    Amo.ValueParam1 = (unsigned)12;
    Amo.ValueParam2 = (unsigned)2;
    
    bool Ans1 = Amo.checkOverBinopDivUint();
    
    EXPECT_EQ(Ans1, false);
}


TEST(AnalysisModeOverflow, checkOverBinopShRUint)
{
    AnalysisModeOverflow Amo;
    Amo.LineNumber = 12;
    Amo.FunctionName = "foo";
    Amo.Scope = 0;

    Amo.ValueParam1 = (unsigned)UINT_MAX;
    Amo.ValueParam2 = (unsigned)32;
    
    bool Ans = Amo.checkOverBinopShRUint();
    
    EXPECT_EQ(Ans, true);

    Amo.ValueParam1 = (unsigned)12;
    Amo.ValueParam2 = (unsigned)2;
    
    bool Ans1 = Amo.checkOverBinopShRUint();
    
    EXPECT_EQ(Ans1, false);
}