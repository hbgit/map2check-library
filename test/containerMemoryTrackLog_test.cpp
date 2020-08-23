#include "../include/ContainerMemoryTrackLog.hpp"
#include "../include/MemoryTrackLog.hpp"

#include "gtest/gtest.h"

TEST(ContainerMemoryTrackLog, ContainerList)
{
    ContainerMemoryTrackLog CntrMt;
    map<long, MemoryTrackLog> MapTmp;
    CntrMt.ContainerLog_.push_back(MapTmp);

    EXPECT_TRUE(CntrMt.ContainerLog_.size() == 1);
}

TEST(ContainerMemoryTrackLog, JsonGen)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";
    MtTmp.PointerName = "ptr";
    MtTmp.IsDynamic = false;
    MtTmp.IsFree = false;
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;

    map<long, MemoryTrackLog> MapTmp;
    MapTmp.insert(pair<long, MemoryTrackLog>(2,MtTmp));
    CntrMt.ContainerLog_.push_back(MapTmp);

    string JsonTxt = CntrMt.printJsonObj(MtTmp);

    EXPECT_GE(JsonTxt.length(), 2);
}


TEST(ContainerMemoryTrackLog, GetLastReference)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";
    MtTmp.PointerName = "ptr";
    MtTmp.IsDynamic = true;
    MtTmp.IsFree = false;
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;

    map<long, MemoryTrackLog> MapTmp;
    MapTmp.insert(pair<long, MemoryTrackLog>(2,MtTmp));
    CntrMt.ContainerLog_.push_back(MapTmp);

    MtTmp.IsFree = true;
    map<long, MemoryTrackLog> MapTmp2;
    MapTmp2.insert(pair<long, MemoryTrackLog>(5,MtTmp));
    CntrMt.ContainerLog_.push_back(MapTmp2);
    
    EXPECT_EQ(CntrMt.getLastReference(1012), 1024);
}

TEST(ContainerMemoryTrackLog, IsMemCleanUpError)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";
    MtTmp.PointerName = "ptr";
    MtTmp.IsDynamic = true;
    MtTmp.IsFree = false;
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;

    map<long, MemoryTrackLog> MapTmp;
    MapTmp.insert(pair<long, MemoryTrackLog>(2,MtTmp));
    CntrMt.ContainerLog_.push_back(MapTmp);

    /*MtTmp.IsFree = true;
    map<long, MemoryTrackLog> MapTmp2;
    MapTmp2.insert(pair<long, MemoryTrackLog>(5,MtTmp));
    CntrMt.ContainerLog_.push_back(MapTmp2);*/
    
    EXPECT_EQ(CntrMt.isMemCleanUpError(1024), true);
    EXPECT_EQ(CntrMt.isMemCleanUpError(1012), false);
}

TEST(ContainerMemoryTrackLog, IsDerefError)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";
    MtTmp.PointerName = "ptr";
    MtTmp.IsDynamic = true;
    MtTmp.IsFree = true;
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;

    map<long, MemoryTrackLog> MapTmp;
    MapTmp.insert(pair<long, MemoryTrackLog>(2,MtTmp));
    CntrMt.ContainerLog_.push_back(MapTmp);
    
    EXPECT_EQ(CntrMt.isDerefError(1012), false);
    EXPECT_EQ(CntrMt.isDerefError(1024), true);
    EXPECT_EQ(CntrMt.isDerefError(4000), false);
}

TEST(ContainerMemoryTrackLog, IsInvalidFree)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";
    MtTmp.PointerName = "ptr";
    MtTmp.IsDynamic = true;
    MtTmp.IsFree = true;
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;

    map<long, MemoryTrackLog> MapTmp;
    MapTmp.insert(pair<long, MemoryTrackLog>(2,MtTmp));
    CntrMt.ContainerLog_.push_back(MapTmp);
    
    EXPECT_EQ(CntrMt.isInvalidFree((long)NULL), false);
    EXPECT_EQ(CntrMt.isInvalidFree(1024), true);
    
}

TEST(ContainerMemoryTrackLog, GetMemoryAddressStatus)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";
    MtTmp.PointerName = "ptr";
    MtTmp.IsDynamic = true;
    MtTmp.IsFree = false;
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;
    
    EXPECT_EQ(CntrMt.getMemoryAddressStatus(MtTmp), DYNAMIC);
    
    MtTmp.IsDynamic = false;
    MtTmp.IsFree = true;
    EXPECT_EQ(CntrMt.getMemoryAddressStatus(MtTmp), FREE);
}
