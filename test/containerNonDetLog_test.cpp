#include "../include/ContainerNonDetLog.hpp"
#include "../include/Nondetlog.hpp"

#include "gtest/gtest.h"
#include <boost/integer_fwd.hpp>
#include <boost/variant/get.hpp>
#include <boost/variant.hpp>
#include <boost/any.hpp>
#include <iostream>
#include <utility>
#include <map>
#include <iterator>


TEST(ContainerNonDetLog, ContainerNonDetLog_int)
{
    NonDetLog NonDet;
    NonDet.Line = 12;
    NonDet.Scope = 0;
    NonDet.Value = 1.2;
    string type = NonDet.getTypeValue(NonDet.Value);
    NonDet.FunctionName = "test";

    ContainerNonDetLog CntrNondetlog;
    
    map<long, NonDetLog> m;
    m.insert(pair<long, NonDetLog>(1, NonDet));
    CntrNondetlog.ContainerLog_.push_back(m);
    EXPECT_EQ(CntrNondetlog.ContainerLog_.size(), 1);

    auto l_front = CntrNondetlog.ContainerLog_.begin();
    advance(l_front, 0);
    EXPECT_EQ(l_front->at(1).Line, 12) << l_front->at(1).Line;
      
    string jsonStr = CntrNondetlog.printJsonObj(NonDet);
    cout << jsonStr << endl;
    EXPECT_TRUE(jsonStr != "");

}