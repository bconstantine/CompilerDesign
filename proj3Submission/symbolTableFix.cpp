#include <iostream>
#include "symbolTableFix.h"
#include "cstring"

//Constructor for the symbol tables, which later will be a dynamic object
SymbolTables::SymbolTables(){
}

//just a test function 
void SymbolTables::sayHi(const char *name){
    std::cout << "Hi " << name << std::endl;
}

//return the size of the symbol table (or the number of nested scope we are having at this point)
int SymbolTables::SymbolTableScopeSize(int debugMode){
    return (this->symbolTables).size();
}

/*Create a symbol table entry*/
int SymbolTables::Create(int debugMode, int isAFunctionProcedureScope){
    //printf("Creating new symbol table entry\n");
    std::map<std::string, int> a;
    this->symbolTables.push_back(a);
    std::vector<EntryAttributes> b;
    this->entryAttributesCol.push_back(b);

    //if it is a global scope, create next counter as 0, otherwise take previous counter
    if(this->nextVariableCounter.size() == 0){
        this->nextVariableCounter.push_back(0);
    }else if(isAFunctionProcedureScope){ 
        int lastNextIdx = 0;
        this->nextVariableCounter.push_back(lastNextIdx);
        if(doInsertInfoAndDumpLastEntryDuringPopProject3){
            std::cout << "entering function/procedure block, next number " << lastNextIdx << "\n";
        }
    }else{
        int lastNextIdx = this->nextVariableCounter[this->nextVariableCounter.size() - 1];
        if(doInsertInfoAndDumpLastEntryDuringPopProject3){
            std::cout << "entering block, next number " << lastNextIdx << "\n";
        }
    }
    return ((this->symbolTables).size() - 1);
}

//pop the last symbol table entry
int SymbolTables::PopBack(int debugMode, int isAFunctionProcedureScope){
    if (this->symbolTables.size() < 1){
        if(debugMode) std::cout << "Bad PopBack: No Symbol Tables exist\n";
        exit(1);
    }
    if(doDumpLastEntryDuringPop){
        std::cout << "contents before popped back\n";
        std::cout << "=============================\n";
        this->DumpLast(debugMode);
        std::cout << "=============================\n";
    }
    if(doInsertInfoAndDumpLastEntryDuringPopProject3){
        //only print local variables, other entry is not printed
        std::cout << "leaving block, symbol table entries: \n";
        if(this->symbolTables.size() > 1){
            this->DumpLastProj3(debugMode);
        }
    }
    //printf("Popping recent symbol table entry\n");
    this->symbolTables.pop_back();
    //pop back also the variable attributes, no longer needed
    //before pop back, traverse for allocated dynamic storage, and deallocate the storage
    int interestIdx = this->entryAttributesCol.size() - 1; 
    int sze = this->entryAttributesCol[interestIdx].size();
    for(int curIdx = 0; curIdx < sze; curIdx++){
        if(this->entryAttributesCol[interestIdx][curIdx].entryType == FUNCTION_ENTTYPE){
            //deallocate dynamic storage or parameter ordering, if params length is more than 
            if(this->entryAttributesCol[interestIdx][curIdx].paramsLength > 0)
            {
                delete this->entryAttributesCol[interestIdx][curIdx].paramsOrdering;
                delete this->entryAttributesCol[interestIdx][curIdx].eachParamsHowManyElements;
            }
        }
        
    }
    this->entryAttributesCol.pop_back();

    //remove the variable counter if the one that pop back is a function
    if(isAFunctionProcedureScope){
        this->nextVariableCounter.pop_back();
    }
    return this->symbolTables.size();
}

/*From the last scope, traverse and return the index of a string name match with the identifier
if no match found for all, then return NIL*/
struct IdxPair SymbolTables::LookupIndexFromLast(const char* name, int debugMode){
    if (this->symbolTables.size() < 1){
        if(debugMode) std::cout << "Bad Lookup: No Symbol Tables exist\n";
        exit(1);
    }

