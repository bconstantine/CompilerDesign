//source of method: https://stackoverflow.com/questions/2744181/how-to-call-c-function-from-c
#ifndef SYMBOL_TABLE_CPP_API
#define SYMBOL_TABLE_CPP_API
#include "commonDataStructure.h"


#ifdef __cplusplus
extern "C" {
#endif 
    //init API Engine
    void initAPIEngine(int debugMode);
    //test function
    void api_sayHi(const char *name);

    //these function is all the same with the one in symbolTableFix.cpp, see there for complete manual
    //it's just used inside here so that it can translate the function call from C++ to C (so that program will only include symbolTableAPI.h)
    //no cpp construct is used in these functions
    int create(int debugMode);
    int popBack(int debugMode);
    int symbolTableScopeSize(int debugMode);
    struct IdxPair lookupIndexFromLast(const char *name, int debugMode);
    struct IdxPair lookupIndexInLast(const char *name, int debugMode);
    struct EntryAttributes fromIdxPairReturnAttributes(struct IdxPair in, int debugMode);
    void editAttributesOnIndex(struct IdxPair in, struct EntryAttributes entry, int debugMode);
    struct IdxPair insert(const char* name, int debugMode);
    int dump(int debugMode);
#ifdef __cplusplus
}
#endif 

#endif 