#include "../include/MemoryTrackLog.hpp"

#include "gtest/gtest.h"

TEST(MemoryTrackLog, ContainerList)
{    
    MemoryTrackLog MapTmp;
    EXPECT_EQ(MapTmp.Step, 0);
}

TEST(MemoryTrackLog, isEqualMemoryTrackObj)
{
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
    EXPECT_EQ(MtTmp.isEqualMemoryTrackObj(MtTmp, MtTmp2), true);

    MtTmp2.IsDynamic = false;
    MtTmp2.IsFree = true;

    // False
    EXPECT_EQ(MtTmp.isEqualMemoryTrackObj(MtTmp, MtTmp2), false);
}


TEST(MemoryTrackLog, setMalloc)
{    
    MemoryTrackLog MtTmp;
    MtTmp.Step = 1;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;
    MtTmp.SizeOfPrimitive = 4;
    MtTmp.SizeToDestiny = 4;
    
    EXPECT_EQ(MtTmp.IsDynamic, false);
    
    MtTmp.Step = 3;
    MtTmp.setMalloc();
    EXPECT_EQ(MtTmp.IsDynamic, true);
    EXPECT_EQ(MtTmp.IsFree, false);
}


TEST(ContainerMemoryTrackLog, setCalloc)
{    
    MemoryTrackLog MtTmp;
    MtTmp.Step = 1;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;
    MtTmp.SizeOfPrimitive = 4;
    MtTmp.SizeToDestiny = 4;
            
    MtTmp.setCalloc(4);
    EXPECT_EQ(MtTmp.IsDynamic, true);
    EXPECT_EQ(MtTmp.SizeToDestiny, 16);
}


TEST(ContainerMemoryTrackLog, setFree)
{    
    MemoryTrackLog MtTmp;
    MtTmp.Step = 1;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;
    MtTmp.SizeOfPrimitive = 4;
    MtTmp.SizeToDestiny = 4;
            
    MtTmp.setMalloc();
    EXPECT_EQ(MtTmp.IsDynamic, true);
    EXPECT_EQ(MtTmp.IsFree, false);

    MtTmp.setFree();
    EXPECT_EQ(MtTmp.IsDynamic, false);
    EXPECT_EQ(MtTmp.IsFree, true);
}