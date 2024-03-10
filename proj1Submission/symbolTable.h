#ifndef SYMBOL_TABLE_CPP
#define SYMBOL_TABLE_CPP
#include <vector>
#include <map>
#include <string>

class SymbolTables{
    public:
        //for now, set mapping from variable name to int(id)
        std::vector<std::map<std::string, int>> symbolTables;
        SymbolTables();
        void sayHi(const char *name);

        /*Debug mode will decide whether or not to cout*/
        /*Create a symbol table entry*/
        void Create(int debugMode);
        /*Return int (index of the id in the first symbol tables, otherwise -1 (NIL) if not found)*/
        int Lookup(const char* name, int debugMode);
        /*Return int (new index of id, otherwise -1 (NIL) if already exist)*/
        int Insert(const char* name, int debugMode);
        /*Dumps all entries of the symbol table on first vector, return length*/
        int Dump(int debugMode);
};
#endif