#include "../include/ContainerNonDetLog.hpp"
#include "../include/Nondetlog.hpp"

#include "gtest/gtest.h"


TEST(ContainerNonDetLog, ContainerNonDetLog_long)
{
    NonDetLog NonDet;
    NonDet.Line = 12;
    NonDet.Scope = 0;
    NonDet.Value = LONG_MAX;
    NonDet.FunctionName = "test";
    
    ContainerNonDetLog CntrNondetlog;

    CntrNondetlog.ContainerLog_.push_back(NonDet);
    NonDet.Step = 1;
    CntrNondetlog.ContainerLog_.push_back(NonDet);
              
    string jsonStr = CntrNondetlog.printContainerAsJson();
    cout << jsonStr << endl;
    EXPECT_TRUE(jsonStr != "");
}