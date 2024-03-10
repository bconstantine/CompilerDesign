#include <cstdlib>

#include "symbolTableAPI.h"
#include "symbolTable.h"

//https://stackoverflow.com/questions/3789340/combining-c-and-c-how-does-ifdef-cplusplus-work
#ifdef __cplusplus
extern "C" {
#endif

    static SymbolTables *st = NULL;

    void initAPIEngine(int debugMode){
        if(st == NULL){
            if(debugMode) printf("Creating new SymbolTables dynamic object");
            st = new SymbolTables();
        }
    }

    void api_sayHi(const char* name){
        initAPIEngine(0);
        st->sayHi(name);
    }
    
    //create, see symbolTable.h for complete manual
    void create(int debugMode){
        initAPIEngine(debugMode);
        return st->Create(debugMode);
    }
    //lookup, see symbolTable.h for complete manual
    int lookup(const char *name, int debugMode){
        initAPIEngine(debugMode);
        return st->Lookup(name, debugMode);
    }
    //insert, see symbolTable.h for complete manual
    int insert(const char *name, int debugMode){
        initAPIEngine(debugMode);
        return st->Insert(name, debugMode);
    }
    //dump, see symbolTable.h for complete manual
    int dump(int debugMode){
        initAPIEngine(debugMode);
        return st->Dump(debugMode);
    }
#ifdef __cplusplus
}
#endif