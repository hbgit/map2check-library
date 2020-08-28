#include "../include/AnalysisModeAssert.hpp"

#include "gtest/gtest.h"

TEST(AnalysisModeAssert, ExprFalse)
{
    AnalysisModeAssert Ama;
    Ama.LineNumber = 12;
    Ama.FunctionName = "foo";
    int N = 24;
    bool Ans = Ama.checkAssert(12 > N);
    
    EXPECT_EQ(Ans, false);
}

TEST(AnalysisModeAssert, ExprTrue)
{
    AnalysisModeAssert Ama;
    Ama.LineNumber = 12;
    Ama.FunctionName = "foo";
    int N = 24;
    bool Ans = Ama.checkAssert(12 < N);
    
    EXPECT_EQ(Ans, true);
}

