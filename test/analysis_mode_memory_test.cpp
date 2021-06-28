#include "gtest/gtest.h"

extern "C" {
  #include "../include/analysismode/analysis_memory.h" 
  #include "../include/caller/caller_lib_result.h" 
}

TEST(AnalysisModeMemory, debug_analysis_mem_set_only_test)
{
    debug_analysis_mem_set_only_test();
    //map2check_init();
    //debug_assert_set_only_test();
    //map2check_is_valid_assert(12, "foo", 144 <= 12);
    EXPECT_EQ(1, 1);
}

TEST(AnalysisModeMemory, vcc_memcheck_failed)
{
    map2check_init();
    debug_analysis_mem_set_only_test();
    vcc_memcheck_failed(1, 12, 0, (char*)"foo",(long)123456, FREE);
    EXPECT_EQ(get_current_property(), MEMSAFETY_FREE);
    vcc_memcheck_failed(1, 12, 0, (char*)"foo",(long)123456, DEREF);
    EXPECT_EQ(get_current_property(), MEMSAFETY_DEREF);
    vcc_memcheck_failed(1, 12, 0, (char*)"foo",(long)123456, MEMTRACK);
    EXPECT_EQ(get_current_property(), MEMSAFETY_MEMTRACK);
    vcc_memcheck_failed(1, 12, 0, (char*)"foo",(long)123456, MEMCLEANUP);
    EXPECT_EQ(get_current_property(), MEMSAFETY_MEMCLEANUP);
}

/*
TEST(AnalysisModeMemory, isValidAllocaAddress)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.Step = 1;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;    
    MtTmp.SizeToDestiny = 0;
    CntrMt.mapAlloca(MtTmp);
    

    MtTmp.setMalloc();
    MtTmp.SizeToDestiny = 4;
    CntrMt.mapAlloca(MtTmp);

    AnalysisModeMemory aM = AnalysisModeMemory(CntrMt.ContainerLog_);
    // insede the valid heap range
    EXPECT_EQ(aM.isValidAllocaAddress(1014, 1), true);
    EXPECT_EQ(aM.isValidAllocaAddress(1024, 4), false);
}


TEST(AnalysisModeMemory, isAllAllocaAddressValidInTheEnd)
{
    ContainerMemoryTrackLog CntrMt;
    MemoryTrackLog MtTmp;
    MtTmp.Step = 1;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;    
    MtTmp.SizeToDestiny = 0;
    CntrMt.mapAlloca(MtTmp);
    MtTmp.Step = 2;
    MtTmp.setMalloc();
    CntrMt.mapAlloca(MtTmp);

    MemoryTrackLog MtTmp2;
    MtTmp2.MemoryAddressPointsTo = 1728;
    MtTmp2.VarMemoryAddress = 1144;
    MtTmp2.FunctionName = "foo";        
    MtTmp2.LineNumber = 17;
    CntrMt.mapAlloca(MtTmp2);
    MtTmp2.setMalloc();
    CntrMt.mapAlloca(MtTmp2);


    AnalysisModeMemory aM = AnalysisModeMemory(CntrMt.ContainerLog_);
    
    //cout << CntrMt.printContainerAsJson() << endl;
    map<bool, long> Ans = aM.isAllAllocaAddressValidInTheEnd();
    EXPECT_EQ(Ans.begin()->first, true);
    EXPECT_EQ(Ans.begin()->second, 1144);

    //true
    MtTmp.setFree();
    CntrMt.mapAlloca(MtTmp);
    MtTmp2.setFree();
    CntrMt.mapAlloca(MtTmp2);

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
    MtTmp.Step = 1;
    MtTmp.MemoryAddressPointsTo = 1024;
    MtTmp.VarMemoryAddress = 1012;
    MtTmp.FunctionName = "foo";        
    MtTmp.LineNumber = 13;
    MtTmp.Scope = 0;    
    MtTmp.SizeToDestiny = 4;
    CntrMt.mapAlloca(MtTmp);

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
    CntrMt.mapAlloca(MtTmp);
    MtTmp.setMalloc();
    CntrMt.mapAlloca(MtTmp);
    
    MtTmp.SizeToDestiny = 4;
    MtTmp.Step += MtTmp.Step;
    CntrMt.mapStorePointer(MtTmp);


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
    
    CntrMt.mapAlloca(MtTmp);
    AnalysisModeMemory aM = AnalysisModeMemory(CntrMt.ContainerLog_);    
    EXPECT_EQ(aM.isDerefError(1012), false);

    MtTmp.setMalloc();
    CntrMt.mapAlloca(MtTmp);
    MtTmp.SizeToDestiny = 4;
    
    AnalysisModeMemory aM2 = AnalysisModeMemory(CntrMt.ContainerLog_);    
    EXPECT_EQ(aM2.isDerefError(1024), false);
    EXPECT_EQ(aM2.isDerefError(1728), true);

    MtTmp.setFree();
    CntrMt.mapAlloca(MtTmp);
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
    CntrMt.mapAlloca(MtTmp);

    MtTmp.setMalloc();
    MtTmp.SizeToDestiny = 4;
    CntrMt.mapAlloca(MtTmp);
    
    AnalysisModeMemory aM2 = AnalysisModeMemory(CntrMt.ContainerLog_);
    cout << CntrMt.printContainerAsJson() << endl; 
    EXPECT_EQ(aM2.isInvalidFree(1024), false);

    MtTmp.setFree();
    CntrMt.mapAlloca(MtTmp);
    AnalysisModeMemory aM3 = AnalysisModeMemory(CntrMt.ContainerLog_);    
    EXPECT_EQ(aM3.isDerefError(1024), true);
}
*/