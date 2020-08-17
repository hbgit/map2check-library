#include "../include/ContainerLog.hpp"
#include "../include/Nondetlog.hpp"

#include "gtest/gtest.h"

#include <iterator>
#include <list>
#include <map>

TEST(ContainerLog, ListJson)
{
   ContainerLog CntrLog;
    
    CntrLog.JsonLogString.push_back("{test:test}");
    auto l_front = CntrLog.JsonLogString.begin();
    advance(l_front, 0);
    //EXPECT_TRUE(false) << *l_front;  
    std::string s = "{test:test}";
    EXPECT_EQ(*l_front, s);    
}


TEST(ContainerLog, AppendList)
{
    ContainerLog CntrLog;
    
    NonDetLog ndtl;
    ndtl.Line = 12;
    
    map<long, NonDetLog> ItemContainer = CntrLog.appendContainerLog(1, ndtl);
    //EXPECT_TRUE(false) << "ItemContainer.size()";
    EXPECT_TRUE(ItemContainer.at(1).Line == 12);
}