    std::string goal = name;
    struct IdxPair tmp;
    strcpy(tmp.varName, name);
    //work all the way back from current to front
    int curIdx = this->symbolTables.size() - 1;
    while(curIdx >= 0){
        if(this->symbolTables[curIdx].find(goal) != this->symbolTables[curIdx].end()){
            //exist
            tmp.symTableIdx = curIdx;
            tmp.innerIdx = this->symbolTables[curIdx][goal];
            return tmp;
        }
        curIdx--;
    }

    //not exist, NIL
    tmp.symTableIdx = NIL;
    tmp.innerIdx = NIL;
    return tmp;
}

/*In the last scope, traverse and return the index of a string name match with the identifier
if no match found for all, then return NIL*/
struct IdxPair SymbolTables::LookupIndexInLast(const char* name, int debugMode){
    if (this->symbolTables.size() < 1){
        if(debugMode) std::cout << "Bad Lookup: No Symbol Tables exist\n";
        exit(1);
    }

    std::string goal = name;
    struct IdxPair tmp;
    //only search the last symbol table
    int curIdx = this->symbolTables.size() - 1;
    strcpy(tmp.varName, name);
    if(this->symbolTables[curIdx].find(goal) != this->symbolTables[curIdx].end()){
        //exist
        tmp.symTableIdx = curIdx;
        tmp.innerIdx = this->symbolTables[curIdx][goal];
        return tmp;
    }

    //not exist, NIL
    tmp.symTableIdx = NIL;
    tmp.innerIdx = NIL;
    return tmp;
}

//based on the idx pair, get the attributes of the entry
struct EntryAttributes SymbolTables::FromIdxPairReturnAttributes(struct IdxPair in, int debugMode){
    //verify index validity
    struct EntryAttributes returnVal;
    if(this->entryAttributesCol.size() <= in.symTableIdx){
        if(debugMode) std::cout << "Bad Return Attributes: Symbol Table out of bound\n";
        std::cout << "entry: " << this->entryAttributesCol.size() << "\n";
        std::cout << "in: " << in.symTableIdx << "\n";
        exit(1);
    }
    if(this->entryAttributesCol[in.symTableIdx].size() <= in.innerIdx){
        if(debugMode) std::cout << "Bad Return Attributes: Inner Table out of bound\n";
        exit(1);
    }
    //return all the EntryAttributes
    returnVal = this->entryAttributesCol[in.symTableIdx][in.innerIdx];
    return returnVal;
}

/* Edit the attributes on a specific index */
void SymbolTables::EditAttributesOnIndex(struct IdxPair in, struct EntryAttributes entry, int debugMode){
    if(this->entryAttributesCol.size() <= in.symTableIdx){
        if(debugMode) std::cout << "Bad Edit Attributes: Symbol Table out of bound\n";
        exit(1);
    }
    if(this->entryAttributesCol[in.symTableIdx].size() <= in.innerIdx){
        if(debugMode) std::cout << "Bad Edit Attributes: Inner Table out of bound\n";
        exit(1);
    }

    //replace whole attributes based on the entry
    this->entryAttributesCol[in.symTableIdx][in.innerIdx] = entry;
}

/*Returns new index id, otherwise -1 (NIL) if already exist
Note that for dynamic attributes, it is considered to be initialized in the yacc*/
struct IdxPair SymbolTables::Insert(const char* name, int debugMode){
    if (this->symbolTables.size() < 1){
        if(debugMode) std::cout << "Bad Insert: No Symbol Tables exist\n";
        exit(1);
    }

    std::string goal = name;
    struct IdxPair tmp;    
    //the most important thing is it has not declared on the last symbol table
    int curIdx = this->symbolTables.size() - 1;
    strcpy(tmp.varName, name);
    if(this->symbolTables[curIdx].find(goal) != this->symbolTables[curIdx].end()){
        //exist, error return NIL
        if(debugMode) std::cout << "Bad Insert: ID already exist\n";
        tmp.symTableIdx = NIL;
        tmp.innerIdx = NIL;
        return tmp;
    }else{
        int curLength = this->symbolTables[curIdx].size();
        this->symbolTables[curIdx][goal] = curLength;
        //insert vanilla entry Attributes item
        struct EntryAttributes vanilla;
        this->entryAttributesCol[curIdx].push_back(vanilla);
        //return index
        tmp.symTableIdx = curIdx;
        tmp.innerIdx = curLength;
        return tmp;
    }
}

