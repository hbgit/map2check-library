#include "../include/ContainerHeapLog.hpp"
#include "../include/HeapLog.hpp"

#include "gtest/gtest.h"

TEST(ContainerHeapLog, ContainerList)
{
    ContainerHeapLog CntrHeap;
    map<long, HeapLog> MapTmp;
    CntrHeap.ContainerLog_.push_back(MapTmp);

    EXPECT_TRUE(CntrHeap.ContainerLog_.size() == 1);
}

TEST(ContainerHeapLog, JsonGen)
{
    ContainerHeapLog CntrHeap;
    HeapLog HeTmp;
    HeTmp.Address = (void *)&HeTmp;
    HeTmp.FunctName = "foo";
    HeTmp.LineNumber = 12;
    HeTmp.Scope = 0;
    HeTmp.Size = 4;
    HeTmp.SizeOfPrimitive = 4;
    HeTmp.SizeToLoad = 4;

    map<long, HeapLog> MapTmp;
    MapTmp.insert(pair<long, HeapLog>(2,HeTmp));
    CntrHeap.ContainerLog_.push_back(MapTmp);

    string JsonTxt = CntrHeap.printJsonObj(HeTmp);

    EXPECT_GE(JsonTxt.length(), 2);
}

TEST(ContainerHeapLog, IsValidHeapAddress)
{
    ContainerHeapLog CntrHeap;
    HeapLog HeTmp;
    HeTmp.Address = (void *)&HeTmp;
    HeTmp.FunctName = "foo";
    HeTmp.LineNumber = 12;
    HeTmp.Scope = 0;
    HeTmp.Size = 4;
    HeTmp.SizeOfPrimitive = 4;
    HeTmp.SizeToLoad = 4;


    map<long, HeapLog> MapTmp;
    MapTmp.insert(pair<long, HeapLog>(12,HeTmp));
    CntrHeap.ContainerLog_.push_back(MapTmp);

    EXPECT_GE(CntrHeap.isValidHeapAddress((void *)&HeTmp, 4), true);
    
}