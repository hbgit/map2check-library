#include "../include/ContainerNonDetLog.hpp"
#include "../include/Nondetlog.hpp"

#include "gtest/gtest.h"
#include <boost/integer_fwd.hpp>
#include <boost/variant/get.hpp>
#include <boost/variant.hpp>
#include <boost/any.hpp>
#include <climits>
#include <iostream>
#include <utility>
#include <map>
#include <iterator>
#include <limits>


TEST(ContainerNonDetLog, ContainerNonDetLog_int)
{
    NonDetLog NonDet;
    NonDet.Line = 12;
    NonDet.Scope = 0;
    NonDet.Value = 1;
    string type = NonDet.getTypeValue(NonDet.Value);
    NonDet.FunctionName = "test";
    EXPECT_STREQ(type.c_str(), "int");

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


TEST(ContainerNonDetLog, ContainerNonDetLog_double)
{
    NonDetLog NonDet;
    NonDet.Line = 12;
    NonDet.Scope = 0;
    NonDet.Value = 1.2;
    string type = NonDet.getTypeValue(NonDet.Value);
    NonDet.FunctionName = "test";
    EXPECT_STREQ(type.c_str(), "double");
    
    ContainerNonDetLog CntrNondetlog;
    
    map<long, NonDetLog> m;
    m.insert(pair<long, NonDetLog>(1, NonDet));
    CntrNondetlog.ContainerLog_.push_back(m);
              
    string jsonStr = CntrNondetlog.printJsonObj(NonDet);
    EXPECT_TRUE(jsonStr != "");

}

TEST(ContainerNonDetLog, ContainerNonDetLog_float)
{
    NonDetLog NonDet;
    NonDet.Line = 12;
    NonDet.Scope = 0;
    NonDet.Value = 1.2f;
    string type = NonDet.getTypeValue(NonDet.Value);
    NonDet.FunctionName = "test";
    EXPECT_STREQ(type.c_str(), "float");
    
    ContainerNonDetLog CntrNondetlog;
    
    map<long, NonDetLog> m;
    m.insert(pair<long, NonDetLog>(1, NonDet));
    CntrNondetlog.ContainerLog_.push_back(m);
              
    string jsonStr = CntrNondetlog.printJsonObj(NonDet);
    EXPECT_TRUE(jsonStr != "");
}

TEST(ContainerNonDetLog, ContainerNonDetLog_char)
{
    NonDetLog NonDet;
    NonDet.Line = 12;
    NonDet.Scope = 0;
    NonDet.Value = 'x';
    string type = NonDet.getTypeValue(NonDet.Value);
    NonDet.FunctionName = "test";
    EXPECT_STREQ(type.c_str(), "char");
    
    ContainerNonDetLog CntrNondetlog;
    
    map<long, NonDetLog> m;
    m.insert(pair<long, NonDetLog>(1, NonDet));
    CntrNondetlog.ContainerLog_.push_back(m);
              
    string jsonStr = CntrNondetlog.printJsonObj(NonDet);
    EXPECT_TRUE(jsonStr != "");
}

TEST(ContainerNonDetLog, ContainerNonDetLog_unsigned)
{
    NonDetLog NonDet;
    NonDet.Line = 12;
    NonDet.Scope = 0;
    NonDet.Value = boost::static_min_max_unsigned_type();
    string type = NonDet.getTypeValue(NonDet.Value);
    NonDet.FunctionName = "test";
    EXPECT_STREQ(type.c_str(), "unsigned");
    
    ContainerNonDetLog CntrNondetlog;
    
    map<long, NonDetLog> m;
    m.insert(pair<long, NonDetLog>(1, NonDet));
    CntrNondetlog.ContainerLog_.push_back(m);
              
    string jsonStr = CntrNondetlog.printJsonObj(NonDet);
    EXPECT_TRUE(jsonStr != "");
}

TEST(ContainerNonDetLog, ContainerNonDetLog_long)
{
    NonDetLog NonDet;
    NonDet.Line = 12;
    NonDet.Scope = 0;
    NonDet.Value = LONG_MAX;
    string type = NonDet.getTypeValue(NonDet.Value);
    NonDet.FunctionName = "test";
    EXPECT_STREQ(type.c_str(), "long");
    
    ContainerNonDetLog CntrNondetlog;
    
    map<long, NonDetLog> m;
    m.insert(pair<long, NonDetLog>(1, NonDet));
    CntrNondetlog.ContainerLog_.push_back(m);
              
    string jsonStr = CntrNondetlog.printJsonObj(NonDet);
    EXPECT_TRUE(jsonStr != "");
}