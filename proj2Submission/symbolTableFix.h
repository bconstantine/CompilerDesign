#ifndef SYMBOL_TABLE_CPP
#define SYMBOL_TABLE_CPP
#include <vector>
#include <map>
#include <string>
#include "commonDataStructure.h"

class SymbolTables{
    public:
        std::vector<std::map<std::string, int>> symbolTables; //name and index mapping
        std::vector<std::vector<EntryAttributes>> entryAttributesCol; //contagious array that is a collection of entry attributes
                                                                      //I do not directly store it inside symbolTables map so that Lex can pass Index to Yacc, just like the method the teacher say
        SymbolTables();
        void sayHi(const char *name);

        /*Debug mode will decide whether or not to cout debug message*/
        /*Create a symbol table entry*/
        int Create(int debugMode);
        //pop the lasat symbol table entry
        int PopBack(int debugMode);
        //return the size of the symbol table (or the number of nested scope we are having at this point)
        int SymbolTableScopeSize(int debugMode);
        /*From the last scope, traverse and return the index of a string name match with the identifier
        if no match found for all, then return NIL*/
        struct IdxPair LookupIndexFromLast(const char* name, int debugMode);
        /*In the last scope, traverse and return the index of a string name match with the identifier
        if no match found for all, then return NIL*/
        struct IdxPair LookupIndexInLast(const char* name, int debugMode);
        //based on the idx pair, get the attributes of the entry
        struct EntryAttributes FromIdxPairReturnAttributes(struct IdxPair in, int debugMode);
        /* Edit the attributes on a specific index */
        void EditAttributesOnIndex(struct IdxPair location, struct EntryAttributes entry, int debugMode);
        /*Returns new index id, otherwise -1 (NIL) if already exist
        Note that for dynamic attributes, it is considered to be initialized in the yacc*/
        struct IdxPair Insert(const char* name, int debugMode);
        /*Dumps all entries of the symbol table on first vector, return length*/
        int Dump(int debugMode);
        // helper function, to print content of symbol table entry Attributes, on the last scope, this function is also contained inside PopBack
        int DumpLast(int debugMode);
};
#endif 