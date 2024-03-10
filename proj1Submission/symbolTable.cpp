#include <iostream>
#include "symbolTable.h"
#define NIL -1

//Constructor, needed to make dynamic
SymbolTables::SymbolTables(){
}

//test func
void SymbolTables::sayHi(const char *name){
    std::cout << "Hi " << name << std::endl;
}

/*Create a symbol table entry*/
void SymbolTables::Create(int debugMode){
    std::map<std::string, int> a;
    this->symbolTables.push_back(a);
}
/*Return int (index of the id in the first symbol tables, otherwise -1 (NIL) if not found)*/
int SymbolTables::Lookup(const char* name, int debugMode){
    if (this->symbolTables.size() < 1){
        if(debugMode) std::cout << "Bad Lookup: No Symbol Tables exist\n";
        exit(1);
    }
    
    //find
    std::string goal = name;
    if(this->symbolTables[0].find(goal) != this->symbolTables[0].end()){
        //exist
        return this->symbolTables[0][goal];
    }else{
        //not exist, NIL
        return NIL;
    }
}
/*Return int (new index of id, otherwise -1 (NIL) if already exist)*/
int SymbolTables::Insert(const char* name, int debugMode){
    if (this->symbolTables.size() < 1){
        if(debugMode) std::cout << "Bad Insert: No Symbol Tables exist\n";
        exit(1);
    }

    //find
    std::string goal = name;
    if(this->symbolTables[0].find(goal) != this->symbolTables[0].end()){
        //exist, error return NIL
        if(debugMode) std::cout << "Bad Insert: ID already exist\n";
        return NIL;
    }else{
        //not exist, return index
        int curLength = this->symbolTables[0].size();
        this->symbolTables[0][goal] = curLength;
        return curLength;
    }
}
/*Dumps all entries of the symbol table on first vector, return length*/
int SymbolTables::Dump(int debugMode){
    if (this->symbolTables.size() < 1){
        if(debugMode) std::cout << "Bad Dump: No Symbol Tables exist\n";
        exit(1);
    }
    else{
        std::cout << "Symbol Table:\n";
        std::cout << "Variables--Index\n";
        /* Printing alphabetically*/
        /* 
        for(auto i = this->symbolTables[0].begin(); i != this->symbolTables[0].end(); i++){
            std::cout << i->first << "--" << i->second << "\n";
        }
        */

        /* Printing based on index (brute force)*/
        int temp = 0;
        int sze = this->symbolTables[0].size();
        while(temp < sze){
            int found = 0;
            for(auto i = this->symbolTables[0].begin(); i != this->symbolTables[0].end(); i++){
                if(i->second == temp){
                    std::cout << i->first << "--" << i->second << "\n";
                    found = 1;
                    temp += 1;
                    break;
                }
            }
            if(!found)
            {
                std::cout << "Index " << temp << " not found! Error!\n";
            }
        }
        return this->symbolTables[0].size();
    }
}