int SymbolTables::GetNextLocalVariableNumber(int debugMode){
    if(nextVariableCounter.size() < 1){
        std::cout << "Error in getting next local variable number, next variable counter is 0\n";
        exit(1);
    }
    int returnVal = nextVariableCounter[nextVariableCounter.size() - 1];
    return returnVal;
}

int SymbolTables::GetNextLocalVariableNumberAndIncrement(int debugMode){
    int returnVal = GetNextLocalVariableNumber(debugMode);
    nextVariableCounter[nextVariableCounter.size() - 1] += 1;
    return returnVal;
}

int SymbolTables::ModifyLocalVariableNumber(IdxPair varLoc, int debugMode){
    EntryAttributes ea = FromIdxPairReturnAttributes(varLoc, debugMode);
    //only modify if it is of type variable, and local
    if(varLoc.symTableIdx > 0 && ea.entryType == VAR_ENTTYPE){
        int currentNumber = GetNextLocalVariableNumberAndIncrement(debugMode);
        int nextNumber = GetNextLocalVariableNumber(debugMode);

        //modify entry attributes
        ea.localVariableNumber = currentNumber;
        EditAttributesOnIndex(varLoc, ea, debugMode);
        //print the insertion info
        if(doInsertInfoAndDumpLastEntryDuringPopProject3){
            std::string varName = varLoc.varName;
            std::cout << varName << " = " << currentNumber << ", next number " << nextNumber << "\n";
        }
    }
}

//helper function, to print content of entry type, does not end with endline
void entryTypePrintingHelper(enum EntryType a, std::string header){
    if(a == VAR_ENTTYPE){
        std::cout << header << "EntryType: Var";
    }else if(a == CONST_ENTTYPE){
        std::cout << header << "EntryType: Const";
    }else if(a == ARRAY_ENTTYPE){
        std::cout << header << "EntryType: Array";
    }else if(a == FUNCTION_ENTTYPE){
        std::cout << header << "EntryType: Function/Procedure";
    }else{
        std::cout << header << "Undefined EntryType";
    }
}

//helper function, to print content of type, does not end with endline
void typePrintingHelper(enum Type a, std::string header){
    if(a == INTEGER_TYPE){
        std::cout << header << "Type: int";
    }else if(a == DOUBLE_TYPE){
        std::cout << header << "Type: real";
    }else if(a == STRING_TYPE){
        std::cout << header<< "Type: string";
    }else if(a == BOOL_TYPE){
        std::cout << header << "Type: bool";
    }else if(a == VOID_TYPE){
        std::cout << header << "Type: Void";
    }else{
        std::cout << header << "Undefined Type";
    }
}

//helper function, to print content of params type, does not end with endline
void paramsTypePrintingHelper(enum ParamsType a, int arrLength, std::string header){
    if(a == IPARAM){
        std::cout << header << "ParamsType: int";    
    }else if(a == DPARAM){
        std::cout << header << "ParamsType: real";    
    }else if(a == SPARAM){
        std::cout << header << "ParamsType: string";    
    }else if(a == BPARAM){
        std::cout << header << "ParamsType: bool";    
    }else if(a == IARRPARAM){
        std::cout << header << "ParamsType: int arr " << arrLength;    
    }else if(a == DARRPARAM){
        std::cout << header << "ParamsType: real arr " << arrLength;    
    }else if(a == BARRPARAM){
        std::cout << header << "ParamsType: bool arr " << arrLength;    
    }else{
        std::cout << header << "Undefined ParamsType";
    }
}

