//source of method: https://stackoverflow.com/questions/2744181/how-to-call-c-function-from-c
#ifndef SYMBOL_TABLE_CPP_API
#define SYMBOL_TABLE_CPP_API

#ifdef __cplusplus
extern "C" {
#endif
    //init API Engine
    void initAPIEngine(int debugMode);
    //test function
    void api_sayHi(const char *name);
    //create, see symbolTable.h for complete manual
    void create(int debugMode);
    //lookup, see symbolTable.h for complete manual
    int lookup(const char *name, int debugMode);
    //insert, see symbolTable.h for complete manual
    int insert(const char *name, int debugMode);
    //dump, see symbolTable.h for complete manual
    int dump(int debugMode);
#ifdef __cplusplus
}
#endif

#endif