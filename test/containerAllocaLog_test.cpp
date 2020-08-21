#include "../include/ContainerAllocaLog.hpp"
#include "../include/AllocaLog.hpp"

#include "gtest/gtest.h"

TEST(ContainerAllocaLog, ContainerList)
{
    ContainerAllocaLog CntrAlloca;
    map<long, AllocaLog> MapTmp;
    CntrAlloca.ContainerLog_.push_back(MapTmp);

    EXPECT_TRUE(CntrAlloca.ContainerLog_.size() == 1);
}

TEST(ContainerAllocaLog, JsonGen)
{
    ContainerAllocaLog CntrAlloca;
    AllocaLog AlTmp;
    AlTmp.Address = 1024;
    AlTmp.IsFree = false;
    AlTmp.SizeToDestiny = 12;

    map<long, AllocaLog> MapTmp;
    MapTmp.insert(pair<long, AllocaLog>(2,AlTmp));
    CntrAlloca.ContainerLog_.push_back(MapTmp);

    string JsonTxt = CntrAlloca.printJsonObj(AlTmp);

    EXPECT_GE(JsonTxt.length(), 2);
}

TEST(ContainerAllocaLog, Search)
{
    ContainerAllocaLog CntrAlloca;
    AllocaLog AlTmp;
    AlTmp.Address = 1024;
    AlTmp.IsFree = false;
    AlTmp.SizeToDestiny = 12;

    map<long, AllocaLog> MapTmp;
    MapTmp.insert(pair<long, AllocaLog>(2,AlTmp));
    CntrAlloca.ContainerLog_.push_back(MapTmp);

    auto ObjAlloca = CntrAlloca.searchContainerAllocaLog(1024);

    EXPECT_GE(ObjAlloca.Address, 1024);
    EXPECT_FALSE(ObjAlloca.Address == 1028);
}

TEST(ContainerAllocaLog, SetDealAlloca)
{
    ContainerAllocaLog CntrAlloca;
    AllocaLog AlTmp;
    AlTmp.Address = 1024;
    AlTmp.IsFree = false;
    AlTmp.SizeToDestiny = 12;

    map<long, AllocaLog> MapTmp;
    MapTmp.insert(pair<long, AllocaLog>(12,AlTmp));
    CntrAlloca.ContainerLog_.push_back(MapTmp);

    CntrAlloca.setDealallocInAddress(12, 1024);

    EXPECT_GE(CntrAlloca.ContainerLog_.rbegin()->begin()->first, 
              13);
    EXPECT_GE(CntrAlloca.ContainerLog_.rbegin()->begin()->second.IsFree, 
              true);
    
}


TEST(ContainerAllocaLog, SetAlloca)
{
    ContainerAllocaLog CntrAlloca;
    AllocaLog AlTmp;
    AlTmp.Address = 1024;
    AlTmp.IsFree = true;
    AlTmp.SizeToDestiny = 12;

    map<long, AllocaLog> MapTmp;
    MapTmp.insert(pair<long, AllocaLog>(12,AlTmp));
    CntrAlloca.ContainerLog_.push_back(MapTmp);

    CntrAlloca.setAllocInAddress(12, 1024);

    EXPECT_GE(CntrAlloca.ContainerLog_.rbegin()->begin()->first, 
              13);
    EXPECT_GE(CntrAlloca.ContainerLog_.rbegin()->begin()->second.IsFree, 
              false);
    
}

TEST(ContainerAllocaLog, GetAddressType)
{
    ContainerAllocaLog CntrAlloca;
    AllocaLog AlTmp;
    AlTmp.Address = 1024;
    AlTmp.IsFree = true;
    AlTmp.SizeToDestiny = 12;

    map<long, AllocaLog> MapTmp;
    MapTmp.insert(pair<long, AllocaLog>(12,AlTmp));
    CntrAlloca.ContainerLog_.push_back(MapTmp);

    EXPECT_GE(CntrAlloca.getAddressTypeInLog(1024), 
              FREE);

    CntrAlloca.setAllocInAddress(12, 1024);
    EXPECT_GE(CntrAlloca.getAddressTypeInLog(1024), 
              DYNAMIC);
    
}

TEST(ContainerAllocaLog, AllocaLogIsValid)
{
    ContainerAllocaLog CntrAlloca;
    AllocaLog AlTmp;
    AlTmp.Address = 1024;
    AlTmp.IsFree = false;
    AlTmp.SizeToDestiny = 12;

    map<long, AllocaLog> MapTmp;
    MapTmp.insert(pair<long, AllocaLog>(12,AlTmp));
    CntrAlloca.ContainerLog_.push_back(MapTmp);

    CntrAlloca.setDealallocInAddress(12, 1024);

    auto ans = CntrAlloca.allocaLogIsValid();

    EXPECT_GE(ans.begin()->first, true);
    
}

TEST(ContainerAllocaLog, IsValidAllocaAddress)
{
    ContainerAllocaLog CntrAlloca;
    AllocaLog AlTmp;
    AlTmp.Address = 1024;
    AlTmp.IsFree = true;
    AlTmp.SizeToDestiny = 12;

    map<long, AllocaLog> MapTmp;
    MapTmp.insert(pair<long, AllocaLog>(12,AlTmp));
    CntrAlloca.ContainerLog_.push_back(MapTmp);

    EXPECT_GE(CntrAlloca.isValidAllocaAddress(1024, 12), false);
    
}