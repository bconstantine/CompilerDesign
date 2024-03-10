#ifndef COMMON_DS_H
#define COMMON_DS_H
#include "stdio.h"
// common data structure that is used inside Symbol table, for both C and C++
#define MAX_STR_LENGTH 256 //maximum number of string content that can be stored. This number is chosen because parser can only parse 256 line
#define NIL -1 //IdxPair will set all int value to NIL if result is not found

extern int debugMode; //set 1 to print the error message of symbol table, set 0 to not print

extern int linenum; //current line number, communicate between yacc and lex

extern int doDumpLastEntryDuringPop; //during pop back of scope, dump the last scope entry before pop back

extern int doInsertInfoAndDumpLastEntryDuringPopProject3; //same as previous, but follow project 3 format (dump last and insert information)

extern int symbolTableStoreValue; //whether symbol table store value, currently there is problem, that is if:
                                  //    - in if, whether it is entered or not, the value will be updated
                                  //      in function, whether it is called or not, the value will be updated
                                  //      in loop and for, whether it is called or not, the value will be updated

extern int errorExist; //whether error exist in the middle when writing code, in which code writing will stop

extern int putCanPrintExpression;   //put can print the expression
extern int getCanScanfIdentifier;   //get can scanf identifier (and store the value in symbol table if enabled) if getCanScanfIdenifier is on

extern int constIntExprCanCheckIndexValidity;   //when expression contains array access index that access an array is const, it checks for index validity

extern int writeCommentToJasm; // This might cause problem, when writing / (/*12 / 3*/)

/*Indices inside symbol table, and also the variable name, this entry will be used for
- passing value from Lex to Yacc
- Telling the program which is the location of an entry in symbol table between yacc operations*/
struct IdxPair{
    int symTableIdx;
    int innerIdx;
    char varName[MAX_STR_LENGTH]; //needed to insert entry in yacc, lex will only search the index
};

/*Type, used for type of an expression, entry in symbol table, and return/result of a function.
Does not differentiate whether it is an array or not

DOUBLE_TYPE is the same as real type, I forgot to change it in midway doing it and changing everything is too cubbersome*/
enum Type{
    INTEGER_TYPE, 
    DOUBLE_TYPE, 
    STRING_TYPE, 
    BOOL_TYPE, 
    VOID_TYPE, //only used if type is procedure, for return type
};

/*Differentiate each entry type of symbol table*/
enum EntryType{
    VAR_ENTTYPE,
    CONST_ENTTYPE,  
    ARRAY_ENTTYPE,
    FUNCTION_ENTTYPE, //or procedure, same
};

/*If the entry is function, I am going to differentiate the parameter type ordering using this*/
enum ParamsType{
    IPARAM, //int
    DPARAM, //double
    SPARAM, //string
    BPARAM, //bool
    IARRPARAM, //integer array 
    DARRPARAM, //double array 
    BARRPARAM, //bool array param
};

/*Similar to Type, but added differentiation if expression is an array to different type, 
I do this because I realize in midway I need to do differentiate expression is an array, but changing all the type to ExprType is cubbersome

This is also similar to ParamsType, but I do not merge it due to the same reason*/
enum ExprType{
    IEXPR, //int
    DEXPR, //double
    SEXPR, //string
    BEXPR, //bool
    VEXPR, //void (e.g. return from procedure)
    IARREXPR, //integer array 
    DARREXPR, //double array 
    BARREXPR, //bool array param
};

/*Notice the comment, not all value is required to be filled (so struct is actually sparse),
based on enum EntryType, some of the variable inside the struct will left unevaluated
I cant use STL in any of the contents because this datatype is also used in C*/
struct EntryAttributes{
    //what is this entry?
    enum EntryType entryType;
    int declaredLine; // which line declare this entry?
    
    //only used if this is variable
    //value is using individual variables to avoid union
    int iVal;
    double dVal;
    char sVal[MAX_STR_LENGTH];
    int boolVal;

    //if it is an array entry
    //array can't store value
    int arrLength; //for easy access limit
    int startIndices;
    int endIndices; // although this is equal startIndices + arrLength - 1, defined here for future operation call simplicity

    //variable, const, or func result type)
    enum Type varConstOrResType;

    //if it is a function, list the ordering of the type
    int paramsLength; //for easy access limit
    enum ParamsType* paramsOrdering; //a pointer to a dynamic array that list the suitable params type ordering of a function
    int* eachParamsHowManyElements; //this one is only used if function parameter is an array. Since by the PDF we can only say An array is the same type of each element type and element number is the same
                                    //one to one mapping with paramsOrdering, even if the ParamsType is not array (so just set to any number)
                                    //if the corresponding params is var, set value to 1


    //additional info for project 3
    //only fill if the variable is not global
    int localVariableNumber;
};


//will be used when evaluating an expression non terminal
struct expr{
    enum ExprType exprType; 
    int isError;
    //whether it is a constant expr (not including any identifiers, except const identifier)
    int isConst;
    //involving function, or right now also array element access
    int isFunc;

    
    //if it is an array, then this will store the arrLength
    int arrLength; //because type compatible just needs for array to have the same length type
                    //set to 1 if current expression is not an array

    //only used if it is not an array
    int iVal; //int value
    double dVal; //double value
    char sVal[MAX_STR_LENGTH]; //string value
    int boolVal; //boolean value
};

//will be used when evaluating function argument during function call or declaration
struct ArgAccumulation{
    int paramsLength; //for easy access limit
    enum ParamsType* paramsOrdering; //each parameter types
    int* eachParamsHowManyElements; //each parameter how many elements (just in case array)
    int isEncounterError; //encounter error along the way? if it does do not initialize the function / function call fail
};

//will be used when track the function result type
struct ResultTracker{
    int resultAmount; //amount of result exist in the function
    int* linenumResult; //there may be multiple return, track each one of the line number
    enum ExprType* resultType; //since there may be multiple return, also track each return type
    int* exprIsError; //whether the resulted expression is an error
};

//will be used when passing the information on what lies on the right hand side of identifier call in expression
enum RightHandSideType{
    IS_EMPTY,
    IS_FUNCTION_CALL, 
    IS_ARRAY_CALL
};

struct RightOfIdentifierInformation{
    enum RightHandSideType rightHandSideSpec;
    
    //if it is an IS_FUNCTION_CALL, this will be used
    struct ArgAccumulation argAcc;

    //If it is IS_ARRAY_CALL, pass these info
    struct expr arrayRHSIntExpr;
};

#endif 