#include "../include/ContainerMemoryTrackLog.hpp"
#include "../include/MemoryTrackLog.hpp"
#include "../include/AnalysisModeMemory.hpp"

#include "gtest/gtest.h"


TEST(AnalysisModeMemory, isValidAllocaAddress)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;    
    MtTmp.SizeToDestiny = 0;
    CntrMt.mapAlloca(2, MtTmp);
    CntrMt.setMalloc(3, 1012, 4);


    AnalysisModeMemory aM = AnalysisModeMemory(CntrMt.ContainerLog_);
    // insede the valid heap range
    EXPECT_EQ(aM.isValidAllocaAddress(1014, 1), true);
    EXPECT_EQ(aM.isValidAllocaAddress(1024, 4), false);
}


TEST(AnalysisModeMemory, isAllAllocaAddressValidInTheEnd)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;    
    MtTmp.SizeToDestiny = 0;
    CntrMt.mapAlloca(2, MtTmp);
    CntrMt.setMalloc(3, 1012, 4);

    MemoryTrackLog MtTmp2;
    MtTmp2.MemoryAddressPointsTo = 1728;
    MtTmp2.VarMemoryAddress = 1144;
    MtTmp2.FunctionName = "foo";        
    MtTmp2.LineNumber = 17;
    CntrMt.mapAlloca(3, MtTmp2);
    CntrMt.setMalloc(4, 1144, 4);


    AnalysisModeMemory aM = AnalysisModeMemory(CntrMt.ContainerLog_);
    
    //cout << CntrMt.printContainerAsJson() << endl;
    map<bool, long> Ans = aM.isAllAllocaAddressValidInTheEnd();
    EXPECT_EQ(Ans.begin()->first, true);
    EXPECT_EQ(Ans.begin()->second, 1144);

    //true
    CntrMt.setFree(5, MtTmp, 0);
    CntrMt.setFree(6, MtTmp2, 0);
    //cout << CntrMt.printContainerAsJson() << endl;
    AnalysisModeMemory aM2 = AnalysisModeMemory(CntrMt.ContainerLog_);
    map<bool, long> Ans2 = aM2.isAllAllocaAddressValidInTheEnd();
    EXPECT_EQ(Ans2.begin()->first, false);
    EXPECT_EQ(Ans2.begin()->second,  0);
    
}


TEST(AnalysisModeMemory, isValidHeapAddress)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;    
    MtTmp.SizeToDestiny = 4;
    CntrMt.mapAlloca(2, MtTmp);

    AnalysisModeMemory aM = AnalysisModeMemory(CntrMt.ContainerLog_);
    
    EXPECT_EQ(aM.isValidHeapAddress(1728, 4), false);
    
    EXPECT_EQ(aM.isValidHeapAddress(1012, 4), true);
}


TEST(AnalysisModeMemory, isMemCleanUpError)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;    
    MtTmp.SizeToDestiny = 0;
    CntrMt.mapAlloca(2, MtTmp);
    CntrMt.setMalloc(3, 1012, 4);
    MtTmp.IsDynamic = true;
    MtTmp.SizeToDestiny = 4;
    CntrMt.mapStorePointer(4, MtTmp);


    AnalysisModeMemory aM = AnalysisModeMemory(CntrMt.ContainerLog_);
    
    cout << CntrMt.printContainerAsJson() << endl;    
    EXPECT_EQ(aM.isMemCleanUpError(1024), true);

    //CntrMt.setFree(5, MtTmp, 0);
    //AnalysisModeMemory aM2 = AnalysisModeMemory(CntrMt.ContainerLog_);
    //EXPECT_EQ(aM.isMemCleanUpError(1024), false);    
}


TEST(AnalysisModeMemory, isDerefError)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;    
    MtTmp.SizeToDestiny = 4;
    
    CntrMt.mapAlloca(2, MtTmp);
    AnalysisModeMemory aM = AnalysisModeMemory(CntrMt.ContainerLog_);    
    EXPECT_EQ(aM.isDerefError(1012), false);

    MtTmp.IsDynamic = true;
    MtTmp.SizeToDestiny = 4;
    CntrMt.setMalloc(3, 1024, 4);
    AnalysisModeMemory aM2 = AnalysisModeMemory(CntrMt.ContainerLog_);    
    EXPECT_EQ(aM2.isDerefError(1024), false);
    EXPECT_EQ(aM2.isDerefError(1728), true);

    CntrMt.setFree(4, MtTmp, 0);
    AnalysisModeMemory aM3 = AnalysisModeMemory(CntrMt.ContainerLog_);    
    EXPECT_EQ(aM3.isDerefError(1024), true);

}


TEST(AnalysisModeMemory, isInvalidFree)
{
    ContainerMemoryTrackLog CntrMt;
    AnalysisModeMemory aM = AnalysisModeMemory(CntrMt.ContainerLog_);    
    EXPECT_EQ(aM.isInvalidFree(1728), true);
    EXPECT_EQ(aM.isInvalidFree(0), false);

    MemoryTrackLog MtTmp;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;    
    MtTmp.SizeToDestiny = 4;
    
    CntrMt.mapAlloca(2, MtTmp);    
    MtTmp.IsDynamic = true;
    MtTmp.SizeToDestiny = 4;
    CntrMt.setMalloc(3, 1012, 4);  
    AnalysisModeMemory aM2 = AnalysisModeMemory(CntrMt.ContainerLog_);
    cout << CntrMt.printContainerAsJson() << endl; 
    EXPECT_EQ(aM2.isInvalidFree(1024), false);

    CntrMt.setFree(4, MtTmp, 0);
    AnalysisModeMemory aM3 = AnalysisModeMemory(CntrMt.ContainerLog_);    
    EXPECT_EQ(aM3.isDerefError(1024), true);
}
