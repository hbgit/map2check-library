#include "../include/ContainerMemoryTrackLog.hpp"
#include "../include/MemoryTrackLog.hpp"

#include "gtest/gtest.h"

TEST(ContainerMemoryTrackLog, ContainerList)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MapTmp;
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
    
    CntrMt.ContainerLog_.push_back(MtTmp);

    string JsonTxt = CntrMt.printContainerAsJson();

    EXPECT_GE(JsonTxt.length(), 1);
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

    CntrMt.ContainerLog_.push_back(MtTmp);

    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1012).IsFree, false);

    MtTmp.IsFree = true;    
    MtTmp.Step = 5;
    CntrMt.ContainerLog_.push_back(MtTmp);
    
    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1012).IsFree, true);
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

    CntrMt.mapAlloca(MtTmp);

    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1012).Step, 0);
    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1212).Step, -1);
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

    CntrMt.mapNonStaticAlloca(MtTmp);

    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1012).Step, 0);
    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1212).Step, -1);
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

    CntrMt.mapFunctionAddress(MtTmp);

    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1012).Step, 0);
    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1212).Step, -1);
}


TEST(ContainerMemoryTrackLog, mapStorePointer)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.Step = 1;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;
    MtTmp.SizeOfPrimitive = 4;
    MtTmp.SizeToDestiny = 4;

    CntrMt.mapAlloca(MtTmp);

    //cout << CntrMt.printContainerAsJson() << CntrMt.ContainerLog_.size() << endl;
    //cout << "-----------------------------" << endl;
   
    MtTmp.LineNumber = 20;
    MtTmp.Step = 3;
    CntrMt.mapStorePointer(MtTmp);

    //cout << CntrMt.printContainerAsJson() << CntrMt.ContainerLog_.size() << endl;
    //cout << "-----------------------------" << endl;

    EXPECT_TRUE(CntrMt.ContainerLog_.size() == 2);
    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1012).LineNumber, 20);

    MtTmp.LineNumber = 20;
    CntrMt.mapStorePointer(MtTmp); // not add in the container
    //cout << CntrMt.printContainerAsJson() << CntrMt.ContainerLog_.size() << endl;
    //cout << "-----------------------------" << endl;

    EXPECT_TRUE(CntrMt.ContainerLog_.size() == 2);
    EXPECT_EQ(CntrMt.searchInContainerLogByAddress(1212).Scope, -1);
}