// helper function, to print content of symbol table entry Attributes, does not end with endline
void entryAttributesPrintingHelper(EntryAttributes in){
    //printing each one of the content for debugging:
    
    //entry type
    std::string tidyTab = "\t";
    entryTypePrintingHelper(in.entryType, tidyTab);
    std::cout << "\n";

    // declared on which line
    std::cout << tidyTab << "declared on line: " << in.declaredLine << "\n";

    //varConstOrResType
    typePrintingHelper(in.varConstOrResType, tidyTab);
    std::cout << "\n";

    //value of variable
    if(in.entryType == VAR_ENTTYPE || in.entryType == CONST_ENTTYPE){
        if(symbolTableStoreValue){
            if(in.varConstOrResType == INTEGER_TYPE){
                std::cout << tidyTab << "iVal: " << in.iVal << "\n";
            }
            else if(in.varConstOrResType == DOUBLE_TYPE){
                std::cout << tidyTab << "dVal: " << in.dVal << "\n";
            }
            else if(in.varConstOrResType == BOOL_TYPE){
                std::cout << tidyTab << "boolVal: " << in.boolVal << "\n";
            }
            else if(in.varConstOrResType == STRING_TYPE){
                std::cout << tidyTab << "sVal: " << in.sVal << "\n";
            }else{
                std::cout << tidyTab << "invalid varConstOrResType\n";
            }
        }
    }

    //it is regarded that array must always be assigned, so all the memory should have dynamically allocated
    if(in.entryType == ARRAY_ENTTYPE){
        std::cout << tidyTab << "arr length: " << in.arrLength << "\n";
        std::cout << tidyTab << "startindices: " << in.startIndices << "\n";
        std::cout << tidyTab << "endIndices: " << in.endIndices << "\n"; 
    }

    //procedure is also considered as function
    if(in.entryType == FUNCTION_ENTTYPE){
        std::cout << tidyTab << "params length: " << in.paramsLength << "\n";
        std::cout << tidyTab << "params content: ";
        for(int idx =0; idx < in.paramsLength; idx++){
            paramsTypePrintingHelper(in.paramsOrdering[idx], in.eachParamsHowManyElements[idx], "");
            std::cout << " ";
        }
        std::cout << "\n";
    }

    //unless it is local variable, the next value will always be -1
    std::cout << tidyTab << "localVariableNumber: " << in.localVariableNumber << "\n";
}

