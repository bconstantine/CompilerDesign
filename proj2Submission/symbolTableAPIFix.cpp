#include <cstdlib>

#include "symbolTableAPIFix.h"
#include "symbolTableFix.h"

//https://stackoverflow.com/questions/3789340/combining-c-and-c-how-does-ifdef-cplusplus-work
#ifdef __cplusplus
extern "C" {
#endif

    static SymbolTables *st = NULL;

    void initAPIEngine(int debugMode){
        if(st == NULL){
            printf("Creating new SymbolTables dynamic object\n");
            st = new SymbolTables();
        }
    }

    void api_sayHi(const char* name){
        initAPIEngine(0);
        st->sayHi(name);
    }
    
    int create(int debugMode){
        initAPIEngine(debugMode);
        return st->Create(debugMode);
    }
    int symbolTableScopeSize(int debugMode){
        initAPIEngine(debugMode);
        return st->SymbolTableScopeSize(debugMode);
    }
    int popBack(int debugMode){
        initAPIEngine(debugMode);
        return st->PopBack(debugMode);
    }
    struct IdxPair lookupIndexFromLast(const char *name, int debugMode){
        initAPIEngine(debugMode);
        struct IdxPair tmp = st->LookupIndexFromLast(name, debugMode);
        return tmp;
    }
    struct IdxPair lookupIndexInLast(const char *name, int debugMode){
        initAPIEngine(debugMode);
        struct IdxPair tmp = st->LookupIndexInLast(name, debugMode);
        return tmp;
    }

    struct EntryAttributes fromIdxPairReturnAttributes(struct IdxPair in, int debugMode){
        initAPIEngine(debugMode);
        struct EntryAttributes tmp = st->FromIdxPairReturnAttributes(in, debugMode);
        return tmp;
    }

    void editAttributesOnIndex(struct IdxPair in, struct EntryAttributes entry, int debugMode){
        initAPIEngine(debugMode);
        st->EditAttributesOnIndex(in, entry, debugMode);
    }
    struct  IdxPair insert(const char* name, int debugMode){
        initAPIEngine(debugMode);
        struct IdxPair tmp = st->Insert(name, debugMode);
        return tmp;
    }
    int dump(int debugMode){
        initAPIEngine(debugMode);
        return st->Dump(debugMode);
    }
#ifdef __cplusplus
}
#endif