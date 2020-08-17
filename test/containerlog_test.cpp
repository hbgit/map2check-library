#include "../include/ContainerLog.hpp"
#include "../include/Nondetlog.hpp"

#include "gtest/gtest.h"

#include <map>
#include <typeinfo>

TEST(ContainerLog, ListJson)
{
    ContainerLog CntrLog;
    
    CntrLog.JsonLogString.push_back("{test:test}");
    string Txt = CntrLog.JsonLogString.end()->c_str();
    EXPECT_EQ(Txt, "{test:test}");
}

TEST(ContainerLog, AppendList)
{
    ContainerLog CntrLog;
    
    NonDetLog ndtl;
    ndtl.Line = 12;
    
    map<long, NonDetLog> ItemContainer = CntrLog.appendContainerLog(1, ndtl);
    //EXPECT_TRUE(false) << ItemContainer.size();
    EXPECT_TRUE(ItemContainer.at(1).Line == 12);
}