// helper function, to print content of symbol table entry Attributes, on the last scope, this function is also contained inside PopBack
int SymbolTables::DumpLast(int debugMode){
    if (this->symbolTables.size() < 1){
        if(debugMode) std::cout << "Bad Dump: No Symbol Tables exist\n";
        exit(1);
    }
    else{
        //printing the symbol table only on last index
        int curIdx =this->symbolTables.size()-1;
        std::cout << "Last symbol table: \n";
            
        /* Printing alphabetically*/
        /* 
        for(auto i = this->symbolTables[curIdx].begin(); i != this->symbolTables[0].end(); i++){
            std::cout << i->first << "--" << i->second << "\n";
        }
        */

        /* Printing based on index (brute force)*/
        int temp = 0;
        int sze = this->symbolTables[curIdx].size();
        if(temp < sze){
            std::cout << "Last symbol table: \n";
        }
        while(temp < sze){
            int found = 0;
            for(auto i = this->symbolTables[curIdx].begin(); i != this->symbolTables[curIdx].end(); i++){
                if(i->second == temp){
                    std::cout << i->first << "--" << i->second << "\n";
                    entryAttributesPrintingHelper(this->entryAttributesCol[curIdx][temp]);
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
        
        return this->symbolTables.size();
    }
}

/*Dumps all entries of the symbol table on first vector, return length*/
int SymbolTables::Dump(int debugMode){
    if (this->symbolTables.size() < 1){
        if(debugMode) std::cout << "Bad Dump: No Symbol Tables exist\n";
        exit(1);
    }
    else{
        //printing the symbol table from the index 0 to last index
        int curIdx = 0;
        while(curIdx < this->symbolTables.size()){
            std::cout << "Symbol Table " << curIdx << ": \n";
            std::cout << "Variables--Index\n";
            
            /* Printing alphabetically*/
            /* 
            for(auto i = this->symbolTables[curIdx].begin(); i != this->symbolTables[0].end(); i++){
                std::cout << i->first << "--" << i->second << "\n";
            }
            */

            /* Printing based on index (brute force)*/
            int temp = 0;
            int sze = this->symbolTables[curIdx].size();
            while(temp < sze){
                int found = 0;
                for(auto i = this->symbolTables[curIdx].begin(); i != this->symbolTables[curIdx].end(); i++){
                    if(i->second == temp){
                        std::cout << i->first << "--" << i->second << "\n";
                        entryAttributesPrintingHelper(this->entryAttributesCol[curIdx][temp]);
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
            curIdx++;
        }
        
        return this->symbolTables.size();
    }
}

//For proj3 format to print entry attributes
void entryAttributesPrintingHelperProj3(std::string tidyTab, std::string variableName, EntryAttributes in){
    //only print if it is local variable
    if(in.entryType == VAR_ENTTYPE){
        std::cout << tidyTab << "<";
        std::cout << "\"" << variableName << "\n";
        std::cout << ", variable, ";
        if(in.varConstOrResType == INTEGER_TYPE){
            std::cout << "integer, ";
        }else if(in.varConstOrResType == DOUBLE_TYPE){
            std::cout << "real, ";
        }else if(in.varConstOrResType == BOOL_TYPE){
            std::cout << "bool, ";
        }else if(in.varConstOrResType == STRING_TYPE){
            std::cout << "string, ";
        }else if(in.varConstOrResType == VOID_TYPE){
            std::cout << "Error in dumping! variable type should not have void entry\n";
            exit(1);
        }
        std::cout << in.localVariableNumber;
        std::cout << ">\n";
    }
}

void proj3EntryAttributesVariablePrintingHelper(std::string tidyTab, std::string varname, EntryAttributes in, int debugMode){
    std::string intype = "integer";
    if(in.varConstOrResType == STRING_TYPE){
        intype = "string";
    }else if(in.varConstOrResType == DOUBLE_TYPE){
        intype = "real";
    }else if(in.varConstOrResType == BOOL_TYPE){
        intype = "bool";
    }else if(in.varConstOrResType == VOID_TYPE){
        intype = "void";
    }
    std::string enttype = "variable";
    if(in.entryType == CONST_ENTTYPE){
        enttype = "const";
    }
    else if(in.entryType == FUNCTION_ENTTYPE){
        enttype = "Function";
        if(in.varConstOrResType == VOID_TYPE){
            enttype = "Procedure";
        }
    }else if(in.entryType == ARRAY_ENTTYPE){
        enttype = "Array";
    }
    std::cout << tidyTab << "<\"" << varname<< "\", " << enttype << ", " << intype << ", " << in.localVariableNumber <<">\n";
}

//only print variables entry
int SymbolTables::DumpLastProj3(int debugMode){
    if (this->symbolTables.size() < 1){
        if(debugMode) std::cout << "Bad Dump: No Symbol Tables exist\n";
        exit(1);
    }
    else{
        //printing the symbol table only on last index
        int curIdx =this->symbolTables.size()-1;
        std::cout << "Last symbol table: \n";
            
        /* Printing alphabetically*/
        /* 
        for(auto i = this->symbolTables[curIdx].begin(); i != this->symbolTables[0].end(); i++){
            std::cout << i->first << "--" << i->second << "\n";
        }
        */

        /* Printing based on index (brute force)*/
        int temp = 0;
        int sze = this->symbolTables[curIdx].size();
        while(temp < sze){
            int found = 0;
            for(auto i = this->symbolTables[curIdx].begin(); i != this->symbolTables[curIdx].end(); i++){
                if(i->second == temp){
                    proj3EntryAttributesVariablePrintingHelper("\t", i->first, this->entryAttributesCol[curIdx][temp], debugMode);
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
        
        return this->symbolTables.size();
    }
}