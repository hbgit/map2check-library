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

    string JsonTxt = CntrMt.printContainerAsJson();

    EXPECT_GE(JsonTxt.length(), 2);
}


TEST(ContainerMemoryTrackLog, searchInContainerLogByAddress)
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

    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1012).IsFree, false);

    MtTmp.IsFree = true;
    map<long, MemoryTrackLog> MapTmp2;
    MapTmp2.insert(pair<long, MemoryTrackLog>(5,MtTmp));
    CntrMt.ContainerLog_.push_back(MapTmp2);
    
    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1012).IsFree, true);
}


TEST(ContainerMemoryTrackLog, isEqualMemoryTrackObj)
{
    ContainerMemoryTrackLog CntrMt;

    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;    
    MtTmp.IsDynamic = true;
    MtTmp.IsFree = false;
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;

    MemoryTrackLog MtTmp2;
    MtTmp2.MemoryAddressPointsTo = 1024;
    MtTmp2.VarMemoryAddress = 1012;    
    MtTmp2.IsDynamic = true;
    MtTmp2.IsFree = false;
    MtTmp2.LineNumber = 13;
    MtTmp2.Scope = 0;
    
    // True
    EXPECT_EQ(CntrMt.isEqualMemoryTrackObj(MtTmp, MtTmp2), true);

    MtTmp2.IsDynamic = false;
    MtTmp2.IsFree = true;

    // False
    EXPECT_EQ(CntrMt.isEqualMemoryTrackObj(MtTmp, MtTmp2), false);
}


TEST(ContainerMemoryTrackLog, mapAlloca)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;

    map<long, MemoryTrackLog> MapTmp;
    MapTmp.insert(pair<long, MemoryTrackLog>(2,MtTmp));
    CntrMt.mapAlloca(2, MtTmp);

    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1012).Scope, 0);
    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1212).Scope, -1);
}


TEST(ContainerMemoryTrackLog, mapNonStaticAlloca)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;
    MtTmp.SizeOfPrimitive = 4;
    MtTmp.SizeToDestiny = 4;

    map<long, MemoryTrackLog> MapTmp;
    MapTmp.insert(pair<long, MemoryTrackLog>(2,MtTmp));
    CntrMt.mapNonStaticAlloca(2, MtTmp);

    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1012).Scope, 0);
    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1212).Scope, -1);
}


TEST(ContainerMemoryTrackLog, mapFunctionAddress)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;
    MtTmp.SizeOfPrimitive = 4;
    MtTmp.SizeToDestiny = 4;

    map<long, MemoryTrackLog> MapTmp;
    MapTmp.insert(pair<long, MemoryTrackLog>(2,MtTmp));
    CntrMt.mapFunctionAddress(2, MtTmp);

    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1012).Scope, 0);
    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1212).Scope, -1);
}


TEST(ContainerMemoryTrackLog, mapStorePointer)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;
    MtTmp.SizeOfPrimitive = 4;
    MtTmp.SizeToDestiny = 4;

    map<long, MemoryTrackLog> MapTmp;
    MapTmp.insert(pair<long, MemoryTrackLog>(2,MtTmp));
    CntrMt.mapAlloca(2, MtTmp);

    cout << CntrMt.printContainerAsJson() << CntrMt.ContainerLog_.size() << endl;
    cout << "-----------------------------" << endl;
   
    MtTmp.LineNumber = 20;
    CntrMt.mapStorePointer(3, MtTmp);

    cout << CntrMt.printContainerAsJson() << CntrMt.ContainerLog_.size() << endl;
    cout << "-----------------------------" << endl;

    EXPECT_TRUE(CntrMt.ContainerLog_.size() == 2);
    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1012).LineNumber, 20);

    MtTmp.LineNumber = 20;
    CntrMt.mapStorePointer(3, MtTmp); // not add in the container
    cout << CntrMt.printContainerAsJson() << CntrMt.ContainerLog_.size() << endl;
    cout << "-----------------------------" << endl;

    EXPECT_TRUE(CntrMt.ContainerLog_.size() == 2);
    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1212).Scope, -1);
}


/*
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
    
}*/
