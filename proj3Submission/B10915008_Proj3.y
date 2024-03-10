%{
#include "codeMakerAPI.h"
#include "symbolTableAPIFix.h" // symbol table  in C++ plus Data Structure implemented for Yacc and Lex altogether, especially for yylval purposes
#include "commonDataStructure.h"
#define Trace(t) if (Opt_Print) printf(t)
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int Opt_Print = 0;
void yyerror(const char *s); 
extern FILE *yyin; 

// use in a function to keep track result statement in scope
struct ResultTracker functionResultTracker;

// global variable to track the start lineof functionDeclaration
int functionStartLine = 0;

int inAFunction = 0; // for printing error message when meeting result not in a function scope, value is only 1 or 0 since no nested function
int inAProcedure = 0; //for printing error message when meeting return not in a procedure scope. value is only 1 or 0 since no nested procedure
int inALoopOrFor = 0; //for printing error message when meething skip or exit not in a loop scope, value is 0 or more, based on the nested loop or for amount

/*Helpers to set default value to structs that is safe*/
struct IdxPair defaultIdxPairValue(){
    struct IdxPair a;
    a.symTableIdx = -1;
    a.innerIdx = -1;
    strcpy(a.varName, "");
    return a;
}

struct EntryAttributes defaultEntryAttributesValue(){
    struct EntryAttributes a;
    a.entryType = VAR_ENTTYPE;
    a.declaredLine = 0;
    
    a.iVal = 0;
    a.dVal = 0;
    strcpy(a.sVal,"");
    a.boolVal=0;
    a.arrLength = 1;
    a.startIndices = 0;
    a.endIndices = 0; 

    a.varConstOrResType = INTEGER_TYPE;

    a.paramsLength = 0; 
    a.paramsOrdering = NULL; 
    a.eachParamsHowManyElements = NULL; 

    a.localVariableNumber = -1;
    return a;
}

struct expr defaultExprValue(){
    struct expr a;
    a.exprType = IEXPR;
    a.isError = 0;
    a.isConst = 0;
    a.isFunc = 0;
    a.arrLength = 1; 

    a.iVal = 0; 
    a.dVal = 0;
    strcpy(a.sVal, "");
    a.boolVal = 0;
    return a;
}

struct ArgAccumulation defaultArgAccumulationValue(){
    struct ArgAccumulation a;
    a.paramsLength = 0;
    a.isEncounterError = 0;
    a.paramsOrdering = NULL;
    a.eachParamsHowManyElements = NULL;
    return a;
}

struct ResultTracker defaultResultTrackerValue(){
    struct ResultTracker a;
    a.resultAmount = 0; 
    a.linenumResult = NULL; 
    a.resultType = NULL; 
    a.exprIsError = NULL; 
    return a;
}

struct RightOfIdentifierInformation defaultRightOfIdentifierInformationValue(){
    struct RightOfIdentifierInformation a;
    a.rightHandSideSpec = IS_EMPTY;
    a.argAcc = defaultArgAccumulationValue();
    a.arrayRHSIntExpr = defaultExprValue();
    return a;
}

enum Type defaultTypeValue(){
    return INTEGER_TYPE;
}

/* Printing helpers
    Although some of these functions is the same with that in symbolTableFix.cpp, but some of them include string in the parameter, which might cause error during printing
    That is why some of I redeclare it here
*/
void typePrintingHelperInC(enum Type a){
    if(a == INTEGER_TYPE){
        printf("Type: int");
    }else if(a == DOUBLE_TYPE){
        printf("Type: real");
    }else if(a == STRING_TYPE){
        printf("Type: string");
    }else if(a == BOOL_TYPE){
        printf("Type: bool");
    }else if(a == VOID_TYPE){
        printf("Type: Void");
    }else{
        printf("Undefined Type");
    }
}

void paramsTypePrintingHelperInC(enum ParamsType a, int paramsHowManyElemens){
    if(a == IPARAM){
        printf("Int");
    }else if(a == DPARAM){
        printf("Real");
    }else if(a == SPARAM){
        printf("String");
    }else if(a == BPARAM){
        printf("Bool");
    }else if(a == IARRPARAM){
        printf("Int array with %i element", paramsHowManyElemens);
    }else if(a == DARRPARAM){
        printf("Real array with %i element", paramsHowManyElemens);
    }else if(a == BARRPARAM){
        printf("Bool array with %i element", paramsHowManyElemens);
    }
}

void exprTypePrintingHelper(enum ExprType a, int arrLength){
    if(a == IEXPR){
        printf("Int");
    }else if(a == DEXPR){
        printf("Real");
    }else if(a == SEXPR){
        printf("String");
    }else if(a == BEXPR){
        printf("Bool");
    }else if(a == VEXPR){
        printf("Void");
    }else if(a == IARREXPR){
        printf("Int array with %i element", arrLength);
    }else if(a == DARREXPR){
        printf("Real array with %i element", arrLength);
    }else if(a == BARREXPR){
        printf("Bool array with %i element", arrLength);
    }
}

// same with exprTypePrintingHelper but do not declare array length when printing
void exprTypePrintingNoArrayLengthHelper(enum ExprType a){
    if(a == IEXPR){
        printf("Int");
    }else if(a == DEXPR){
        printf("Real");
    }else if(a == SEXPR){
        printf("String");
    }else if(a == BEXPR){
        printf("Bool");
    }else if(a == VEXPR){
        printf("Void");
    }else if(a == IARREXPR){
        printf("Int array");
    }else if(a == DARREXPR){
        printf("Real array");
    }else if(a == BARREXPR){
        printf("Bool array");
    }
}

int exprIsArray(enum ExprType a){
    return a == IARREXPR || a == BARREXPR || a == DARREXPR;
}

int identifierNotExistInThisScopeChecker(struct IdxPair identifierPos){
    return (identifierPos.symTableIdx == -1 && identifierPos.innerIdx == -1) || (identifierPos.symTableIdx+1) < symbolTableScopeSize(debugMode);
}

int identifierNotExistInAllScopeChecker(struct IdxPair identifierPos){
    return (identifierPos.symTableIdx == -1 && identifierPos.innerIdx == -1);
}

int identifierIsLocal(struct IdxPair identifierPos){
    if(identifierPos.symTableIdx > 0){
        return 1;
    }else{
        return 0;
    }
}

int identifierIsGlobal(struct IdxPair identifierPos){
    return !(identifierIsLocal(identifierPos));
}

//sometimes it is needed to translate from ExprType to Type, then this function will be used
//this is because I use different enumeration between expression type and types inside symbol table
enum Type translatorExprType(enum ExprType a){
    if(a == IEXPR || a == IARREXPR){
        return INTEGER_TYPE;
    }else if(a == BEXPR || a == BARREXPR){
        return BOOL_TYPE;
    }else if (a == DEXPR || a == DARREXPR){
        return DOUBLE_TYPE;
    }else{
        return STRING_TYPE;
    }
}

//whether can store value or not in an symbol table, based on the feature type
//this is a plus point feature, not mentioned inside powerpoint
int canStoreValueInSymbolTable(struct expr exprSpec){
    return (symbolTableStoreValue) || exprSpec.isConst;
}


int arrayIndexValidityChecker(struct EntryAttributes arrAttributes, int index){
    return(arrAttributes.startIndices <= index && arrAttributes.endIndices >= index);
}

//To check ther variable (NOT ARRAY) arguments inside a function
//isDeclaration: 1 if this is a declaration, 0 if it is part of a function call
//identifierPos: Argument Identifier specification for declaration
//varType: type of Argument identifier that is going to use for declaration
//followUpArguments, the list of arguments that come after it (because argument is in left recursion)
//int linenum: current linenum
//callExprIsError: if current parameters expr for function is an error
struct ArgAccumulation functionVarArgumentChecker(int isDeclaration, struct IdxPair identifierPos, enum Type varType, struct ArgAccumulation followUpArguments, int linenum, int callExprIsError){
    struct ArgAccumulation resultArgument = defaultArgAccumulationValue();
    char errorMessageHelper[256] = "Call";
    if(isDeclaration){
        strcpy(errorMessageHelper, "Declaration");
    }
    if(!isDeclaration || identifierNotExistInThisScopeChecker(identifierPos)){
        // if it is a declaration, we need to make sure that no duplicate argument identifier
        if(followUpArguments.isEncounterError || (!isDeclaration && callExprIsError)){
            // the arguments that follows it is already an error, no need to continue
            resultArgument.isEncounterError = 1;
            
            resultArgument.paramsLength=0;
            //free dynamic variables if needed
            if(!followUpArguments.isEncounterError){
                free(followUpArguments.paramsOrdering);
                free(followUpArguments.eachParamsHowManyElements);
            }
        }else{
            //append the result of FunctionArgFollowUp to the current one if the length is more than zero
            resultArgument.isEncounterError = 0;
            resultArgument.paramsLength = followUpArguments.paramsLength + 1;
            resultArgument.paramsOrdering = (enum ParamsType*) calloc(resultArgument.paramsLength, sizeof(enum ParamsType));
            resultArgument.eachParamsHowManyElements = (int*) calloc(resultArgument.paramsLength, sizeof(int));

            
            if(followUpArguments.paramsLength > 0){
                // input the trailing parameter
                for(int idx = 0; idx < followUpArguments.paramsLength; idx++){
                    resultArgument.paramsOrdering[idx] = followUpArguments.paramsOrdering[idx];
                    resultArgument.eachParamsHowManyElements[idx] = followUpArguments.eachParamsHowManyElements[idx];
                }
                //deallocate the trailing parameter dynamic memory
                free(followUpArguments.paramsOrdering);
                free(followUpArguments.eachParamsHowManyElements);
            }

            //set the first entry as the result current variable
            if(varType == INTEGER_TYPE){
                resultArgument.paramsOrdering[followUpArguments.paramsLength] = IPARAM;
                resultArgument.eachParamsHowManyElements[followUpArguments.paramsLength] = 1; //since this is not an array
            }else if (varType == DOUBLE_TYPE){
                resultArgument.paramsOrdering[followUpArguments.paramsLength] = DPARAM;
                resultArgument.eachParamsHowManyElements[followUpArguments.paramsLength] = 1; //since this is not an array
            }else if (varType == STRING_TYPE){
                resultArgument.paramsOrdering[followUpArguments.paramsLength] = SPARAM;
                resultArgument.eachParamsHowManyElements[followUpArguments.paramsLength] = 1; //since this is not an array
            }else if(varType == BOOL_TYPE){
                resultArgument.paramsOrdering[followUpArguments.paramsLength] = BPARAM;
                resultArgument.eachParamsHowManyElements[followUpArguments.paramsLength] = 1; //since this is not an array
            }else{
                // program should not enter here, if it does something is wrong with your program
                printf("SelfError %d: Something is wrong with the program, it should not enter here, encounter type: ", linenum);
                errorExist = 1;
                typePrintingHelperInC(varType);
                printf("\n");
            }
        }
        if(isDeclaration){
            //if it is declaration nevertheless it is an error or not, keep on inserting the current variable into the symbol table
            //assume that the value is already initialized, but set all the default value to empty
            struct EntryAttributes in = defaultEntryAttributesValue();
            in.entryType = VAR_ENTTYPE;
            in.declaredLine = linenum;
            if(varType == INTEGER_TYPE){
                in.iVal = 0; //just to avoid error
                in.varConstOrResType = INTEGER_TYPE;
                // insert to local symbol table
                struct IdxPair entryPosition = insert(identifierPos.varName, debugMode);
                editAttributesOnIndex(entryPosition, in, debugMode);
                ///////WRITE CODE SECTION
                modifyLocalVariableNumber(entryPosition, debugMode);
                /////////////////////////
            }else if(varType == DOUBLE_TYPE){
                in.dVal = 0.0; //just to avoid error
                in.varConstOrResType = DOUBLE_TYPE;
                // insert to local symbol table
                struct IdxPair entryPosition = insert(identifierPos.varName, debugMode);
                editAttributesOnIndex(entryPosition, in, debugMode);
                ///////WRITE CODE SECTION
                modifyLocalVariableNumber(entryPosition, debugMode);
                encounterUnableToExpress(&errorExist, "float function/procedure argument", linenum);
                /////////////////////////
            }else if(varType == STRING_TYPE){
                strcpy(in.sVal, ""); //just to avoid error
                in.varConstOrResType = STRING_TYPE;
                // insert to local symbol table
                struct IdxPair entryPosition = insert(identifierPos.varName, debugMode);
                editAttributesOnIndex(entryPosition, in, debugMode);
                ///////WRITE CODE SECTION
                modifyLocalVariableNumber(entryPosition, debugMode);
                encounterUnableToExpress(&errorExist, "string function/procedure argument", linenum);
                /////////////////////////
            }else if(varType == BOOL_TYPE){
                in.boolVal = 0; //just to avoid error
                in.varConstOrResType = BOOL_TYPE;
                // insert to local symbol table
                struct IdxPair entryPosition = insert(identifierPos.varName, debugMode);
                editAttributesOnIndex(entryPosition, in, debugMode);
                ///////WRITE CODE SECTION
                modifyLocalVariableNumber(entryPosition, debugMode);
                /////////////////////////
            }else{
                // program should not enter here, if it does something is wrong with your program
                printf("SelfError %d: Something is wrong with the program, it should not enter here, encounter type: ", linenum);
                errorExist = 1;
                typePrintingHelperInC(varType);
                printf("\n");
            }
        }
    }else
    {
        //point out that same argument identifier is already declared, and function declaration is an error
        struct EntryAttributes alreadyExist = fromIdxPairReturnAttributes(identifierPos, debugMode);
        printf("Error %d: Argument %s %s failed due to duplicate identifier already declared at line %i, not saving to symbol table\n", linenum, errorMessageHelper,identifierPos.varName, alreadyExist.declaredLine);
        errorExist = 1;
        resultArgument.isEncounterError = 1;
        resultArgument.paramsLength=0;
        //deallocate the FunctionArgFollowUp if it is not an error
        //to unallocated memory
        if(followUpArguments.isEncounterError == 0 && followUpArguments.paramsLength > 0){
            free(followUpArguments.paramsOrdering);
            free(followUpArguments.eachParamsHowManyElements);
        }
    }
    return resultArgument;
}

//same with previous function, but do the case for ARRAY argument
//isDeclaration: 1 if this is a declaration, 0 if it is part of a function call
//identifierPos: Identifier specification for declaration
//varType: type of identifier that is going to use for declaration
//startIndices: start index of the array
//endIndices: end index of the array
//followUpArguments, the list of arguments that come after it (because argument is in left recursion)
//int linenum: current linenum
//callExprIsError: if current parameters expr for function is an error
struct ArgAccumulation functionArrayArgumentChecker(int isDeclaration, struct IdxPair identifierPos, enum Type varType, int startIndices, int endIndices, struct ArgAccumulation followUpArguments, int linenum, int callExprIsError){
    struct ArgAccumulation resultArgument = defaultArgAccumulationValue();
    ///////WRITE CODE SECTION
    encounterUnableToExpress(&errorExist, "array function/procedure argument", linenum);
    /////////////////////////
    //check the index correctness
    int correctStartIndices = startIndices;
    int correctEndIndices = endIndices;
    if(!isDeclaration || identifierNotExistInThisScopeChecker(identifierPos)){
        // if it is a declaration, we need to make sure that no duplicate argument identifier
        if(followUpArguments.isEncounterError || (!isDeclaration && callExprIsError)){
            // no need to continue, as the trailing parameter listing is already an error
            resultArgument.isEncounterError = 1;
            resultArgument.paramsLength = 0;
            //free dynamic variables if needed
            if(!followUpArguments.isEncounterError){
                free(followUpArguments.paramsOrdering);
                free(followUpArguments.eachParamsHowManyElements);
            }

            //check index correctness, although this is an error, also fix the index because in the future nevertheless I will still insert to symbol table to check for duplicate naming
            if(correctStartIndices > correctEndIndices){
                int temp = correctStartIndices;
                correctStartIndices = correctEndIndices;
                correctEndIndices = temp;
                resultArgument.isEncounterError = 1;
            }
        }else{
            resultArgument.isEncounterError = 0;
            if(correctStartIndices > correctEndIndices){
                //index is invalid, corrent the index because it will be inserted to local symbol table for duplicate checking, to avoid possible error

                int temp = correctStartIndices;
                correctStartIndices = correctEndIndices;
                correctEndIndices = temp;
                resultArgument.isEncounterError = 1;
                resultArgument.paramsLength = 1;
                //previously here followUpArguments is not an error, that means dynamic variable still intact, free them
                if(followUpArguments.paramsLength > 0){
                    free(followUpArguments.paramsOrdering);
                    free(followUpArguments.eachParamsHowManyElements);
                }
            }else{
                //everything is correct
                //append the result of FunctionArgFollowUp to the current one if the length is more than zero
                resultArgument.paramsLength = followUpArguments.paramsLength + 1;
                resultArgument.paramsOrdering = (enum ParamsType*) calloc(resultArgument.paramsLength, sizeof(enum ParamsType));
                resultArgument.eachParamsHowManyElements = (int*) calloc(resultArgument.paramsLength, sizeof(int));
                
                if(followUpArguments.paramsLength > 0){
                    // input the trailing parameter
                    for(int idx = 0; idx < followUpArguments.paramsLength; idx++){
                        resultArgument.paramsOrdering[idx] = followUpArguments.paramsOrdering[idx];
                        resultArgument.eachParamsHowManyElements[idx] = followUpArguments.eachParamsHowManyElements[idx];
                    }
                }
                
                //set the first entry as the result current variable
                if(varType == INTEGER_TYPE){
                    resultArgument.paramsOrdering[followUpArguments.paramsLength] = IARRPARAM;
                    resultArgument.eachParamsHowManyElements[followUpArguments.paramsLength] = correctEndIndices - correctStartIndices + 1; //since this is not an array
                }else if (varType == DOUBLE_TYPE){
                    resultArgument.paramsOrdering[followUpArguments.paramsLength] = DARRPARAM;
                    resultArgument.eachParamsHowManyElements[followUpArguments.paramsLength] = correctEndIndices - correctStartIndices + 1; //since this is not an array
                }else if (varType == STRING_TYPE){
                    resultArgument.isEncounterError = 1;
                    resultArgument.paramsLength = 1;
                    printf("Error %d: Argument declaration %s failed due to string array is not allowed\n", linenum, identifierPos.varName);
                    errorExist = 1;
                    free(resultArgument.paramsOrdering);
                    free(resultArgument.eachParamsHowManyElements);
                }else if(varType == BOOL_TYPE){
                    resultArgument.paramsOrdering[followUpArguments.paramsLength] = BARRPARAM;
                    resultArgument.eachParamsHowManyElements[followUpArguments.paramsLength] = correctEndIndices - correctStartIndices + 1; //since this is not an array
                }else{
                    // program should not enter here, if it does something is wrong with your program
                    printf("SelfError %d: Something is wrong with the program, it should not enter here, encounter type: ", linenum);
                    errorExist = 1;
                    typePrintingHelperInC(varType);
                    printf("\n");
                }

                if(followUpArguments.isEncounterError == 0 && followUpArguments.paramsLength > 0){
                    //deallocate the trailing parameter dynamic memory
                    free(followUpArguments.paramsOrdering);
                    free(followUpArguments.eachParamsHowManyElements);
                }
            }
        }
        if(isDeclaration){
            //if declaration, nevertheless it is an error or not, keep on inserting the current variable into the symbol table
            struct EntryAttributes in = defaultEntryAttributesValue();
            //////////////WRITE CODE SECTION
            ///No need to put local variable number real value
            ////////////////////////////////
            in.entryType = ARRAY_ENTTYPE;
            in.declaredLine = linenum;
            in.arrLength = correctEndIndices - correctStartIndices + 1;
            in.startIndices = correctStartIndices;
            in.endIndices = correctEndIndices;
            if(varType == INTEGER_TYPE){
                in.varConstOrResType = INTEGER_TYPE;
                struct IdxPair entryPosition = insert(identifierPos.varName, debugMode);
                editAttributesOnIndex(entryPosition, in, debugMode);
            }else if(varType == DOUBLE_TYPE){
                in.varConstOrResType = DOUBLE_TYPE;
                // insert to local symbol table
                struct IdxPair entryPosition = insert(identifierPos.varName, debugMode);
                editAttributesOnIndex(entryPosition, in, debugMode);
            }else if(varType == STRING_TYPE){
                printf("Error %d: Argument declaration %s failed due to string array is not allowed, not pushing to symbol table\n", linenum, identifierPos.varName);
                errorExist = 1;
            }else if(varType == BOOL_TYPE){
                in.varConstOrResType = BOOL_TYPE;
                // insert to local symbol table
                struct IdxPair entryPosition = insert(identifierPos.varName, debugMode);
                editAttributesOnIndex(entryPosition, in, debugMode);
            }else{
                // program should not enter here, if it does something is wrong with your program
                printf("SelfError %d: Something is wrong with the program, it should not enter here, encounter type: ", linenum);
                errorExist = 1;
                typePrintingHelperInC(varType);
                printf("\n");
            }
        }
    }else
    {
        //point out that same identifier is already declared, and function declaration is an error
        struct EntryAttributes alreadyExist = fromIdxPairReturnAttributes(identifierPos, debugMode);
        printf("Error %d: Array Argument declaration %s failed due to duplicate identifier already declared at line %i, not saving to symbol table\n", linenum, identifierPos.varName, alreadyExist.declaredLine);
        errorExist = 1;
        resultArgument.isEncounterError = 1;
        resultArgument.paramsLength = 0;
        //deallocate the FunctionArgFollowUp if it is not an error
        //if it is an error, that means it has previously deallocated
        if(followUpArguments.isEncounterError == 0 && followUpArguments.paramsLength > 0){
            free(followUpArguments.paramsOrdering);
            free(followUpArguments.eachParamsHowManyElements);
        }
    }
    return resultArgument;
}

//LHS and RHS operation collection for comparison operator
int intDoubleBooleanEvaluationBasedOnSymbol(double LHS, char* symbol, double RHS){
    if(strcmp(symbol, "=") == 0){
        return LHS == RHS;
    }else if(strcmp(symbol, "not=") == 0){
        return LHS != RHS;
    }else if(strcmp(symbol, "<=") == 0){
        return LHS <= RHS;
    }else if(strcmp(symbol, "<") == 0){
        return LHS < RHS;
    }else if(strcmp(symbol, ">") == 0){
        return LHS > RHS;
    }else if(strcmp(symbol, ">=") == 0){
        return LHS >= RHS;
    }else{
        printf("SelfError %d: Numerical Relational operator not defined error\n", linenum);
        errorExist = 1;
        return -1;
    }
}

//same but for string
int stringBooleanEvaluationBasedOnSymbol(char* LHS, char* symbol, char* RHS){
    if(strcmp(symbol, "=") == 0){
        return strcmp(LHS,RHS) == 0;
    }else if(strcmp(symbol, "not=") == 0){
        return strcmp(LHS,RHS) != 0;
    }else if(strcmp(symbol, "<=") == 0){
        return strcmp(LHS,RHS) <= 0;
    }else if(strcmp(symbol, "<") == 0){
        return strcmp(LHS,RHS) < 0;
    }else if(strcmp(symbol, ">") == 0){
        return strcmp(LHS,RHS) > 0;
    }else if(strcmp(symbol, ">=") == 0){
        return strcmp(LHS,RHS) >= 0;
    }else{
        printf("SelfError %d: String Relational operator not defined error\n", linenum);
        errorExist = 1;
        return -1;
    }
}

//same but for bool
int boolBooleanEvaluationBasedOnSymbol(int LHS, char* symbol, int RHS){
    if(strcmp(symbol, "=") == 0){
        return LHS == RHS;
    }else if(strcmp(symbol, "not=") == 0){
        return LHS != RHS;
    }else{
        printf("SelfError %d: Bool Relational operator not defined error\n", linenum);
        errorExist = 1;
        return -1;
    }
}

struct expr relationalStatementChecker(struct expr LHS, char* symbol,struct expr RHS){
    // valid combination:
    // numerical with numerical (int or double)
    // string with string
    // EXCLUSIVE ONLY FOR NOT EQUAL AND EQUAL: Boolean and Boolean
    // resulting a boolean
    struct expr resExpr = defaultExprValue();
    // make sure that both of the expr has no error
    if(LHS.isError == 0 && RHS.isError == 0){
        if(exprIsArray(LHS.exprType) || exprIsArray(RHS.exprType)){
            //not valid because expression is an array, can't put relational operator
            printf("Error %d: Not a valid expr, %s  has LHS or RHS anArray\n", linenum, symbol);
            errorExist = 1;
            resExpr.isError = 1;
        }else{
            resExpr.arrLength = 1;
            // if both of them is a const, then the result is also a const
            if(LHS.isConst == 1 && RHS.isConst == 1){
                resExpr.isConst = 1;
            }else{
                resExpr.isConst = 0;
            }

            resExpr.isError = 0;
            if((LHS.exprType == IEXPR || LHS.exprType == DEXPR) && (RHS.exprType == IEXPR || RHS.exprType == DEXPR)) {
                //numerical inputs
                if(LHS.exprType == DEXPR && RHS.exprType == DEXPR){
                    // both are double
                    resExpr.exprType = BEXPR;
                    // if one of them is func, for now left unevaluated
                    if(canStoreValueInSymbolTable(resExpr)) resExpr.boolVal = intDoubleBooleanEvaluationBasedOnSymbol(LHS.dVal, symbol ,RHS.dVal);

                    /////////////////WRITE CODE SECTION
                    encounterUnableToExpress(&errorExist, "float relational input", linenum);
                    ///////////////////////////////////
                }else if(LHS.exprType == DEXPR && RHS.exprType == IEXPR){
                    // RHS is int
                    resExpr.exprType = BEXPR;
                    // if one of them is func, for now left unevaluated
                    if(canStoreValueInSymbolTable(resExpr)) resExpr.boolVal = intDoubleBooleanEvaluationBasedOnSymbol(LHS.dVal, symbol ,RHS.iVal);

                    /////////////////WRITE CODE SECTION
                    encounterUnableToExpress(&errorExist, "float relational input", linenum);
                    ///////////////////////////////////
                }else if(LHS.exprType == IEXPR && RHS.exprType == DEXPR){
                    // LHS is int
                    resExpr.exprType = BEXPR;
                    // if one of them is func, for now left unevaluated
                    if(canStoreValueInSymbolTable(resExpr)) resExpr.boolVal = intDoubleBooleanEvaluationBasedOnSymbol(LHS.iVal, symbol ,RHS.dVal);

                    /////////////////WRITE CODE SECTION
                    encounterUnableToExpress(&errorExist, "float relational input", linenum);
                    ///////////////////////////////////
                }else{
                    // both is int
                    resExpr.exprType = BEXPR;
                    // if one of them is func, for now left unevaluated
                    if(canStoreValueInSymbolTable(resExpr)) resExpr.boolVal = intDoubleBooleanEvaluationBasedOnSymbol(LHS.iVal, symbol ,RHS.iVal);
                    
                    /////////////////WRITE CODE SECTION
                    relationalOperators(&errorExist, symbol);
                    ///////////////////////////////////
                }
            }
            else if((LHS.exprType == SEXPR) && (RHS.exprType == SEXPR)){
                // string with string
                resExpr.exprType = BEXPR;
                // if one of them is func, for now left unevaluated
                if(canStoreValueInSymbolTable(resExpr)) resExpr.boolVal = stringBooleanEvaluationBasedOnSymbol(LHS.sVal, symbol ,RHS.sVal);
                /////////////////WRITE CODE SECTION
                encounterUnableToExpress(&errorExist, "string relational input", linenum);
                ///////////////////////////////////
            }else if((LHS.exprType == BEXPR) && (RHS.exprType == BEXPR) && (strcmp(symbol, "=") == 0 || strcmp(symbol, "not=") == 0)){
                resExpr.exprType = BEXPR;
                // if one of them is func, for now left unevaluated
                if(canStoreValueInSymbolTable(resExpr)) resExpr.boolVal = boolBooleanEvaluationBasedOnSymbol(LHS.boolVal, symbol ,RHS.boolVal);
                /////////////////WRITE CODE SECTION
                relationalOperators(&errorExist, symbol);
                ///////////////////////////////////
            }
            else{
                // not a valid type
                printf("Error %d: Not a valid expr, %s  has invalid LHS and RHS Type Pair : ", linenum, symbol);
                errorExist = 1;
                exprTypePrintingHelper(LHS.exprType, LHS.arrLength);
                printf(" and ");
                exprTypePrintingHelper(RHS.exprType, RHS.arrLength);
                printf("\n");
                resExpr.isError = 1;
            }
        }
    }else{
        // no need to continue, it is already an error in previous expression input
        resExpr.isError = 1;
    }
    return resExpr;
}

int booleanLogicalEvaluationBasedOnSymbol(int LHSBool, char* symbol, int RHSBool){
    if(strcmp(symbol,"and") == 0){
        return LHSBool && RHSBool;
    }else if(strcmp(symbol, "or") == 0){
        return LHSBool || RHSBool;
    }else if(strcmp(symbol, "not") == 0){
        // only uses RHS Bool
        return !RHSBool;
    }else{
        printf("SelfError %d: Bool Logical operator not defined error\n", linenum);
        errorExist = 1;
        return -1;
    }
}

struct expr LogicalAndOrNotOperation(struct expr LHS, char *symbol, struct expr RHS){
    //Both the input should be boolean
    // for not, LHS will not be evaluated and can be anything
    int isOrAnd = strcmp(symbol,"or") == 0||strcmp(symbol,"and") == 0;
    int isNot = strcmp(symbol,"not") == 0;
    struct expr resExpr = defaultExprValue();
    if(LHS.isError == 0 && RHS.isError == 0){
        // both should not error
        if(exprIsArray(LHS.exprType) || exprIsArray(RHS.exprType)){
            //not valid because expression is an array, can't put logical operator
            printf("Error %d: Not a valid expr for logical, %s  has LHS or RHS anArray\n", linenum, symbol);
            errorExist = 1;
            resExpr.isError = 1;
        }else{
            // if both of them is a const, then the result is also a const
            // for not, just look at RHS
            if(((LHS.isConst == 1 && RHS.isConst == 1) && isOrAnd) || ( RHS.isConst == 1 && isNot)){
                resExpr.isConst = 1;
            }else{
                resExpr.isConst = 0;
            }

            if(((LHS.exprType == BEXPR) && (RHS.exprType == BEXPR) && (isOrAnd)) || ((isNot) && (RHS.exprType == BEXPR))) {
                resExpr.exprType = BEXPR;
                // if one of them is func, for now left unevaluated
                // for not, just look at rhs
                if(canStoreValueInSymbolTable(resExpr)) resExpr.boolVal = booleanLogicalEvaluationBasedOnSymbol(LHS.boolVal, symbol, RHS.boolVal);
                resExpr.isError = 0;
                /////////////////WRITE CODE SECTION
                logicalOperators(&errorExist, symbol);
                ///////////////////////////////////
            }else{
                // not a valid type
                if(isOrAnd){
                    printf("Error %d: Not a valid expr, %s has invalid LHS and RHS Type Pair : ", linenum, symbol);
                    errorExist = 1;
                    exprTypePrintingHelper(LHS.exprType, LHS.arrLength);
                    printf(" and ");
                    exprTypePrintingHelper(RHS.exprType, RHS.arrLength);
                    printf("\n");
                }else if(isNot){
                    printf("Error %d: Not a valid expr, %s has invalid LHS and RHS Type Pair : ", linenum, symbol);
                    errorExist = 1;
                    exprTypePrintingHelper(RHS.exprType, RHS.arrLength);
                    printf("\n");
                }else{
                    printf("SelfError %d: Undefined symbol: %s\n", linenum, symbol);
                    errorExist = 1;
                }
                resExpr.isError = 1;
            }
        }
    }else{
        // no need to continue, it is already an error
        resExpr.isError = 1;
    }
    return resExpr;
}


double MathematicalOperationResultDouble(double LHS, char* symbol, double RHS){
    if(strcmp(symbol, "ADDITION") == 0){
        return LHS + RHS;
    }else if(strcmp(symbol, "SUBTRACTION") == 0){
        return LHS - RHS;
    }else if(strcmp(symbol, "MULTIPLICATION") == 0){
        return LHS * RHS;
    }else if(strcmp(symbol, "DIVISION") == 0){
        //zero division is checked outside
        return LHS / RHS;
    }else{
        //remainder is not defined, only both int inputs are possible
        printf("SelfError %d: Operator %s is not defined for mathematical operation resulting int\n", linenum, symbol);
        errorExist = 1;
        return -1;
    }
}

int MathematicalOperationResultInt(int LHS, char* symbol, int RHS){
    //for the case of unary, I will not put it here
    if(strcmp(symbol, "ADDITION") == 0){
        return LHS + RHS;
    }else if(strcmp(symbol, "SUBTRACTION") == 0){
        return LHS - RHS;
    }else if(strcmp(symbol, "MULTIPLICATION") == 0){
        return LHS * RHS;
    }else if(strcmp(symbol, "DIVISION") == 0){
        return LHS / RHS;
    }else if(strcmp(symbol, "REMAINDER") == 0){
        //zero division is checked outside
        return LHS % RHS;
    }else{
        printf("SelfError %d: Operator %s is not defined for mathematical operation resulting int\n", linenum, symbol);
        errorExist = 1;
        return -1;
    }
}


//Addition - Subtraction - Multiplication - Division - Remainder
struct expr MathematicalOperation(struct expr LHS, char* symbol, struct expr RHS){
    //only numerical entry for LHS or RHS is valid (Int and Real)
    // Type checking first between expression
    struct expr resExpr = defaultExprValue();
    // make sure that both of the expr has no error
    if(LHS.isError == 0 && RHS.isError == 0){
        if(exprIsArray(LHS.exprType) || exprIsArray(RHS.exprType)){
            printf("Error %d: Not a valid expr for mathematical, %s  has LHS or RHS anArray\n", linenum, symbol);
            errorExist = 1;
            resExpr.isError = 1;
        }else{
            resExpr.arrLength = 1;// because this is a variable, no array is possible
            // only numerical expression is valid
            // for addition, subtraction, multiplication, division, LHS and RHS can be INT or DOUBLE
            // but for remainder, LHS and RHS can only be an int
            int isAdd = (strcmp(symbol, "ADDITION") == 0);
            int isSub = (strcmp(symbol, "SUBTRACTION") == 0);
            int isMult = (strcmp(symbol, "MULTIPLICATION") == 0);
            int isDiv = (strcmp(symbol, "DIVISION") == 0);
            int isRem = (strcmp(symbol, "REMAINDER") == 0);
            int isAddSubMultDiv = (isAdd|| isSub || isMult || isDiv);
            int LHSAndRHSNumerical = (LHS.exprType == IEXPR || LHS.exprType == DEXPR) && (RHS.exprType == IEXPR || RHS.exprType == DEXPR);
            int LHSAndRHSInt = (LHS.exprType == IEXPR) && (RHS.exprType == IEXPR);
            if((LHSAndRHSInt && isRem) || (LHSAndRHSNumerical && isAddSubMultDiv)) {
                // check for zero division error
                // for now can only check it is a zero division error if rhs is not a function
                int isZeroDivisionError = 0;
                if(isDiv || isRem){
                    if(!RHS.isConst && !symbolTableStoreValue){
                        printf("Warning %d: In the current state because RHS has a variable, and symbol table value saving is turned off, can't check for zero division error\n", linenum);
                    }
                    else{
                        if(RHS.exprType == IEXPR && RHS.iVal == 0)
                        {
                            isZeroDivisionError = 1;
                        }

                        if(RHS.exprType == DEXPR && RHS.dVal == 0.0)
                        {
                            isZeroDivisionError = 1;
                        }
                    }
                }

                if(isZeroDivisionError){
                    char temp[256];
                    if(isRem){
                        strcpy(temp, "REMAINDER");
                    }else{
                        strcpy(temp, "DIVISION");
                    }
                    printf("Error %d: Zero Division Error, encounter 0 value in RHS while do %s\n", linenum, temp);
                    errorExist = 1;
                    resExpr.isError = 1;    
                } 
                else
                {
                    // valid
                    // if one of them is double, result is double
                    resExpr.arrLength = 1;
                    // if both of them is a const, then the result if also a const
                    if(LHS.isConst == 1 && RHS.isConst == 1){
                        resExpr.isConst = 1;
                    }else{
                        resExpr.isConst = 0;
                    }

                    if(LHS.exprType == DEXPR && RHS.exprType == DEXPR){
                        // both are double
                        resExpr.exprType = DEXPR;
                        // if one of them is func, for now left unevaluated
                        if(canStoreValueInSymbolTable(resExpr)) resExpr.dVal = MathematicalOperationResultDouble(LHS.dVal, symbol, RHS.dVal);
                        /////////////////WRITE CODE SECTION
                        encounterUnableToExpress(&errorExist, "float mathematical input", linenum);
                        ///////////////////////////////////
                    }else if(LHS.exprType == DEXPR && RHS.exprType == IEXPR){
                        // RHS is int
                        resExpr.exprType = DEXPR;
                        // if one of them is func, for now left unevaluated
                        if(canStoreValueInSymbolTable(resExpr)) resExpr.dVal = MathematicalOperationResultDouble(LHS.dVal, symbol, RHS.iVal);
                        /////////////////WRITE CODE SECTION
                        encounterUnableToExpress(&errorExist, "float mathematical input", linenum);
                        ///////////////////////////////////
                    }else if(LHS.exprType == IEXPR && RHS.exprType == DEXPR){
                        // LHS is int
                        resExpr.exprType = DEXPR;
                        // if one of them is func, for now left unevaluated
                        if(canStoreValueInSymbolTable(resExpr)) resExpr.dVal = MathematicalOperationResultDouble(LHS.iVal, symbol, RHS.dVal);
                        /////////////////WRITE CODE SECTION
                        encounterUnableToExpress(&errorExist, "float mathematical input", linenum);
                        ///////////////////////////////////
                    }else{
                        // both is int
                        resExpr.exprType = IEXPR;
                        // if one of them is func, for now left unevaluated
                        if(canStoreValueInSymbolTable(resExpr)) resExpr.iVal = MathematicalOperationResultInt(LHS.iVal, symbol, RHS.iVal);
                        
                        /////////////////WRITE CODE SECTION
                        arithmeticOperators(&errorExist, symbol);
                        ///////////////////////////////////
                    }
                    resExpr.isError = 0;
                }
            }else{
                if(isAdd || isSub || isMult || isDiv || isRem){
                    if(isAdd){
                        printf("Error %d: Not a valid expr, ADDITION has invalid LHS and RHS Type Pair : ",linenum);
                        errorExist = 1;
                    }else if(isSub){
                        printf("Error %d: Not a valid expr, SUBTRACTION has invalid LHS and RHS Type Pair : ",linenum);
                        errorExist = 1;
                    }else if(isMult){
                        printf("Error %d: Not a valid expr, MULTIPLICATION has invalid LHS and RHS Type Pair : ",linenum);
                        errorExist = 1;
                    }else if(isDiv){
                        printf("Error %d: Not a valid expr, DIVISION has invalid LHS and RHS Type Pair : ",linenum);
                        errorExist = 1;
                    }else{
                        printf("Error %d: Not a valid expr, REMAINDER has invalid LHS and RHS Type Pair : ",linenum);
                        errorExist = 1;
                    }
                    exprTypePrintingHelper(LHS.exprType, LHS.arrLength);
                    printf(" and ");
                    exprTypePrintingHelper(RHS.exprType, RHS.arrLength);
                    printf("\n");
                }
                else{
                    //invalid operation
                    printf("SelfError %d: Invalid arithmetic operator: %s\n", linenum, symbol);
                    errorExist = 1;
                }
                resExpr.isError = 1;
            }
        }
    }else{
        // no need to continue, it is already an error
        resExpr.isError = 1;
    }
    return resExpr;
}

double ParenthesesUnaryMinExprRes(double in, char* operation){
    if(strcmp(operation, "UMINUS") == 0){
        return -in;
    }else if(strcmp(operation, "PARENTHESES") == 0){
        return in;
    }else{
        printf("SelfError %d: Operator %s is not defined for unaryMinParenthesesExprRes\n", linenum, operation);
        errorExist = 1;
        return -1;
    }
}

struct expr ParenthesesUnaryMinExpr(struct expr in, char* operation){
    //operation can either be "UMINUS" or "PARENTHESES"
    //uminus can only have numerical expression input,
    //parentheses can be anything, even void (and array)
    struct expr resExpr = defaultExprValue();
    int isMinUnary = strcmp(operation, "UMINUS") == 0;
    int isParentheses = strcmp(operation, "PARENTHESES") == 0;
    // make sure that expr in the middle has no error
    if(isMinUnary || isParentheses){
        if(in.isError == 0){
            resExpr.exprType = in.exprType;
            if(exprIsArray(in.exprType)){
                //array type can only be used for parentheses
                //array type is only defined for INT, REAL, BOOL
                /////////////////WRITE CODE SECTION
                encounterUnableToExpress(&errorExist, "Array", linenum);
                ///////////////////////////////////
                if(in.exprType == DARREXPR && (isParentheses)){
                    resExpr.arrLength = in.arrLength;
                    resExpr.isConst = in.isConst;
                    resExpr.isError = 0;
                }else if(in.exprType == IARREXPR && (isParentheses)){
                    resExpr.arrLength = in.arrLength;
                    resExpr.isConst = in.isConst;
                    resExpr.isError = 0;
                }else if(in.exprType == BARREXPR && (isParentheses)){
                    resExpr.arrLength = in.arrLength;
                    resExpr.isConst = in.isConst;
                    resExpr.isError = 0;
                }else{
                    printf("Error %d: Unknown value for array input expression %s Expr, type : \n", linenum, operation);
                    exprTypePrintingHelper(in.exprType, in.arrLength);
                    printf("\n");
                    resExpr.isError = 1;
                    errorExist = 1;
                }
            }else{
                //regular variable, not an array
                resExpr.arrLength = 1;
                resExpr.isConst = in.isConst;
                if(in.exprType == DEXPR && (isMinUnary || isParentheses)){
                    // if middle is func, for now left unevaluated
                    if(canStoreValueInSymbolTable(resExpr)) resExpr.dVal = ParenthesesUnaryMinExprRes(in.dVal, operation);
                    resExpr.isError = 0;
                    /////////////////WRITE CODE SECTION
                    encounterUnableToExpress(&errorExist, "float unary minus/parentheses input", linenum);
                    ///////////////////////////////////
                }else if(in.exprType == IEXPR && (isMinUnary || isParentheses)){
                    // if middle is func, for now left unevaluated
                    if(canStoreValueInSymbolTable(resExpr)) resExpr.iVal = ParenthesesUnaryMinExprRes(in.iVal, operation);
                    resExpr.isError = 0;

                    /////////////////WRITE CODE SECTION
                    if(strcmp(operation, "UMINUS") == 0){
                        arithmeticOperators(&errorExist, operation);
                    }
                    ///////////////////////////////////
                }else if(in.exprType == SEXPR && (isParentheses)){
                    // if middle is func, for now left unevaluated
                    if(canStoreValueInSymbolTable(resExpr)) strcpy(resExpr.sVal, in.sVal);
                    resExpr.isError = 0;
                    resExpr.isError = 0;
                }else if(in.exprType == BEXPR && (isParentheses)){
                    // if middle is func, for now left unevaluated
                    if(canStoreValueInSymbolTable(resExpr)) resExpr.boolVal =  in.boolVal;
                    resExpr.isError = 0;
                }else if(in.exprType == VEXPR && (isParentheses)){
                    // just leave it as it is
                    resExpr.isError = 0;
                }else{
                    printf("Error %d: Unknown value for input expression %s Expr, type : ", linenum, operation);
                    exprTypePrintingHelper(in.exprType, in.arrLength);
                    printf("\n");
                    resExpr.isError = 1;
                    errorExist = 1;
                }
            }
        }else{
            // no need to continue, it is already an error
            resExpr.isError = 1;
        }
    }else{
        //undefined operator
        printf("SelfError %d: Unknown operation for ParenthesesUnaryMinExpr %s", linenum, operation);
        resExpr.isError = 1;
        errorExist = 1;
    }
    
    return resExpr;
}

//Variable declaring purposes
//isValueless = whether declaration has value
//isTypeless = whether declaration has type
//isConst = whether it is a const declaration
//IdxPair = identifier IdxPair Specification
//typeSpec= input type specification(if not typeless)
//exprSpec= input the expression specification (if not valueless)
//linenum: declared in which line
void VariableDeclarationSteps(int isValueless, int isTypeless, int isConst, struct IdxPair identifierSpec, enum Type typeSpec, struct expr exprSpec, int linenum){
    char errorMessageHelper[256] = "var";
    if(isConst){
        strcpy(errorMessageHelper, "const");
    }
    if(!isValueless && exprSpec.isError == 1){
        // expr is error, declaration failed
        printf("Error %d: %s %s is not declared due to error in expression\n", linenum, identifierSpec.varName, errorMessageHelper);
        errorExist = 1;
    }else{
        // check whether Expr is a const
        // function for expr is also invalid, because function will have isConst = 0
        if(!isValueless && exprSpec.isConst == 0){
            printf("Error %d: %s %s is not declared due to expression is not a const\n", linenum, identifierSpec.varName, errorMessageHelper);
            errorExist = 1;
        }else{ 
            // type error? need to check whether Type and expr.exprType is the same, (if both of them exist)
            //right hand side cannot be array
            if(isValueless || ((isTypeless || typeSpec == translatorExprType(exprSpec.exprType)) && !exprIsArray(exprSpec.exprType))){
                // valid, continue declaration of var
                // see whether same name is already declared inside the symbol table
                if(identifierNotExistInThisScopeChecker(identifierSpec)){
                    // variable not found, valid, put the content here
                    struct EntryAttributes toBeInputted = defaultEntryAttributesValue();
                    // entryType
                    toBeInputted.entryType = VAR_ENTTYPE;
                    if(isConst){
                        toBeInputted.entryType = CONST_ENTTYPE;
                    }
                    // declared in which line number
                    toBeInputted.declaredLine = linenum;
                    if(!isValueless){
                        if(exprSpec.exprType == IEXPR){
                            //if constant, its value can always be stored on symbol table
                            if(isConst || canStoreValueInSymbolTable(exprSpec)) toBeInputted.iVal = exprSpec.iVal;
                        }else if(exprSpec.exprType == DEXPR){
                            //if constant, its value can always be stored on symbol table
                            if(isConst || canStoreValueInSymbolTable(exprSpec)) toBeInputted.dVal = exprSpec.dVal;
                        }else if(exprSpec.exprType == SEXPR){
                            //if constant, its value can always be stored on symbol table
                            if(isConst || canStoreValueInSymbolTable(exprSpec)) strcpy(toBeInputted.sVal, exprSpec.sVal);
                        }else if(exprSpec.exprType == BEXPR){
                            //if constant, its value can always be stored on symbol table
                            if(isConst || canStoreValueInSymbolTable(exprSpec)) toBeInputted.boolVal = exprSpec.boolVal;
                        }else{
                            printf("SelfError %d: Invalid setting value to %s, get type: \n", linenum, errorMessageHelper);
                            exprTypePrintingHelper(exprSpec.exprType, exprSpec.arrLength);
                            errorExist = 1;
                            printf("\n");
                        }
                    }else{
                        // set default value for now
                        // definitely not typeless, because it can't be that they are both valueless and typeless at the same time
                        if(typeSpec == INTEGER_TYPE){
                            toBeInputted.iVal = 0;
                        }else if(typeSpec == DOUBLE_TYPE){
                            toBeInputted.dVal = 0;
                        }else if(typeSpec == STRING_TYPE){
                            strcpy(toBeInputted.sVal, "");
                        }else if(typeSpec == BOOL_TYPE){
                            toBeInputted.boolVal = 0;
                        }else{
                            printf("SelfError %d: Invalid setting value to %s\n", linenum, errorMessageHelper);
                            errorExist = 1;
                        }
                    }

                    // set type of variables
                    if(isTypeless){
                        if(exprSpec.exprType == IEXPR){
                            //if constant, its value can always be stored on symbol table
                            toBeInputted.varConstOrResType = INTEGER_TYPE;
                        }else if(exprSpec.exprType == DEXPR){
                            //if constant, its value can always be stored on symbol table
                            toBeInputted.varConstOrResType = DOUBLE_TYPE;
                        }else if(exprSpec.exprType == SEXPR){
                            //if constant, its value can always be stored on symbol table
                            toBeInputted.varConstOrResType = STRING_TYPE;
                        }else if(exprSpec.exprType == BEXPR){
                            //if constant, its value can always be stored on symbol table
                            toBeInputted.varConstOrResType = BOOL_TYPE;
                        }else{
                            printf("SelfError %d: Invalid setting value to %s, get type: \n", linenum, errorMessageHelper);
                            exprTypePrintingHelper(exprSpec.exprType, exprSpec.arrLength);
                            printf("\n");
                            errorExist = 1;
                        }
                    }else if(isValueless){
                        toBeInputted.varConstOrResType = typeSpec;
                    }else{
                        toBeInputted.varConstOrResType = typeSpec;
                    }
                    
                    // insert new entry to the back of symbol table
                    struct IdxPair entryPosition = insert(identifierSpec.varName, debugMode);
                    editAttributesOnIndex(entryPosition, toBeInputted, debugMode);
                    //////////////WRITE CODE SECTION
                    ///Modify local variable number if variable is declared local
                    if(toBeInputted.entryType == VAR_ENTTYPE && identifierIsLocal(entryPosition)){
                        modifyLocalVariableNumber(entryPosition, debugMode);
                    }
                    ////////////////////////////////
                    /////////////////WRITE CODE SECTION
                    if(toBeInputted.varConstOrResType == STRING_TYPE && toBeInputted.entryType == VAR_ENTTYPE){
                        encounterUnableToExpress(&errorExist, "string variable declaration", linenum);
                    }else if(toBeInputted.varConstOrResType == DOUBLE_TYPE){
                        encounterUnableToExpress(&errorExist, "float variable / constant declaration", linenum);
                    }else if(toBeInputted.varConstOrResType == INTEGER_TYPE && toBeInputted.entryType == VAR_ENTTYPE){
                        if(identifierIsGlobal(entryPosition)){
                            declareGlobalVar(&errorExist, entryPosition, isValueless);
                        }else{
                            declareLocalVar(&errorExist, entryPosition, isValueless);
                        }
                    }else if(toBeInputted.varConstOrResType == BOOL_TYPE && toBeInputted.entryType == VAR_ENTTYPE){
                        if(identifierIsGlobal(entryPosition)){
                            declareGlobalVar(&errorExist, entryPosition, isValueless);
                        }else{
                            declareLocalVar(&errorExist, entryPosition, isValueless);
                        }
                    }
                    ///////////////////////////////////
                    
                }else{
                    struct EntryAttributes existingVarAttributes = fromIdxPairReturnAttributes(identifierSpec, debugMode);
                    printf("Error %d: %s declaration failed, %s is already exist inside symbol table, defined in line: %i\n", linenum, errorMessageHelper, identifierSpec.varName, existingVarAttributes.declaredLine);
                    errorExist = 1;
                }
            }else{
                printf("Error %d: Can't declare %s %s because different type: \n", linenum, errorMessageHelper, identifierSpec.varName);
                typePrintingHelperInC(typeSpec);
                printf(" and ");
                exprTypePrintingHelper(exprSpec.exprType, exprSpec.arrLength);
                printf("\n");
                errorExist = 1;
            }
        }
    }
}

/////////////////WRITE CODE SECTION
//FUNCTION WRITING PART WILL BE DONE DIRECTLY IN RULE
///////////////////////////////////

//to be used during middle rule of function and procedure, making local scopes preparation
//isFunc; 1 = procedure, 0 = function
// globalIdentifierSpec; global scope identifier specification
// linenum, declared line number
void initialFunctionProcedureDeclaration(int isFunc, struct IdxPair globalIdentifierSpec, int linenum){
    create(debugMode , 1); //create new scope

    //insert the function name to symbol table
    //since no recursion, we don't have to worry about the correctness of the data inside during the midrule (e.g. the params, and return type for function)
    //we just have to pay attention so that the entry exist inside the symbol table, so that no future identifier can use this name
    //even if this identifier already exist in the global (where it causes error),I still insert it into local for ProcedureScope/FunctionScope non terminal error-checking to avoid duplicate entry name inside
    struct EntryAttributes in = defaultEntryAttributesValue();
    in.entryType = FUNCTION_ENTTYPE; //I said Function and Procedure as both FUNCTION_ENTTYPE for simplicity
    in.declaredLine = linenum;
    in.varConstOrResType = VOID_TYPE; // procedure is always a void, but function may not, we will change this later in finishFunctionProcedureDeclaration
    struct IdxPair entryPosition = insert(globalIdentifierSpec.varName, debugMode);
    editAttributesOnIndex(entryPosition, in, debugMode);
    // reset function result tracker
    functionResultTracker = defaultResultTrackerValue();
}

// finish function or procedulre declaration
// isFunc; 0 = procedure, 1 = function
// globalIdentifierSpec; global scope identifier specification
// linenum, declared line number
// ArgumentList: List of the argument specification for the function
// endingNameIsSame: back in function/procedure when meeting END, IDENTIFIER name that follows should match
// resultTypeSpec: declared result type, only for function
void finishFunctionProcedureDeclaration(int isFunc, struct IdxPair globalIdentifierSpec, int linenum, struct ArgAccumulation argumentList, int endingNameIsSame, enum Type resultTypeSpec){
    char errorMessageHelper[256] = "procedure";
    if(isFunc){
        strcpy(errorMessageHelper, "function");
    }
    
    struct IdxPair entryPosition = lookupIndexInLast(globalIdentifierSpec.varName, debugMode);
    struct EntryAttributes localEntry = fromIdxPairReturnAttributes(entryPosition, debugMode);
    // fix the result type spec, because previously all is set as VOID_TYPE
    localEntry.varConstOrResType = resultTypeSpec;
    if(argumentList.isEncounterError == 0){
        //due to the way my program works, I need to duplicately dynamic alloc the dynamic array, because if I pop back, all the entry of dynamic array will be deallocated by symbol table operation
        localEntry.paramsLength = argumentList.paramsLength;
        if(localEntry.paramsLength > 0){
            localEntry.paramsOrdering = (enum ParamsType*) calloc(localEntry.paramsLength, sizeof(enum ParamsType));
            localEntry.eachParamsHowManyElements = (int*) calloc(localEntry.paramsLength, sizeof(int));
            for(int idx = 0; idx < localEntry.paramsLength; idx++){
                localEntry.paramsOrdering[idx] = argumentList.paramsOrdering[idx];
                localEntry.eachParamsHowManyElements[idx] = argumentList.eachParamsHowManyElements[idx];
            }
        }else{
            localEntry.paramsOrdering = NULL;
            localEntry.eachParamsHowManyElements = NULL;
        }
    }else{
        //if there is problem in the argumentListing, no need to fix entry
        //dont worry about dynamic array, it has been deallocated as soon as error is met
        printf("Error %d: %s %s is not declared due to error in argument listing\n", linenum, errorMessageHelper, globalIdentifierSpec.varName);
        errorExist = 1;
    }

    // fix the local entry
    editAttributesOnIndex(entryPosition, localEntry, debugMode);
    // pop back the symbol table
    popBack(debugMode, 1);
    //only push to the global symbol table if everything is valid,
    //that is the ending name is the same, function or procedure has not exist in global, and argumentList has no error, and result type is valid for function
    int notExistInGlobal = identifierNotExistInThisScopeChecker(globalIdentifierSpec);
    // for function, each result type should also be the same as the said type
    // check from the global variable
    int resultValid = 1;
    if(isFunc && functionResultTracker.resultAmount == 0){
        resultValid = 0;
    }else if(!isFunc && functionResultTracker.resultAmount > 0){
        //procedure cannot have result
        resultValid = 0;
    }
    int resultTypeCorrect = 1;
    if(isFunc && resultValid)
    {
        for(int idx = 0; idx < functionResultTracker.resultAmount; idx++){
            //result can't be array, and also type should be the same as in the one said in declaration
            if(functionResultTracker.exprIsError[idx]){
                printf("Error %d: %s %s declaration failed due to result expression has error in line %i\n", linenum, errorMessageHelper, globalIdentifierSpec.varName, functionResultTracker.linenumResult[idx]);
                errorExist = 1;
                resultTypeCorrect = 0;
                continue;
            }
            if(exprIsArray(functionResultTracker.resultType[idx]) || translatorExprType(functionResultTracker.resultType[idx]) != resultTypeSpec){
                printf("Error %d: %s %s declaration failed due to result type in compatible in line %i, ", linenum, errorMessageHelper, globalIdentifierSpec.varName, functionResultTracker.linenumResult[idx]);
                printf("Expected: ");
                typePrintingHelperInC(resultTypeSpec);
                printf(", Found: "); 
                exprTypePrintingNoArrayLengthHelper(functionResultTracker.resultType[idx]);
                printf("\n");
                errorExist = 1;
                resultTypeCorrect = 0;
            }
        }
        //deallocate dynamic memory
        free(functionResultTracker.linenumResult);
        free(functionResultTracker.resultType);
        free(functionResultTracker.exprIsError);
        //reset
        functionResultTracker = defaultResultTrackerValue();
    }
    
    if(notExistInGlobal && endingNameIsSame && argumentList.isEncounterError == 0 && resultValid && resultTypeCorrect){
        // valid 
        struct IdxPair globalEntryPosition = insert(globalIdentifierSpec.varName, debugMode);
        //reedit the local entry, this time just copy directly the address on the FunctionArgList result
        if(localEntry.paramsLength > 0){
            localEntry.paramsOrdering = argumentList.paramsOrdering;
            localEntry.eachParamsHowManyElements = argumentList.eachParamsHowManyElements;
        }else{
            //set the array to NULL
            //it is already set to NULL above
        }
        editAttributesOnIndex(globalEntryPosition, localEntry, debugMode);
    }else{
        if(!notExistInGlobal){
            struct EntryAttributes alreadyExist = fromIdxPairReturnAttributes(globalIdentifierSpec, debugMode);
            printf("Error %d: %s declaration of %s failed due to identifier already declared at line %i, not saving to global symbol table\n", linenum, errorMessageHelper, globalIdentifierSpec.varName, alreadyExist.declaredLine);
            errorExist = 1;
        }
        if(!endingNameIsSame){
            printf("Error %d: %s declaration of %s failed due to ending name is different, not saving to global\n", linenum, errorMessageHelper, globalIdentifierSpec.varName);
            errorExist = 1;
        }
        if(argumentList.isEncounterError != 0){
            printf("Error %d: %s declaration of  %s failed due to argument declaration has error, not saving to global symbol table\n", linenum, errorMessageHelper, globalIdentifierSpec.varName);
            errorExist = 1;
        }
        if(!resultValid)
        {
            if(!isFunc){
                printf("Error %d: procedure %s, has result, procedure can't have result, declaration failed, not saving to global symbol table\n", linenum,globalIdentifierSpec.varName);
                errorExist = 1;
            }else{
                printf("Error %d: function %s, no result, declaration failed, not saving to global symbol table\n", linenum,globalIdentifierSpec.varName);
                errorExist = 1;
            }
        }
        if(!resultTypeCorrect){
            printf("Error %d: function %s, there is type incompatible on result, declaration failed, not saving to global symbol table\n", linenum,globalIdentifierSpec.varName);
            errorExist = 1;
        }
    }
}

//when meeting a result statement, update the global variable
void addResultEntryToGlobal(struct expr exprSpec, int linenumber){
    if(functionResultTracker.resultAmount > 0){
        // dynamic variable already initialized
        functionResultTracker.resultAmount++;
        functionResultTracker.linenumResult = (int*) realloc(functionResultTracker.linenumResult, sizeof(int) * functionResultTracker.resultAmount);
        functionResultTracker.resultType = (enum ExprType*) realloc(functionResultTracker.resultType, sizeof(enum ExprType) * functionResultTracker.resultAmount);
        functionResultTracker.exprIsError = (int*) realloc(functionResultTracker.exprIsError, sizeof(int) * functionResultTracker.resultAmount);
    }else{
        //needs to reinit dynamic variable
        functionResultTracker.resultAmount++;
        functionResultTracker.linenumResult = (int* ) calloc(functionResultTracker.resultAmount, sizeof(int));
        functionResultTracker.resultType = (enum ExprType* ) calloc(functionResultTracker.resultAmount, sizeof(enum ExprType));
        functionResultTracker.exprIsError = (int*) calloc(functionResultTracker.resultAmount, sizeof(int));
    }

    //assign type and line number to the last entry
    functionResultTracker.linenumResult[functionResultTracker.resultAmount - 1] = linenumber;
    functionResultTracker.resultType[functionResultTracker.resultAmount - 1] = exprSpec.exprType;
    functionResultTracker.exprIsError[functionResultTracker.resultAmount-1] = exprSpec.isError;
}

/////////////////WRITE CODE SECTION
///PUT INITIALIZATION IS DONE IN RULE DIRECTLY
///////////////////////////////////


// for result statement and put statement, since their structure is imilar
// int isPut; 0 = Result, 1 = Put
// Specification that wants to be printed or resulted
// linenumber: needed for storing which line is the return value
void resultPutSteps(int isPut, struct expr ExprSpec, int linenumber){
    // for Put, I aslo implement printing, but only if the expression doesn't involve function
    // for result, I will store them inside functionResultTracker global variable, but only if the expression is valid
    char errorMessageHelper[256] = "put";
    if(!isPut){
        strcpy(errorMessageHelper, "result");
    }

    if(ExprSpec.isError == 0){
        if(exprIsArray(ExprSpec.exprType)){
            printf("Error %d: Cant do %s due to input expression is an array\n", linenum, errorMessageHelper);
            errorExist = 1;
            if(!isPut){
                addResultEntryToGlobal(ExprSpec, linenumber);
                //later finishFunctionProcedureDeclaration can report the error
            }
        }else{
            // All type is valid except void_type
            if(ExprSpec.exprType == IEXPR) {
                // if expr is func, left unevaluated for now
                if(isPut){
                    /////////////////WRITE CODE SECTION
                    putStatementIntBoolean(&errorExist);
                    ///////////////////////////////////
                }else{
                    // a result expression
                    addResultEntryToGlobal(ExprSpec, linenumber);

                    /////////////////WRITE CODE SECTION
                    resultReturnStatement(&errorExist, INTEGER_TYPE);
                    ///////////////////////////////////
                }
            }else if(ExprSpec.exprType == DEXPR) {
                // if expr is func, left unevaluated for now
                /////////////////WRITE CODE SECTION
                encounterUnableToExpress(&errorExist, "double put/result", linenum);
                ///////////////////////////////////
                if(isPut){
                    
                }else{
                    // a result expression
                    addResultEntryToGlobal(ExprSpec, linenumber);
                }
            }else if(ExprSpec.exprType == SEXPR) {
                // if expr is func, left unevaluated for now
                if(isPut){
                    /////////////////WRITE CODE SECTION
                    putStatementString(&errorExist);
                    ///////////////////////////////////
                }else{
                    // a result expression
                    addResultEntryToGlobal(ExprSpec, linenumber);
                    /////////////////WRITE CODE SECTION
                    encounterUnableToExpress(&errorExist, "string result", linenum);
                    ///////////////////////////////////
                }
            }else if(ExprSpec.exprType == BEXPR) {
                // if expr is func, left unevaluated for now
                if(isPut){
                    /////////////////WRITE CODE SECTION
                    putStatementIntBoolean(&errorExist);
                    ///////////////////////////////////
                }else{
                    // a result expression
                    addResultEntryToGlobal(ExprSpec, linenumber);

                    /////////////////WRITE CODE SECTION
                    resultReturnStatement(&errorExist, BOOL_TYPE);
                    ///////////////////////////////////
                }
            }else{
                // not a valid type
                printf("Error %d: Not a valid expr, %s has invalid RHS Type : ", linenum, errorMessageHelper);
                exprTypePrintingNoArrayLengthHelper(ExprSpec.exprType);
                printf("\n");
                errorExist = 1;
            }
        }
    }else{
        // no need to continue, it is already an error
        if(isPut){
            printf("Error %d: Expression for put has an error\n", linenum);
            errorExist = 1;
        }else{
            printf("Error %d: Expression for result has an error, not counted as a result operation\n", linenum);
            errorExist = 1;
        }
        
    }
}

//operation that will be used for get and assignment (for variable, NOT ARRAY)
//int isGet, set 0 if it is assignment, set 1 if it is a get
//struct IdxPair identifierSpec, the identifier information from lex where we want to get or assign
//struct expr exprSpec, if it is an assignmentStatement, then this is the right hand side of it
void getAssignmentStepsIdentifier(int isGet, struct IdxPair identifierSpec, struct expr exprSpec){
    // Identifier should be a variable
    // Identifier type and Expr Type should be the same

    // Check in this scope whether identifier already exist
    // in this case,identifier should already be initialized
    char errorMessageHelper[256] = "assignment";
    if(isGet){
        strcpy(errorMessageHelper, "get");
        /////////////////WRITE CODE SECTION
        encounterUnableToExpress(&errorExist, "get statement", linenum);
        ///////////////////////////////////
    }

    if(identifierNotExistInAllScopeChecker(identifierSpec)){
        //identifier not exist in this scope
        printf("symtableidx: %d, innerIdx: %d, name:%s", identifierSpec.symTableIdx, identifierSpec.innerIdx, identifierSpec.varName);
        printf("Error %d: Invalid identifier %s for %s, undeclared in this scope\n", linenum, identifierSpec.varName, errorMessageHelper);
        printf("Enter here23\n");
        errorExist = 1;
    }else{
        // at this point it is found
        struct EntryAttributes varAttributes = fromIdxPairReturnAttributes(identifierSpec, debugMode);
        
        // only valid for variable type, other entity type cant do
        if(varAttributes.entryType == VAR_ENTTYPE){
            // type check
            // need to check whether Expr is error
            if(!isGet && exprSpec.isError == 1){
                // expr is error, declaration failed
                printf("Error %d: %s var is not assigned a value due to error in RHS expression\n", linenum, identifierSpec.varName);
                errorExist = 1;
            }else{
                // Check the type of the expr tne same with the type of the variable
                int assignmentValid = !isGet && translatorExprType(exprSpec.exprType) == varAttributes.varConstOrResType && !exprIsArray(exprSpec.exprType);
                if(isGet || assignmentValid){
                    // for now, if expr involves function, leave it as it is and not edit value at all
                    if(varAttributes.varConstOrResType == INTEGER_TYPE){
                        if(isGet){
                            // get statement
                            if(getCanScanfIdentifier && symbolTableStoreValue){
                                printf("---Scanf for integer variable %s: ", identifierSpec.varName);
                                scanf("%i", &varAttributes.iVal);
                            }
                        }else{
                            // assignment statement
                            //only assign to symbol table if assignment modes is enabled
                            if(!symbolTableStoreValue){
                                // always enter here, since symbolTableStoreValue is 0
                                /////////////////WRITE CODE SECTION
                                if(identifierIsGlobal(identifierSpec)){
                                    storeGlobalVarInt(&errorExist, identifierSpec);
                                }else{
                                    storeLocalVariableInteger(&errorExist, identifierSpec);
                                }
                                ///////////////////////////////////
                            }else{
                                //symbol table can store value
                                varAttributes.iVal = exprSpec.iVal;
                            }
                        }
                        editAttributesOnIndex(identifierSpec, varAttributes, debugMode); // reinsert to symbol table
                    }else if(varAttributes.varConstOrResType == DOUBLE_TYPE){
                        if(isGet){
                            // get statement
                            if(getCanScanfIdentifier && symbolTableStoreValue){
                                printf("---Scanf for real variable %s: ", identifierSpec.varName);
                                scanf("%lf", &varAttributes.dVal);
                            }
                        }else{
                            // assignment statement
                            //only assign if assignment modes is enabled
                            if(!symbolTableStoreValue){
                                // always enter here in project 3
                                /////////////////WRITE CODE SECTION
                                encounterUnableToExpress(&errorExist, "assignment float variable", linenum);
                                ///////////////////////////////////
                            }else{
                                //symbol table can store value
                                varAttributes.dVal = exprSpec.dVal;
                            }
                        }
                        editAttributesOnIndex(identifierSpec, varAttributes, debugMode); // reinsert to symbol table
                    }else if(varAttributes.varConstOrResType == STRING_TYPE){
                        if(isGet){
                            // get statement
                            if(getCanScanfIdentifier && symbolTableStoreValue){
                                printf("---Scanf for string variable %s: ", identifierSpec.varName);
                                scanf("%s", varAttributes.sVal);
                            }
                        }else{
                            // assignment statement
                            //only assign if assignment modes is enabled
                            if(!symbolTableStoreValue){
                                // always enter here in project 3
                                /////////////////WRITE CODE SECTION
                                encounterUnableToExpress(&errorExist, "assignment float variable", linenum);
                                ///////////////////////////////////
                            }else{
                                //symbol table can store value
                                strcpy(varAttributes.sVal, exprSpec.sVal);
                            }
                        }
                        editAttributesOnIndex(identifierSpec, varAttributes, debugMode); // reinsert to symbol table
                    }else if(varAttributes.varConstOrResType == BOOL_TYPE){
                        if(isGet){
                            // get statement
                            if(getCanScanfIdentifier && symbolTableStoreValue){
                                printf("---Scanf for bool variable %s, type 1 for true, 0 for false: ", identifierSpec.varName);
                                scanf("%i", &varAttributes.boolVal);
                            }
                        }else{
                            // assignment statement
                            //only assign if assignment modes is enabled
                            if(!symbolTableStoreValue){
                                // cannot store value
                                if(identifierIsGlobal(identifierSpec)){
                                    storeGlobalVarBoolean(&errorExist, identifierSpec);
                                }else{
                                    storeLocalVariableBoolean(&errorExist, identifierSpec);
                                }
                            }else{
                                //symbol table can store value
                                varAttributes.boolVal = exprSpec.boolVal;
                            }
                        }
                        editAttributesOnIndex(identifierSpec, varAttributes, debugMode); // reinsert to symbol table
                    }else{
                        // shouldnot enter here, if it does then it is my mistake
                        printf("Error %d: %s %s variable has invalid type: ", linenum, errorMessageHelper, identifierSpec.varName);
                        errorExist = 1;
                        typePrintingHelperInC(varAttributes.varConstOrResType);
                        printf("\n");
                    }
                }else{
                    // invalid assignment, different type of data
                    printf("Error %d: %s variable assignment invalid due to different datatype : ", linenum, identifierSpec.varName);
                    typePrintingHelperInC(varAttributes.varConstOrResType);
                    printf(" and ");
                    exprTypePrintingHelper(exprSpec.exprType, exprSpec.arrLength);
                    printf("\n");
                    errorExist = 1;
                }
            }
        }else if(varAttributes.entryType == CONST_ENTTYPE){
            // assignment statement invalid for identifier const entry
            printf("Error %d: variable %s invalid for const %s\n", linenum, errorMessageHelper, identifierSpec.varName);
            errorExist = 1;
        }else if(varAttributes.entryType == ARRAY_ENTTYPE){
            // assignment statement invalid for identifier array entry
            printf("Error %d: variable %s invalid for array %s\n", linenum, errorMessageHelper, identifierSpec.varName);
            errorExist = 1;
        }else if(varAttributes.entryType == FUNCTION_ENTTYPE){
            // assignment statement invalid for identifier function entry
            printf("Error %d: variable %s invalid for function / procedure %s\n", linenum, errorMessageHelper, identifierSpec.varName);
            errorExist = 1;
        }else{
            // unknown type
            printf("SelfError %d: %s : Unknown type of entry %s\n", linenum, errorMessageHelper, identifierSpec.varName);
            errorExist = 1;
        }
    }
}

//operation that will be used for get and assignment when involving array
//int isGet, set 0 if it is assignment, set 1 if it is a get
//struct IdxPair identifierSpec, the identifier information from lex where we want to get or assign
//struct expr exprSpec, if it is an assignmentStatement, then this is the right hand side of it
//struct expr indexExpr: int expr for accessing array index
void getAssignmentStepsIdentifierArray(int isGet, struct IdxPair identifierSpec, struct expr ExprSpec, struct expr IndexExprSpec){
    if(identifierNotExistInAllScopeChecker(identifierSpec)){
        printf("Error %d: Invalid identifier %s, undeclared in this scope\n", linenum, identifierSpec.varName);
        errorExist = 1;
    }else{
        // at this point it is found
        struct EntryAttributes arrAttributes = fromIdxPairReturnAttributes(identifierSpec, debugMode);

        char errorMessageHelper[256] = "get";
        if(isGet){
            strcpy(errorMessageHelper, "assignment");
            /////////////////WRITE CODE SECTION
            encounterUnableToExpress(&errorExist, "get statement of array", linenum);
            ///////////////////////////////////
        }else{
            /////////////////WRITE CODE SECTION
            encounterUnableToExpress(&errorExist, "assignment to an array", linenum);
            ///////////////////////////////////
        }


        // Should be an array type
        if(arrAttributes.entryType == ARRAY_ENTTYPE){
            // index checking
            if(IndexExprSpec.isError == 0 && !exprIsArray(IndexExprSpec.exprType) && IndexExprSpec.exprType == IEXPR){
                int indexValid = 1;
                int indexCanBeExtracted = IndexExprSpec.isConst;
                //can only check index validity if the expression value can be counted
                // won't check index validity unless input value is a const
                if(indexCanBeExtracted && constIntExprCanCheckIndexValidity)
                {
                    if(!arrayIndexValidityChecker(arrAttributes, IndexExprSpec.iVal)){
                        indexValid = 0;
                        printf("Error %d: (Plus point) %s Array Element %s, index value %i is invalid with index %i to %i\n", linenum, errorMessageHelper, identifierSpec.varName, IndexExprSpec.iVal, arrAttributes.startIndices, arrAttributes.endIndices);
                        errorExist = 1;
                    }
                }

                //only evaluate if it is an assignment operation
                int rightHandSideValid = 1;
                if(!isGet && ExprSpec.isError){
                    rightHandSideValid = 0;
                    printf("Error %d: Assignment Array element %s  is invalid due to RHS expression that will be assigned is invalid\n", linenum, identifierSpec.varName);
                    errorExist = 1;
                }else if (exprIsArray(ExprSpec.exprType)){
                    rightHandSideValid = 0;
                    printf("Error %d: Assignment Array element %s is invalid due to RHS expression that will be assign is an array\n",  linenum, identifierSpec.varName);
                    errorExist = 1;
                }else if(translatorExprType(ExprSpec.exprType) != arrAttributes.varConstOrResType){
                    rightHandSideValid = 0;
                    printf("Error %d: Assignment Array element %s is invalid due to type of RHS expression and array unmatched, expected: ", linenum, identifierSpec.varName);
                    typePrintingHelperInC(arrAttributes.varConstOrResType);
                    printf(", get: ");
                    exprTypePrintingHelper(ExprSpec.exprType, ExprSpec.arrLength);
                    printf("\n");
                    errorExist = 1;
                }


                //play with value assignment
                //only do if all these categories are fulfilled
                if(indexCanBeExtracted && indexValid && rightHandSideValid){
                    // valid index , for now do nothing because array element can't store value
                }
            }else{
                if(IndexExprSpec.isError){
                    printf("Error %d: Array Element %s %s failed, index expression is an error\n", linenum, errorMessageHelper, identifierSpec.varName);
                    errorExist = 1;
                }else if(exprIsArray(IndexExprSpec.exprType)){
                    printf("Error %d: Array Element %s %s failed, index expression is an array\n", linenum, errorMessageHelper, identifierSpec.varName);
                    errorExist = 1;
                }else if(IndexExprSpec.exprType != INTEGER_TYPE){
                    printf("Error %d: Array Element %s %s failed, only integer index is valid for array index\n", linenum, errorMessageHelper, identifierSpec.varName);
                    errorExist = 1;
                }
            }
        }else if(arrAttributes.entryType == CONST_ENTTYPE){
            printf("Error %d: Array Element %s failed, cannot assignment a const %s \n", linenum, errorMessageHelper, identifierSpec.varName);
            errorExist = 1;
        }else if(arrAttributes.entryType == FUNCTION_ENTTYPE){
            printf("Error %d: Array Element %s failed, cannot assignment a function or procedure %s \n", linenum, errorMessageHelper, identifierSpec.varName);
            errorExist = 1;
        }else{
            // array type should not have entered here, it means something is wrong with your parser
            printf("Error %d: Array Element %s failed, %s is a variable identifier, hence no index\n", linenum, errorMessageHelper, identifierSpec.varName);
            errorExist = 1;
        }
    }
}

%}
/* Writing Format: 
- Non Terminal: Pascal Case
- Terminal : CAPSLOCK
*/

%union {
    struct expr exprContent;
    enum Type typeContent;
    char strContent[256];
    double doubleContent;
    int intContent;
    struct IdxPair idx;
    struct ArgAccumulation funcArgContent;
    struct RightOfIdentifierInformation rightOfIdentifierInformationContent;
}

/*Nonterminals*/
%type <exprContent> Expr //Expressions
%type <exprContent> IdentifierConsts //Collection of consts call or identifier calls for expression usage
%type <typeContent> Type //Type speficiation keywords: "int", "real", "bool", "string"
%type <intContent> DecreaseOrNot //included in For contruct, whether it involves the keyword "decrease" or not
%type <funcArgContent> FunctionArgList //Lists of Function Argument
%type <funcArgContent> FunctionArg //The first function argument
%type <funcArgContent> FunctionArgFollowUp //the function argument follow up the FunctionArg
%type <funcArgContent> FunctionCallBrackets //structure when calling Function In Expression
%type <funcArgContent> FunctionParameters //The first function parameter
%type <funcArgContent> FunctionParametersFollowUp //the function parameter following up FunctionParameters
%type <exprContent> ArrayCallBrackets //brackets content to call array element
%type <rightOfIdentifierInformationContent> RightOfIdentifier //when calling identifier in expression, this is the token that follows on its right
%type <intContent> ExitCondition //whether it is unconditionalexit (no rhs), set to 1

/* Start symbol*/
%start AllStmts

/* Keywords*/
%token BEGINKWD BOOL CHAR DECREASING DEFAULT DO ELSE END EXIT FALSE FOR IF INT LOOP OF PUT REAL RESULT RETURN SKIP STRING THEN TRUE WHEN
/* Delimiters*/
%token DOT COMMA COLON SEMICOLON OPENBRACKET CLOSINGBRACKET
/* For now I regard assignment statement to be non associative because can't chain assign*/
%nonassoc ASSIGNMENT 
%left LOGICALOR
/* Logical Operators except NOT, left associative*/
%left LOGICALAND
%right LOGICALNOT
/* Relational Operator equal and not equal, Left associative*/
%left RELATIONALEQ RELATIONALNOT RELATIONALLE RELATIONALLT RELATIONALGE RELATIONALGT
/* Binary Arithmetic Operator*/ 
%left ADDITION SUBTRACTION
%left MULTIPLICATION DIVISION REMAINDER
/* Unary Operators, only UMINUS Arithmetic*/
%nonassoc UMINUS
/* Need to be lower than the rest of the operator*/
%token OPENPARENTHESES CLOSINGPARENTHESES

/* Try placing it lower than operator to defeat their precedence */
%token <idx> IDENTIFIER 
%token <intContent> INTCONST 
%token <doubleContent> REALCONST 
%token <strContent> STRINGCONST


/* Try placing it down than the others To defeat the precedence of IDENTIFIER (so they are not indicated as variable/function call expression) */ 
%token ARRAY CONST VAR FUNCTION PROCEDURE GET OPENSQUAREBRACKET CLOSINGSQUAREBRACKET
%%

/* 
AllStmts: Basically the whole program
There is only 1 global scope in a program， or the program is empty*/
AllStmts:   GlobalScope
            {
                Trace("Reducing to AllStmts 1(From GlobalScope)\n");
            }
            | /*Empty*/
            {
                Trace("Reducing to AllStmts 2(Empty)\n");
            }


/* GlobalStmts: a global program can only consist of declaration section. and NonDeclarationSections that follow after it*/
GlobalScope:    DeclarationSections NonDeclarationSections
                {
                    Trace("Reducing to GlobalScope 1(From DeclarationSections and NonDeclarationSections)\n");
                }
                | DeclarationSections
                {
                    Trace("Reducing to GlobalScope 2(From DeclarationSections)\n");
                }
                | NonDeclarationSections
                {
                    Trace("Reducing to GlobalScope 3(From NonDeclarationSections)\n");
                }



/* Sections consist of one or many statements */
DeclarationSections: DeclarationSections DeclarationStatement
                     {
                        Trace("Reducing to DeclarationSections 1(From DeclarationSections and DeclarationStatement)\n");
                     }
                     | DeclarationStatement
                     {
                        Trace("Reducing to DeclarationSections 2(From DeclarationStatement)\n");
                     }

NonDeclarationSections: NonDeclarationSections NonDeclarationStatement
                        {
                            Trace("Reducing to NonDeclarationSections 1(From NonDeclaration Sections to NonDeclarationStatement)\n");
                        }
                        | NonDeclarationStatement
                        {
                            Trace("Reducing to NonDeclarationSections 2(From NonDeclarationStatement)\n");
                        }

/* Each statement differentiated to different construct
*/
DeclarationStatement: ConstDeclConstruct
                      {
                        Trace("Reducing to DeclarationStatement 1(From ConstDeclConstruct)\n");
                      }
                      | VarDeclConstruct
                      {
                        Trace("Reducing to DeclarationStatement 2(From VarDeclConstruct)\n");
                      }
                      | ArrayDeclConstruct
                      {
                        Trace("Reducing to DeclarationStatement 3(From ArrayDeclConstruct)\n");
                      }
                      | ProcedureDeclarationConstruct
                      {
                        Trace("Reducing to DeclarationStatement 4(From ProcedureDeclarationConstruct)\n");
                      }
                      | FunctionDeclarationConstruct
                      {
                        Trace("Reducing to DeclarationStatement 5(From FunctionDeclarationConstruct)\n");
                      }

ProcedureDeclarationConstruct: PROCEDURE IDENTIFIER 
                               {
                                    if(inAFunction > 0){
                                        printf("Error %d: Invalid Procedure declaration %s is inside another function, nevertheless still put to symbol table for now, this event will cause syntax error message\n", linenum, $2.varName);
                                        errorExist = 1;
                                    }
                                    if(inAProcedure > 0){
                                        printf("Error %d: Invalid Procedure declaration %s is inside another procedure, nevertheless still put to symbol table for now, this event will cause syntax error message\n", linenum, $2.varName);
                                        errorExist = 1;
                                    }
                                    if(inALoopOrFor > 0){
                                        printf("Error %d: Invalid Procedure declaration %s is inside a loop, nevertheless still put to symbol table for now, this event will cause syntax error message\n", linenum, $2.varName);
                                        errorExist = 1;
                                    }
                                    //midrule needed to insert new symbol table, done inside the function
                                    //creation of symbol table is done in the function
                                    int isFunc = 0; //1 = procedure, 0 = function
                                    struct IdxPair globalIdentifierSpec = $2; //global scope identifier specification
                                    int linenumber = linenum;
                                    functionStartLine = linenum;
                                    initialFunctionProcedureDeclaration(isFunc, globalIdentifierSpec, linenumber);
                                    inAProcedure += 1;
                                }FunctionArgList {
                                    //new midrule for proj3
                                    /////////////////WRITE CODE SECTION
                                    functionDeclarationBegin(&errorExist, $2, VOID_TYPE, $4);
                                    ///////////////////////////////////
                                }ProcedureAllStatements END IDENTIFIER
                                {
                                    Trace("Reducing to ProcedureDeclarationConstruct\n");
                                    int isFunc = 0; //0 = procedure, 1 = function
                                    struct IdxPair globalIdentifierSpec = $2; // global scope identifier specification
                                    int linenumber = functionStartLine; //declared line number
                                    struct ArgAccumulation  argumentList = $4; // List of the argument specification for the function
                                    int endingNameIsSame = strcmp($2.varName, $8.varName) == 0; // back in function/procedure when meeting END, IDENTIFIER name that follows should match
                                    enum Type resultTypeSpec = VOID_TYPE; //resultTypeSpec: declared result type, only for function
                                    finishFunctionProcedureDeclaration(isFunc,  globalIdentifierSpec, linenumber, argumentList, endingNameIsSame, resultTypeSpec);
                                    // erasing scope of symbol table is done within the function
                                    /////////////WRITE CODE SECTION
                                    functionDeclarationEnd(&errorExist, resultTypeSpec);
                                    ///////////////////////////////
                                    inAProcedure -= 1;
                                }
FunctionDeclarationConstruct:   FUNCTION IDENTIFIER {
                                    if(inAFunction > 0){
                                        printf("Error %d: Invalid Function declaration %s is inside another function, nevertheless still put to symbol table for now, this event will cause syntax error message\n", linenum, $2.varName);
                                        errorExist = 1;
                                    }
                                    if(inAProcedure > 0){
                                        printf("Error %d: Invalid Function declaration %s is inside another procedure, nevertheless still put to symbol table for now, this event will cause syntax error message\n", linenum, $2.varName);
                                        errorExist = 1;
                                    }
                                    if(inALoopOrFor > 0){
                                        printf("Error %d: Invalid Function declaration %s is inside a loop, nevertheless still put to symbol table for now, this event will cause syntax error message\n", linenum, $2.varName);
                                        errorExist = 1;
                                    }
                                    //midrule needed to insert new symbol table
                                    int isFunc = 1; //1 = procedure, 0 = function
                                    struct IdxPair globalIdentifierSpec = $2; //global scope identifier specification
                                    int linenumber = linenum;
                                    initialFunctionProcedureDeclaration(isFunc, globalIdentifierSpec, linenumber);
                                    functionStartLine = linenum;
                                    inAFunction += 1;
                                }FunctionArgList COLON Type {
                                    //new midrule for proj3
                                    /////////////////WRITE CODE SECTION
                                    functionDeclarationBegin(&errorExist, $2, $6, $4);
                                    ///////////////////////////////////
                                }FunctionAllStatements END IDENTIFIER
                                {
                                    Trace("Reducing to FunctionDeclarationConstruct\n");
                                    int isFunc = 1; //0 = procedure, 1 = function
                                    struct IdxPair globalIdentifierSpec = $2; // global scope identifier specification
                                    int linenumber = functionStartLine; //declared line number
                                    struct ArgAccumulation argumentList = $4; // List of the argument specification for the function
                                    int endingNameIsSame = strcmp($2.varName, $10.varName) == 0; // back in function/procedure when meeting END, IDENTIFIER name that follows should match
                                    enum Type resultTypeSpec = $6; //resultTypeSpec: declared result type, only for function
                                    finishFunctionProcedureDeclaration(isFunc,  globalIdentifierSpec, linenumber, argumentList, endingNameIsSame, resultTypeSpec);
                                    // erasing scope of symbol table is done within the function
                                    /////////////WRITE CODE SECTION
                                    functionDeclarationEnd(&errorExist, resultTypeSpec);
                                    ///////////////////////////////
                                    inAFunction -= 1;
                                }

FunctionArgList:        /*Empty*/
                        {
                            Trace("Reducing to FunctionArgList 1 (No Parentheses, which is an error)\n");
                            struct ArgAccumulation resultArgument = defaultArgAccumulationValue();
                            resultArgument.isEncounterError = 1;
                            printf("Error %d: Function does not specify parameter and does not use parentheses, need to use parentheses even with no parameters\n", linenum);
                            errorExist = 1;
                            $$ = resultArgument;
                        }
                        | OPENPARENTHESES FunctionArg CLOSINGPARENTHESES
                        {
                            //May be empty may be not
                            Trace("Reducing to FunctionArgList 2 (Parentheses with FunctionArg)\n");
                            // copy the result on FunctionArg to the return value
                            struct ArgAccumulation resultArgument = defaultArgAccumulationValue();
                            resultArgument.isEncounterError = $2.isEncounterError;
                            if($2.paramsLength > 0){
                                resultArgument.paramsLength = $2.paramsLength;
                                resultArgument.paramsOrdering = $2.paramsOrdering;
                                resultArgument.eachParamsHowManyElements = $2.eachParamsHowManyElements;
                            }else{
                                resultArgument.paramsLength = 0;
                                resultArgument.paramsOrdering = NULL;
                                resultArgument.eachParamsHowManyElements = NULL;
                            }

                            $$ = resultArgument;
                        }
FunctionArg:            /*empty*/
                        {
                            // has bracket but no function argument
                            Trace("Reducing to FunctionArg 1 (Empty)\n");
                            //indicate that the result is empty
                            struct ArgAccumulation resultArgument = defaultArgAccumulationValue();
                            $$ = resultArgument;
                        }
                        | FunctionArgFollowUp IDENTIFIER COLON Type 
                        {
                            // has at least one function argument
                            Trace("Reducing to FunctionArg 2 (Variable Arg with FunctionArgFollowUp)\n");
                            //check whether the declaration of identifier is valid, that is in this symbol table it should not exist before
                            int isDeclaration = 1; //isDeclaration: 1 if this is a declaration, 0 if it is part of a function call
                            struct IdxPair identifierPos = $2; //identifierPos: Identifier specification for declaration
                            enum Type varType = $4; //varType: type of identifier that is going to use for declaration
                            struct ArgAccumulation followUpArguments = $1;//followUpArguments, the list of arguments that come after it (because argument is in left recursion)
                            int linenumber = linenum; //current line number
                            int callExprIsError = 0; //this one not used if it is a declaration
                            struct ArgAccumulation resultArgument = functionVarArgumentChecker(isDeclaration, identifierPos, varType, followUpArguments, linenumber, callExprIsError);
                            $$ = resultArgument;
                        }
                        |  FunctionArgFollowUp IDENTIFIER COLON ARRAY INTCONST DOT DOT INTCONST OF Type
                        {
                            // has at least one function argument, array
                            Trace("Reducing to FunctionArg 3 (Array arg with FunctionArgFollowUp)\n");
                            int isDeclaration = 1; //isDeclaration: 1 if this is a declaration, 0 if it is part of a function call
                            struct IdxPair identifierPos = $2; //identifierPos: Identifier specification for declaration
                            enum Type varType = $10; //varType: type of identifier that is going to use for declaration
                            int startIndices = $5; //startIndices: start index of the array
                            int endIndices = $8; //endIndices: end index of the array
                            struct ArgAccumulation followUpArguments = $1; //followUpArguments, the list of arguments that come after it (because argument is in left recursion)
                            int linenumber = linenum; //current line number
                            int callExprIsError = 0; //this one not used if it is a declaration
                            struct ArgAccumulation resultArgument = functionArrayArgumentChecker(isDeclaration, identifierPos, varType, startIndices, endIndices, followUpArguments, linenumber, callExprIsError);
                            $$ = resultArgument;
                        }

// what follows after the comma
FunctionArgFollowUp:    FunctionArgFollowUp IDENTIFIER COLON Type COMMA 
                        {
                            // has at least one function argument
                            Trace("Reducing to FunctionArgFollowUp 1 (Comma Variable Arg with FunctionArgFollowUp)\n");
                            //check whether the declaration of identifier is valid, that is in this symbol table it should not exist before
                            int isDeclaration = 1; //isDeclaration: 1 if this is a declaration, 0 if it is part of a function call
                            struct IdxPair identifierPos = $2; //identifierPos: Identifier specification for declaration
                            enum Type varType = $4; //varType: type of identifier that is going to use for declaration
                            struct ArgAccumulation followUpArguments = $1;//followUpArguments, the list of arguments that come after it (because argument is in left recursion)
                            int linenumber = linenum;
                            int callExprIsError = 0; //this one is not used if function is declaration
                            struct ArgAccumulation resultArgument = functionVarArgumentChecker(isDeclaration, identifierPos, varType, followUpArguments, linenumber, callExprIsError);
                            $$ = resultArgument;
                        }
                        |  FunctionArgFollowUp IDENTIFIER COLON ARRAY INTCONST DOT DOT INTCONST OF Type COMMA
                        {
                            Trace("Reducing to FunctionArgFollowUp 2 (Comma with Array Arg with FunctionArgFollowUp)\n");
                            //check whether the declaration of identifier is valid, that is in this symbol table it should not exist before
                            int isDeclaration = 1; //isDeclaration: 1 if this is a declaration, 0 if it is part of a function call
                            struct IdxPair identifierPos = $2; //identifierPos: Identifier specification for declaration
                            enum Type varType = $10; //varType: type of identifier that is going to use for declaration
                            int startIndices = $5; //startIndices: start index of the array
                            int endIndices = $8; //endIndices: end index of the array
                            struct ArgAccumulation followUpArguments = $1; //followUpArguments, the list of arguments that come after it (because argument is in left recursion)
                            int linenumber = linenum;
                            int callExprIsError = 0;
                            struct ArgAccumulation resultArgument = functionArrayArgumentChecker(isDeclaration, identifierPos, varType, startIndices, endIndices, followUpArguments,linenumber, callExprIsError);
                            $$ = resultArgument;

                        }
                        | /*empty*/
                        {
                            Trace("Reducing to FunctionArgFollowUp 3 (Empty)\n");
                            struct ArgAccumulation resultArgument = defaultArgAccumulationValue();
                            $$ = resultArgument;
                        }

ProcedureAllStatements: /* Empty */
                        {
                            Trace("Reducing to ProcedureAllStatements 1(Empty)\n");
                        }
                        | ProcedureScope
                        {
                            Trace("Reducing to ProcedureAllStatements 2(From Procedure Scope)\n");
                        }

/*Cant redeclare function/procedure inside another function/procedure
The NonDeclarationSections is usual + return statement*/
ProcedureScope:     ProcUniversalSections
                    {
                        Trace("Reducing to ProcedureScope 1(ProcUniversalSections)\n");
                    }

FunctionAllStatements:  /* Empty */
                        {
                            Trace("Reducing to FunctionAllStatements 1(Empty)\n");
                        }
                        | FunctionScope
                        {
                            Trace("Reducing to FunctionAllStatements 2(From FunctionScope)\n");
                        }

/*Cant redeclare function/procedure inside another function/procedure
The NonDeclarationSections is usual + Result Statement */
FunctionScope:  FuncUniversalSections
                {
                    Trace("Reducing to FunctionScope 1(Func Universal Sections)\n");
                }

ProcUniversalSections:  ProcUniversalSections ProcUniversalStatement
                        {
                            Trace("Reducing to ProcUniversalSections 1 (from ProcUniversalSections branching to ProcUniversalStatement)\n");
                        }
                        | ProcUniversalStatement
                        {
                            Trace("Reducing to ProcUniversalSections 2 (ProcUniversalStatement)\n");
                        }

ProcUniversalStatement: PutStatement
                        {
                            Trace("Reducing to ProcUniversalStatement 1 (Put)\n");
                        }
                        | GetStatement
                        {
                            Trace("Reducing to ProcUniversalStatement 2 (Get)\n");
                        }
                        | AssignmentStatement
                        {
                            Trace("Reducing to ProcUniversalStatement 3 (Assignment)\n");
                        }
                        | LoopConstruct
                        {
                            Trace("Reducing to ProcUniversalStatement 4 (Loop)\n");
                        }
                        | BlockConstruct
                        {
                            Trace("Reducing to ProcUniversalStatement 5 (Block)\n");
                        }
                        | IfConstruct
                        {
                            Trace("Reducing to ProcUniversalStatement 6 (If)\n");
                        }
                        | ForConstruct
                        {
                            Trace("Reducing to ProcUniversalStatement 7 (For)\n");
                        }
                        | ReturnStatement
                        {
                            Trace("Reducing to ProcUniversalStatement 8 (Return)\n");
                        }
                        | ResultStatement
                        {
                            //because procedure declaration inside function declaration is invalid
                            printf("Error %d: Invalid! Result statement encountered inside a procedure not a function, this will cause procedure declaration to fail\n",linenum);
                            errorExist = 1;
                            Trace("Reducing to ProcUniversalStatement 10 (ResultStatement)\n");
                        }
                        | ExitStatement
                        {
                            //because procedure declaration inside loop/for is invalid
                            Trace("Reducing to ProcUniversalStatement 11 (ExitStatement)\n");
                        }
                        | SkipStatement
                        {
                            Trace("Reducing to ProcUniversalStatement 12 (SkipStatement)\n");
                        }
                        | NoFuncProcDeclStatement 
                        {
                            Trace("Reducing to ProcUniversalStatement 13 (NoFuncProcDeclStatement)\n");
                        }
                        | Expr
                        {
                            if($1.isFunc && $1.exprType != VEXPR){
                                printf("Error %d: Not a valid expression! Standalone expression can only in form of procedure / (procedure) / expression \n", linenum);
                                errorExist = 1;
                            }
                            if($1.exprType != VEXPR){
                                ////////////WRITE CODE SECTION
                                popExpression(&errorExist);
                                //////////////////////////////
                            }
                            Trace("Reducing to ProcUniversalStatement 14 (Expr)\n");
                        }

FuncUniversalSections:  FuncUniversalSections FuncUniversalStatement
                        {
                            Trace("Reducing to FuncUniversalSections 1 (From FuncUniversalSections branching to FuncUniversalStatement))\n");
                        }
                        | FuncUniversalStatement
                        {
                            Trace("Reducing to FuncUniversalStatement 2 (From FuncUniversalStatement)\n");
                        }



FuncUniversalStatement: PutStatement
                        {
                            Trace("Reducing to FuncUniversalStatement 1 (Put)\n");
                        }
                        | GetStatement
                        {
                            Trace("Reducing to FuncUniversalStatement 2 (Get)\n");
                        }
                        | AssignmentStatement
                        {
                            Trace("Reducing to FuncUniversalStatement 3 (Assignment)\n");
                        }
                        | LoopConstruct
                        {
                            Trace("Reducing to FuncUniversalStatement 4 (Loop)\n");
                        }
                        | BlockConstruct
                        {
                            Trace("Reducing to FuncUniversalStatement 5 (Block)\n");
                        }
                        | IfConstruct
                        {
                            Trace("Reducing to FuncUniversalStatement 6 (If)\n");
                        }
                        | ForConstruct
                        {
                            Trace("Reducing to FuncUniversalStatement 7 (For)\n");
                        }
                        | ResultStatement
                        {
                            Trace("Reducing to FuncUniversalStatement 8 (Result)\n");
                        }
                        | ReturnStatement
                        {
                            //because function declaration inside procedure declaration is invalid
                            printf("Error %d: Invalid! Return statement encountered inside a function not a procedure\n",linenum);
                            errorExist = 1;
                            Trace("Reducing to FuncUniversalStatement 10 (ReturnStatement)\n");
                        }
                        | ExitStatement
                        {
                            //because function declaration inside loop/for is invalid
                            Trace("Reducing to FuncUniversalStatement 11 (ExitStatement)\n");
                        }
                        | SkipStatement
                        {
                            Trace("Reducing to FuncUniversalStatement 12 (SkipStatement)\n");
                        }
                        | NoFuncProcDeclStatement 
                        {
                            Trace("Reducing to FuncUniversalStatement 13 (NoFuncProcDeclStatement)\n");
                        }
                        | Expr
                        {
                            if($1.isFunc && $1.exprType != VEXPR){
                                printf("Error %d: Not a valid expression! Standalone expression can only in form of procedure / (procedure) / expression \n", linenum);
                                errorExist = 1;
                            }
                            if($1.exprType != VEXPR){
                                ////////////WRITE CODE SECTION
                                popExpression(&errorExist);
                                //////////////////////////////
                            }
                            Trace("Reducing to FuncUniversalStatement 14 (Expr)\n");
                        }

NoFuncProcDeclStatement:    ConstDeclConstruct
                            {
                                Trace("Reducing to NoFuncProcDeclStatement 1 (Const declare)\n");
                            }
                            | VarDeclConstruct
                            {
                                Trace("Reducing to NoFuncProcDeclStatement 2 (Variable declare)\n");
                            }
                            | ArrayDeclConstruct
                            {
                                Trace("Reducing to NoFuncProcDeclStatement 3 (Array Declare)\n");
                            }

NonDeclarationStatement: PutStatement
                        {
                            Trace("Reducing to NonDeclarationStatement 1 (From Put)\n");
                        }
                        | GetStatement
                        {
                            Trace("Reducing to NonDeclarationStatement 2 (From Get)\n");
                        }
                        | AssignmentStatement
                        {
                            Trace("Reducing to NonDeclarationStatement 3 (From Assignment)\n");
                        }
                        | LoopConstruct
                        {
                            Trace("Reducing to NonDeclarationStatement 4 (From Loop)\n");
                        }
                        | BlockConstruct
                        {
                            Trace("Reducing to NonDeclarationStatement 5 (From Block)\n");
                        }
                        | IfConstruct
                        {
                            Trace("Reducing to NonDeclarationStatement 6 (From If)\n");
                        }
                        | ForConstruct
                        {
                            Trace("Reducing to NonDeclarationStatement 7 (From For)\n");
                        }
                        | ResultStatement
                        {
                            //there might be result or return, whether this scope is inside a function
                            //to counter if/local scope inside a function, which is still valid
                            if(inAFunction <= 0){
                                printf("Error %d: Invalid! Result statement encountered in a scope where it is not inside a function\n",linenum);
                                errorExist = 1;
                            }
                            Trace("Reducing to NonDeclarationStatement 9 (ResultStatement)\n");
                        }
                        | ExitStatement
                        {
                            //there might be Exit or Skip, whether this scope is inside a function
                            //to counter if/local inside a loop construct, which is still valid
                            Trace("Reducing to NonDeclarationStatement 10 (ExitStatement)\n");
                        }
                        | SkipStatement
                        {
                            //there might be Exit or Skip, whether this scope is inside a function
                            //to counter if inside a loop construct, which is still valid
                            Trace("Reducing to NonDeclarationStatement 11 (SkipStatement)\n");
                        }
                        | ReturnStatement
                        {
                            //there might be result or return, whether this scope is inside a function
                            //to counter if/local scope inside a function, which is still valid
                            if(inAProcedure <= 0){
                                printf("Error %d: Invalid! Return statement encountered in a scope where it is not inside a function\n",linenum);
                                errorExist = 1;
                            }
                            Trace("Reducing to NonDeclarationStatement 12 (ReturnStatement)\n");
                        }
                        | Expr
                        {
                            if($1.isFunc && $1.exprType != VEXPR){
                                printf("Error %d: Not a valid expression! Standalone expression can only in form of procedure / (procedure) / expression \n", linenum);
                                errorExist = 1;
                            }
                            if($1.exprType != VEXPR){
                                ////////////WRITE CODE SECTION
                                popExpression(&errorExist);
                                //////////////////////////////
                            }
                            Trace("Reducing to NonDeclarationStatement 13 (Expr)\n");
                        }
                        ;

/*Warning, for now since we have no way evaluating the statement of the if, all update (including variable in outside scope) will have its value updated,
nevertheless it is in the THEN or the ELSE*/
IfConstruct:    IF Expr THEN 
                {
                    //Expr should be a bool and not error
                    if($2.isError || $2.exprType != BEXPR || exprIsArray($2.exprType)){
                        printf("Error %d: Ill defined if: it is not a bool expr without error, but for now I will continue parse the rest and create local scope\n", linenum);
                        errorExist = 1;
                    }
                    //mid rule needed to insert the symbol table
                    create(debugMode, 0);
                    /////////////////WRITE CODE SECTION
                    ifStatementBegin(&errorExist);
                    ///////////////////////////////////
                }IfAllStatements 
                {
                    popBack(debugMode, 0);
                }ElseOrNot END IF
                {
                    /////////////////WRITE CODE SECTION
                    ifStatementEnd(&errorExist);
                    ///////////////////////////////////
                    Trace("Reducing to IfConstruct 1\n");
                }

ElseOrNot:      /*empty*/
                {
                    Trace("Reducing to ElseOrNot 1 (Empty No Else)\n");
                }
                | ELSE 
                {
                    //mid rule needed to insert the symbol table
                    create(debugMode, 0);
                    /////////////////WRITE CODE SECTION
                    elseStatementBegin(&errorExist);
                    ///////////////////////////////////
                }IfAllStatements
                {
                    Trace("Reducing to ElseOrNot 2 (Else IfAllStatements)\n");
                    popBack(debugMode, 0);
                }

IfAllStatements: /*empty*/
                {
                    Trace("Reducing to IfAllStatements 1(Empty)\n");
                }
                | IfScope{
                    Trace("Reducinng to IfAllStatements 2(From If Scope)\n");
                }

/*If has no Procedure and Function declaration in it, the other is just like usual local scope*/
IfScope:    LocalUniversalSections
            {
                Trace("Reducing to IfScope (LocalUniversalSections)\n");
            }

/* Begins with begin and ends with end*/
BlockConstruct: BEGINKWD { 
                    // Mid rule needed to make new symbol table Scope
                    create(debugMode, 0);
                    /////////////////WRITE CODE SECTION
                    beginBlockBegin(&errorExist);
                    ///////////////////////////////////
                } LocalAllStatements END
                {
                    Trace("Reducing to BlockConstruct\n");
                    // done with the Block, pop the back of symbol table
                    /////////////////WRITE CODE SECTION
                    beginBlockEnd(&errorExist);
                    ///////////////////////////////////
                    popBack(debugMode, 0);
                }

LocalAllStatements: /*Empty*/
                    {
                        Trace("Reducing to LocalAllStatements 1(Empty)\n");
                    }
                    | LocalScope
                    {
                        Trace("Reducing to LocalAllStatements 2(LocalScope)\n");
                    }

/*For now, all the sections of LocalScope and GlobalScope is identical, put different non terminal name just for convenience*/ 
LocalScope:     LocalUniversalSections
                {
                    Trace("Reducing to LocalScope 1 (LocalUniversalSections)\n");
                }

LocalUniversalSections: LocalUniversalSections LocalUniversalStatement
                        {
                            Trace("Reducing to LocalUniversalSections 1 (LocalUniversalSections branching with LocalUniversalStatement)\n");
                        }
                        | LocalUniversalStatement
                        {
                            Trace("Reducing to LocalUniversalSections 2 (LocalUniversalStatement)\n");
                        }

LocalUniversalStatement:    PutStatement
                            {
                                Trace("Reducing to LocalUniversalStatement 1 (Put)\n");
                            }
                            | GetStatement
                            {
                                Trace("Reducing to LocalUniversalStatement 2 (Get)\n");
                            }
                            | AssignmentStatement
                            {
                                Trace("Reducing to LocalUniversalStatement 3 (Assignment)\n");
                            }
                            | LoopConstruct
                            {
                                Trace("Reducing to LocalUniversalStatement 4 (Loop)\n");
                            }
                            | BlockConstruct
                            {
                                Trace("Reducing to LocalUniversalStatement 5 (Block)\n");
                            }
                            | IfConstruct
                            {
                                Trace("Reducing to LocalUniversalStatement 6 (If)\n");
                            }
                            | ForConstruct
                            {
                                Trace("Reducing to LocalUniversalStatement 7 (For)\n");
                            }
                            | SkipStatement
                            {
                                Trace("Reducing to LocalUniversalStatement 9 (Skip)\n");
                            }
                            | ExitStatement
                            {
                                // handle local scope inside loop
                                Trace("Reducing to LocalUniversalStatement 10 (Exit)\n");
                            }
                            | ReturnStatement
                            {
                                // handle a loop inside a procedure
                                if(inAProcedure <= 0){
                                    printf("Error %d: Invalid! Return statement encountered in a loop/for where it is not inside procedure declaration\n",linenum);
                                    errorExist = 1;
                                }
                                Trace("Reducing to LocalUniversalStatement 11 (ReturnStatement)\n");
                            }
                            | ResultStatement
                            {
                                //handle a loop inside a function
                                if(inAFunction <= 0){
                                    printf("Error %d: Invalid! Result statement encountered in a loop/for, where it is not inside function declaration\n",linenum);
                                    errorExist = 1;    
                                }
                                Trace("Reducing to LocalUniversalStatement 12 (ResultStatement)\n");
                            }
                            | NoFuncProcDeclStatement
                            {
                                Trace("Reducing to LocalUniversalStatement 13 (NoFuncProcDeclStatement)\n");
                            }
                            | Expr
                            {
                                if($1.isFunc && $1.exprType != VEXPR){
                                    printf("Error %d: Not a valid expression! Standalone expression can only in form of procedure / (procedure) / expression \n", linenum);
                                    errorExist = 1;
                                }
                                if($1.exprType != VEXPR){
                                    ////////////WRITE CODE SECTION
                                    popExpression(&errorExist);
                                    //////////////////////////////
                                }
                                Trace("Reducing to LocalUniversalStatement 14 (Expr)\n");
                            }

/*Loop Scope needs differences for available statement, see further detail*/
LoopConstruct:  LOOP {
                    // Mid rule needed to make new symbol table Scope
                    create(debugMode, 0);
                    inALoopOrFor += 1;
                    /////////////////WRITE CODE SECTION
                    loopStatementBegin(&errorExist);
                    ///////////////////////////////////
                } LoopAllStatements END LOOP
                {
                    Trace("Reducing to LoopConstruct\n");
                    /////////////////WRITE CODE SECTION
                    loopStatementEnd(&errorExist);
                    ///////////////////////////////////
                    // done with the Loop, pop the back of symbol table
                    popBack(debugMode, 0);
                    inALoopOrFor -= 1;
                }

LoopAllStatements:  /*Empty*/
                    {
                        Trace("Reducing to LoopAllStatements 1(Empty)\n");
                    }
                    | LoopScope
                    {
                        Trace("Reducing to LoopAllStatements 2(LoopScope)\n");
                    }

LoopScope:  LoopUniversalSections
            {
                Trace("Reducing to LoopScope 1 (LoopUniversalSections)\n");
            }

LoopUniversalSections:      LoopUniversalSections LoopUniversalStatement
                            {
                                Trace("Reducing to LoopUniversalSections 1 (Branching of LoopUniversalSections to LoopUniversalStatement)\n");
                            }
                            | LoopUniversalStatement
                            {
                                Trace("Reducing to LoopUniversalSections 2 (From LoopUniversalStatement)\n");
                            }

/*From the NonDeclarationStatement, need to add skip statement, and exit statement*/
LoopUniversalStatement:     PutStatement
                            {
                                Trace("Reducing to LoopUniversalStatement 1 (Put)\n");
                            }
                            | GetStatement
                            {
                                Trace("Reducing to LoopUniversalStatement 2 (Get)\n");
                            }
                            | AssignmentStatement
                            {
                                Trace("Reducing to LoopUniversalStatement 3 (Assignment)\n");
                            }
                            | LoopConstruct
                            {
                                Trace("Reducing to LoopUniversalStatement 4 (Loop)\n");
                            }
                            | BlockConstruct
                            {
                                Trace("Reducing to LoopUniversalStatement 5 (Block)\n");
                            }
                            | IfConstruct
                            {
                                Trace("Reducing to LoopUniversalStatement 6 (If)\n");
                            }
                            | ForConstruct
                            {
                                Trace("Reducing to LoopUniversalStatement 7 (For)\n");
                            }
                            | SkipStatement
                            {
                                Trace("Reducing to LoopUniversalStatement 9 (Skip)\n");
                            }
                            | ExitStatement
                            {
                                Trace("Reducing to LoopUniversalStatement 10 (Exit)\n");
                            }
                            | ReturnStatement
                            {
                                // handle a loop inside a procedure
                                if(inAProcedure <= 0){
                                    printf("Error %d: Invalid! Return statement encountered in a loop/for where it is not inside procedure declaration\n",linenum);
                                    errorExist = 1;
                                }
                                Trace("Reducing to LoopUniversalStatement 11 (ReturnStatement)\n");
                            }
                            | ResultStatement
                            {
                                //handle a loop inside a function
                                if(inAFunction <= 0){
                                    printf("Error %d: Invalid! Result statement encountered in a loop/for, where it is not inside function declaration\n",linenum);
                                    errorExist = 1;    
                                }
                                Trace("Reducing to LoopUniversalStatement 12 (ResultStatement)\n");
                            }
                            | NoFuncProcDeclStatement
                            {
                                Trace("Reducing to LoopUniversalStatement 13 (NoFuncProcDeclStatement)\n");
                            }
                            | Expr
                            {
                                if($1.isFunc && $1.exprType != VEXPR){
                                    printf("Error %d: Not a valid expression! Standalone expression can only in form of procedure / (procedure) / expression \n", linenum);
                                    errorExist = 1;
                                }
                                if($1.exprType != VEXPR){
                                    ////////////WRITE CODE SECTION
                                    popExpression(&errorExist);
                                    //////////////////////////////
                                }
                                Trace("Reducing to LoopUniversalStatement 14 (Expr)\n");
                            }

/*Two form, whether they are decreasing or not
Here I assume since no increment/decrement distance, only INTCONST is valid*/
ForConstruct: FOR DecreaseOrNot IDENTIFIER COLON Expr DOT {
                /////////////////WRITE CODE SECTION
                forStatementUntilFirstExpression(&errorExist);
                ///////////////////////////////////
              } DOT Expr 
              {
                //need midrule to create new symbol table
                create(debugMode, 0);
                inALoopOrFor += 1;
                // continue operation by inserting the identifier in a new scope
                struct EntryAttributes toBeInputted = defaultEntryAttributesValue();
                toBeInputted.entryType = VAR_ENTTYPE;
                toBeInputted.declaredLine = linenum; 
                toBeInputted.varConstOrResType = INTEGER_TYPE;
                if($5.isError || $9.isError)
                {
                    //error in expression between dots
                    printf("Error %d: For expression between the dot has error expressions, nevertheless, still be to local symbol table to check for identifier duplicity\n", linenum);
                    errorExist = 1;
                }
                else if($5.exprType != IEXPR || $9.exprType != IEXPR){
                    //expression between dots is not integer, or may be integer array
                    printf("Error %d: For expression between the dot should be integer expressions, nevertheless, still be to local symbol table to check for identifier duplicity\n", linenum);
                    errorExist = 1;
                }else if (!($5.isConst) || !($9.isConst)){
                    //error in expression between dots is not const
                    printf("Error %d: For expression between the dot should be constant expressions, nevertheless, still be to local symbol table to check for identifier duplicity\n", linenum);
                    errorExist = 1;
                }else{
                    //First, before inputting the variable check correspondence of DecreaseOrNot with the two INTCONST between DOT DOT
                    if(($2 == 1 && $5.iVal >= $9.iVal) || ($2 == 0 && $5.iVal <= $9.iVal))
                    {
                        // valid
                        
                        //assume that the value is set as the number before ..
                        if(symbolTableStoreValue) toBeInputted.iVal = $5.iVal;
                    }
                    else{
                        printf("Error %d: ill defined For, not matching relation between decreasing and two number separated by .. , nevertheless, variable still be to local symbol table to check for identifier duplicity\n", linenum);
                        errorExist = 1;
                    }
                }
                //inserting the toBeInputted into the symbol table
                struct IdxPair entryPosition = insert($3.varName, debugMode);
                editAttributesOnIndex(entryPosition, toBeInputted, debugMode);
                /////////////////WRITE CODE SECTION
                //////////////WRITE CODE SECTION
                ///Modify local variable number if variable is declared local
                if(toBeInputted.entryType == VAR_ENTTYPE && identifierIsLocal(entryPosition)){
                    modifyLocalVariableNumber(entryPosition, debugMode);
                }
                forStatementBegin(&errorExist, entryPosition, $2);
                ///////////////////////////////////  
              }
              LoopAllStatements END FOR
              {
                Trace("Reducing to ForConstruct\n");
                /////////////////WRITE CODE SECTION
                struct IdxPair entryPosition = lookupIndexInLast($3.varName, debugMode);
                forStatementEnd(&errorExist, entryPosition, $2);
                ///////////////////////////////////  
                popBack(debugMode, 0);
                inALoopOrFor -= 1;
              }

DecreaseOrNot:  DECREASING
                {
                    Trace("Reducing to DecreaseOrNot 1 (From DECREASING)\n");
                    // true for being decreasing
                    $$ = 1;
                }
                | /*empty*/
                {
                    Trace("Reducing to DecreaseOrNot 2 (From Empty)\n");
                    // false for being not decreasing
                    $$ = 0;
                }

SkipStatement: SKIP
               { 
                   Trace("Reducing to SkipStatement\n");
                   /////////////////WRITE CODE SECTION
                   skipStatement(&errorExist);
                   ///////////////////////////////////  
               }

ExitStatement:  EXIT ExitCondition
                {
                    int functionOrGlobalExit = 0;
                    if(inALoopOrFor <= 0){
                        functionOrGlobalExit = 1;
                    }
                    Trace("Reducing to ExitStatement\n");
                    /////////////////WRITE CODE SECTION
                    //// for exit, we should know the context of the exit
                    exitStatement(&errorExist, functionOrGlobalExit, $2);
                    ///////////////////////////////////  
                }

/*Exit Condition can be empty also, this method is done to left factor ExitStatement*/
ExitCondition:  WHEN Expr
                {
                    Trace("Reducing to ExitCondition 1 (Non Empty Exit Condition)\n");

                    //Expr on the right should be boolean condition
                    struct expr resExpr = defaultExprValue();

                    // make sure that expr valid
                    if($2.isError == 0 ){
                        // only boolean expression is valid
                        if($2.exprType == BEXPR && !exprIsArray($2.exprType)) {
                            //valid
                        }else{
                            // not a valid type
                            printf("Error %d: Not a valid expr type, WHEN has invalid RHS Type, Expected boolean, get: ", linenum);
                            exprTypePrintingHelper($2.exprType, $2.arrLength);
                            printf("\n");
                            resExpr.isError = 1;
                            errorExist = 1;
                        }
                    }else{
                        // no need to continue, it is already an error
                        printf("Error %d: WHEN has error RHS expression\n", linenum);
                        errorExist = 1;
                    }
                    $$ = 0; //not unconditional exit
                }
                | /*empty*/
                {
                    // empty exit condition
                    Trace("Reducing to ExitCondition 2 (Empty Exit Condition)\n");
                    $$ = 1; //unconditional exit
                }

ReturnStatement:    RETURN
                    {
                        if(inAProcedure <= 0){
                            printf("Error %d: return isnt in any procedure, this will cause syntax error\n", linenum);
                            errorExist = 1;
                        }
                        Trace("Reducing to ReturnStatement\n");
                        ///////////////////WRITE CODE SECTION
                        resultReturnStatement(&errorExist, VOID_TYPE);
                        /////////////////////////////////////
                    }

ResultStatement:    RESULT Expr
                    {
                        if(inAFunction <= 0){
                            printf("Error %d: result isnt in any function, this will cause syntax error\n", linenum);
                            errorExist = 1;
                        }
                        Trace("Reducing to ResultStatement\n");
                        int isPut = 0; //0 for result, 1 for put
                        struct expr ExprSpec = $2;
                        int linenumber = linenum;
                        resultPutSteps(isPut, ExprSpec, linenumber);
                    }

PutStatement:   PUT {
                    Trace("Reducing to PutStatement MIDRULE!\n");
                    ////////////////////WRITE CODE SECTION
                    putStatementPreparation(&errorExist);
                    //////////////////////////////////////
                }Expr
                {
                    Trace("Reducing to PutStatement\n");
                    int isPut = 1; //0 for result, 1 for put
                    struct expr ExprSpec = $3;
                    int linenumber = linenum;
                    resultPutSteps(isPut, ExprSpec, linenumber);
                }
                ;

GetStatement:   GET IDENTIFIER
                {
                    // Identifier must be a variable type
                    Trace("Reducing to GetStatement 1 (Regular Identifier)\n");

                    int isGet = 1; //int isGet, set 0 if it is assignment, set 1 if it is a get
                    struct IdxPair identifierSpec = $2;//struct  IdxPos identifierSpec, the identifier information from lex where we want to get or assign
                    struct expr exprSpec = defaultExprValue(); //just temporary variable because it is not used
                    getAssignmentStepsIdentifier(isGet, identifierSpec, exprSpec);
                } 
                | GET IDENTIFIER OPENSQUAREBRACKET Expr CLOSINGSQUAREBRACKET
                {
                    Trace("Reducing to GetStatement 2 (Get Array)\n");
                    int isGet = 1;//int isGet, set 0 if it is assignment, set 1 if it is a get
                    struct IdxPair identifierSpec = $2;//struct IdxPair identifierSpec, the identifier information from lex where we want to get or assign
                    struct expr exprSpec = defaultExprValue();//struct expr exprSpec, if it is an assignmentStatement, then this is the right hand side of it
                    struct expr indexExprSpec = $4;//struct expr indexExpr: int expr for accessing array index
                    getAssignmentStepsIdentifierArray(isGet, identifierSpec, exprSpec, indexExprSpec);
                } 
                ;

/* Assignment without declaration, it means variable must be declared and Expr on RHS must be the same type*/
AssignmentStatement:    IDENTIFIER ASSIGNMENT Expr
                        {
                            Trace("Reducing to AssignmentStatement 1(Variable Assignment)\n");

                            //verify that the identifier is correct, because I found bug in my project 2 where if
                            // var s:int
                            // s := 10
                            // will produce bug due to s token evaluated earlier than the first rule, so revise identifier token just in case
                            struct IdxPair  res = lookupIndexFromLast($1.varName, debugMode);
                            if($1.symTableIdx != res.symTableIdx || $1.innerIdx != res.symTableIdx){
                                $1.symTableIdx = res.symTableIdx;
                                $1.innerIdx = res.innerIdx;
                            }


                            // Identifier should be a variable
                            // Identifier type and Expr Type should be the same

                            int isGet = 0; //int isGet, set 0 if it is assignment, set 1 if it is a get
                            struct IdxPair identifierSpec = $1;//struct  IdxPos identifierSpec, the identifier information from lex where we want to get or assign
                            struct expr exprSpec = $3; //just temporary variable because it is not used
                            getAssignmentStepsIdentifier(isGet, identifierSpec, exprSpec);
                        }
                        | IDENTIFIER OPENSQUAREBRACKET Expr CLOSINGSQUAREBRACKET ASSIGNMENT Expr
                        {

                            //verify that the identifier is correct, because I found bug in my project 2 where if
                            // var s:int
                            // s := 10
                            // will produce bug due to s token evaluated earlier than the first rule, so revise identifier token just in case
                            struct IdxPair  res = lookupIndexFromLast($1.varName, debugMode);
                            if($1.symTableIdx != res.symTableIdx || $1.innerIdx != res.symTableIdx){
                                $1.symTableIdx = res.symTableIdx;
                                $1.innerIdx = res.innerIdx;
                            }


                            Trace("Reducing to AssignmentStatement 2 (Array Assignment)\n");
                            int isGet = 0;//int isGet, set 0 if it is assignment, set 1 if it is a get
                            struct IdxPair identifierSpec = $1;//struct IdxPair identifierSpec, the identifier information from lex where we want to get or assign
                            struct expr exprSpec = $6;//struct expr exprSpec, if it is an assignmentStatement, then this is the right hand side of it
                            struct expr indexExprSpec = $3;//struct expr indexExpr: int expr for accessing array index
                            getAssignmentStepsIdentifierArray(isGet, identifierSpec, exprSpec, indexExprSpec);
                        }

/* Type definition, Can either REAL, INT, STRING or BOOL*/
Type:           REAL
                {
                    Trace("Reducing to Type 1 (Real)\n");
                    enum Type tmp= DOUBLE_TYPE;
                    $$ = tmp;
                }
                | INT
                {
                    Trace("Reducing to Type 2 (INT)\n");
                    enum Type tmp= INTEGER_TYPE;
                    $$ = tmp;
                }
                | STRING
                {
                    Trace("Reducing to Type 3 (STRING)\n");
                    enum Type tmp= STRING_TYPE;
                    $$ = tmp;
                }
                | BOOL
                {
                    Trace("Reducing to Type 4 (BOOL)\n");
                    enum Type tmp= BOOL_TYPE;
                    $$ = tmp;
                }
                ;

IdentifierConsts:   TRUE
                    {
                        Trace("Reducing to IdentifierConsts 1 (TRUE)\n");
                        struct expr res = defaultExprValue();
                        res.exprType = BEXPR;
                        res.boolVal = 1;
                        res.isConst = 1;
                        res.isError = 0;
                        res.arrLength = 1;
                        res.isFunc = 0;
                        ////////////////////WRITE CODE SECTION
                        loadConstantBoolean(&errorExist,1);
                        //////////////////////////////////////
                        $$ = res;
                    }
                    | FALSE
                    {
                        Trace("Reducing to IdentifierConsts 2 (FALSE)\n");
                        struct expr res = defaultExprValue();
                        res.exprType = BEXPR;
                        res.boolVal = 0;
                        res.isConst = 1;
                        res.isError = 0;
                        res.arrLength = 1;
                        res.isFunc = 0;
                        ////////////////////WRITE CODE SECTION
                        loadConstantBoolean(&errorExist,0);
                        //////////////////////////////////////
                        $$ = res;
                    }  
                    | INTCONST
                    {
                        Trace("Reducing to IdentifierConsts 3 (INTEGERCONST)\n");
                        struct expr res = defaultExprValue();
                        res.exprType = IEXPR;
                        res.iVal = $1;
                        res.isConst = 1;
                        res.isError = 0;
                        res.arrLength = 1;
                        res.isFunc = 0;
                        ////////////////////WRITE CODE SECTION
                        loadConstantInteger(&errorExist,$1);
                        //////////////////////////////////////
                        $$ = res;
                    }
                    | REALCONST
                    {
                        Trace("Reducing to IdentifierConsts 4 (REALCONST)\n");
                        struct expr res = defaultExprValue();
                        res.exprType = DEXPR;
                        res.dVal = $1;
                        res.isConst = 1;
                        res.isError = 0;
                        res.arrLength = 1;
                        res.isFunc = 0;
                        ////////////////////WRITE CODE SECTION
                        encounterUnableToExpress(&errorExist, "Float literal", linenum);
                        //////////////////////////////////////
                        $$ = res;
                    }
                    | STRINGCONST
                    {
                        Trace("Reducing to IdentifierConsts 5 (STRINGCONST)\n");
                        struct expr res = defaultExprValue();
                        res.exprType = SEXPR;
                        strcpy(res.sVal, $1);
                        res.isConst = 1;
                        res.isError = 0;
                        res.arrLength = 1;
                        res.isFunc = 0;
                        ////////////////////WRITE CODE SECTION
                        loadConstantString(&errorExist, $1);
                        //////////////////////////////////////
                        $$ = res;
                    }
                    | IDENTIFIER RightOfIdentifier
                    {
                        Trace("Reducing to IdentifierConsts 6 (Identifiers with different types): ");
                        struct expr res = defaultExprValue();
                        res.isConst = 0;
                        res.arrLength = 1;
                        res.isFunc = 0;
                        // Check in this scope whether identifier already exist
                        // in this case, identifier is used for expression, so identifier should already be initialized
                        if(identifierNotExistInAllScopeChecker($1)){
                            printf("Error %d: Invalid identifier %s, undeclared in this scope\n", linenum, $1.varName);
                            res.isError = 1;
                            Trace("\n");
                            errorExist = 1;
                        }else{
                            if($2.rightHandSideSpec == IS_EMPTY){
                                Trace("Regular Variable\n");
                                //Can either variables, or const, or array
                                // at this point it is found in symbol table
                                struct EntryAttributes varAttributes = fromIdxPairReturnAttributes($1, debugMode);
                                // based on type, differentiate the operation
                                if(varAttributes.entryType == VAR_ENTTYPE){
                                    // needs to check whether this var is assigned or not
                                    // For now no need to check whether value is assigned
                                    // type check
                                    if(varAttributes.varConstOrResType == INTEGER_TYPE){
                                        res.exprType = IEXPR;
                                        if(symbolTableStoreValue){
                                            res.iVal = varAttributes.iVal;
                                        }else{
                                            //Can't set value due to fear of fault value
                                        }
                                        ////////////////////WRITE CODE SECTION
                                        if(identifierIsGlobal($1)){
                                            loadGlobalVarInt(&errorExist, $1);
                                        }else{
                                            loadLocalVariableInteger(&errorExist, $1);
                                        }
                                        //////////////////////////////////////
                                        res.isError = 0;
                                    }else if(varAttributes.varConstOrResType == DOUBLE_TYPE){
                                        res.exprType = DEXPR;
                                        if(symbolTableStoreValue){
                                            res.dVal = varAttributes.dVal;
                                        }else{
                                            //Can't set value due to fear of fault value
                                        }
                                        ////////////////////WRITE CODE SECTION
                                        encounterUnableToExpress(&errorExist, "Double variable loading", linenum);
                                        //////////////////////////////////////
                                        res.isError = 0;
                                    }else if(varAttributes.varConstOrResType == STRING_TYPE){
                                        res.exprType = SEXPR;
                                        if(symbolTableStoreValue){
                                            strcpy(res.sVal, varAttributes.sVal);
                                        }else{
                                            //Can't set value due to fear of fault value
                                        }
                                        res.isError = 0;
                                        ////////////////////WRITE CODE SECTION
                                        encounterUnableToExpress(&errorExist, "String variable loading", linenum);
                                        //////////////////////////////////////
                                    }else if(varAttributes.varConstOrResType == BOOL_TYPE){
                                        res.exprType = BEXPR;
                                        if(symbolTableStoreValue){
                                            res.boolVal = varAttributes.boolVal;
                                        }else{
                                            //Can't set value due to fear of fault value
                                        }
                                        ////////////////////WRITE CODE SECTION
                                        if(identifierIsGlobal($1)){
                                            loadGlobalVarBoolean(&errorExist, $1);
                                        }else{
                                            loadLocalVariableBoolean(&errorExist, $1);
                                        }
                                        //////////////////////////////////////
                                        res.isError = 0;
                                    }else{
                                        printf("Error %d: Invalid identifier type for variable %s : ", linenum, $1.varName);
                                        typePrintingHelperInC(varAttributes.varConstOrResType);
                                        printf("\n");
                                        res.isError = 1;
                                        errorExist = 1;
                                    }
                                }else if(varAttributes.entryType == CONST_ENTTYPE){
                                    // No need to check whether it is assigned or not, because it must have been assigned at this point
                                    res.isConst = 1; // notice that this is counted as a constant, so any expr regarding this entry will still be counted as const expression
                                    if(varAttributes.varConstOrResType == INTEGER_TYPE){
                                        res.exprType = IEXPR;
                                        res.iVal = varAttributes.iVal;
                                        res.isError = 0;
                                        ////////////////////WRITE CODE SECTION
                                        loadConstantInteger(&errorExist, res.iVal);
                                        //////////////////////////////////////
                                    }else if(varAttributes.varConstOrResType == DOUBLE_TYPE){
                                        res.exprType = DEXPR;
                                        res.dVal = varAttributes.dVal;
                                        res.isError = 0;
                                        ////////////////////WRITE CODE SECTION
                                        encounterUnableToExpress(&errorExist, "Float constant variable", linenum);
                                        //////////////////////////////////////
                                    }else if(varAttributes.varConstOrResType == STRING_TYPE){
                                        res.exprType = SEXPR;
                                        strcpy(res.sVal, varAttributes.sVal);
                                        res.isError = 0;
                                        ////////////////////WRITE CODE SECTION
                                        loadConstantString(&errorExist, res.sVal);
                                        //////////////////////////////////////
                                    }else if(varAttributes.varConstOrResType == BOOL_TYPE){
                                        res.exprType = BEXPR;
                                        res.boolVal = varAttributes.boolVal;
                                        res.isError = 0;
                                        ////////////////////WRITE CODE SECTION
                                        loadConstantBoolean(&errorExist, res.boolVal);
                                        //////////////////////////////////////
                                    }else{
                                        printf("Error %d: Invalid identifier type for constant %s : ", linenum, $1.varName);
                                        errorExist = 1;
                                        typePrintingHelperInC(varAttributes.varConstOrResType);
                                        printf("\n");
                                        res.isError = 1;
                                    }
                                }else if(varAttributes.entryType == FUNCTION_ENTTYPE){
                                    // Need to check whether the length of the params is 0
                                    char errorMessageHelper[256] = "function";
                                    if(varAttributes.varConstOrResType == VOID_TYPE){
                                        strcpy(errorMessageHelper, "procedure");
                                    }
                                    printf("Error %d: Invalid calling %s %s, needs to append () even if empty without parameter", linenum, errorMessageHelper, $1.varName);
                                    errorExist = 1;
                                    printf("\n");
                                    res.isError = 1;
                                }else if(varAttributes.entryType == ARRAY_ENTTYPE){
                                    // might be valid, return array as a whole, just in case passed to function params
                                    res.arrLength = varAttributes.endIndices - varAttributes.startIndices + 1;
                                    res.isError = 0; // it might not be error (e.g. passing array to function parameter)
                                    ////////////////////WRITE CODE SECTION
                                    encounterUnableToExpress(&errorExist, "Array variable on RHS", linenum);
                                    //////////////////////////////////////
                                    if(varAttributes.varConstOrResType == INTEGER_TYPE){
                                        res.exprType = IARREXPR;
                                        res.isError = 0;
                                    }else if(varAttributes.varConstOrResType == DOUBLE_TYPE){
                                        res.exprType = DARREXPR;
                                        res.isError = 0;
                                    }else if(varAttributes.varConstOrResType == BOOL_TYPE){
                                        res.exprType = BARREXPR;
                                        res.isError = 0;
                                    }else{
                                        printf("Error %d: Invalid identifier type for array expr %s : ", linenum, $1.varName);
                                        errorExist = 1;
                                        typePrintingHelperInC(varAttributes.varConstOrResType);
                                        printf("\n");
                                        res.isError = 1;
                                    }
                                }else{
                                    printf("SelfError %d: Something wrong with the parser, IdentifierConst should not enter here \n", linenum);
                                    errorExist = 1;
                                    typePrintingHelperInC(varAttributes.varConstOrResType);
                                    printf("\n");
                                    res.isError = 1;
                                }
                            }else if($2.rightHandSideSpec == IS_FUNCTION_CALL){
                                Trace("Function Call\n");
                                //must be function
                                // at this point it is found in symbol table
                                struct EntryAttributes varAttributes = fromIdxPairReturnAttributes($1, debugMode);
                                
                                // only function type is valid
                                if(varAttributes.entryType == VAR_ENTTYPE){
                                    printf("Error %d: Invalid identifier %s, It is a variable, not a function/procedure\n", linenum, $1.varName);
                                    res.isError = 1;
                                    errorExist = 1;
                                }else if(varAttributes.entryType == CONST_ENTTYPE){
                                    printf("Error %d: Invalid identifier %s, It is a const, not a function/procedure\n", linenum, $1.varName);
                                    res.isError = 1;
                                    errorExist = 1;
                                }else if(varAttributes.entryType == FUNCTION_ENTTYPE){
                                    // Need to check whether the length of the params is 0
                                    res.isFunc = 1;
                                    struct ArgAccumulation argumentCheck = $2.argAcc;
                                    char errorMessageHelper[256] = "function";
                                    if(varAttributes.varConstOrResType == VOID_TYPE){
                                        strcpy(errorMessageHelper, "procedure");
                                    }

                                    if(argumentCheck.isEncounterError){
                                        //one of the expression for function parameters is invalid
                                        //dont worry about dynamic array, they have been deallocated
                                        printf("Error %d: Invalid calling %s %s, there is error when specifying the argument\n", linenum, errorMessageHelper, $1.varName);
                                        res.isError = 1;
                                        errorExist = 1;
                                    }else if(varAttributes.paramsLength != argumentCheck.paramsLength){
                                        printf("Error %d: Invalid calling %s %s, parameter and argument amount not the same, ", linenum, errorMessageHelper, $1.varName);
                                        printf("expect amount: %i, get amount: %i", varAttributes.paramsLength, argumentCheck.paramsLength);
                                        printf("\n");
                                        res.isError = 1;
                                        errorExist = 1;
                                    }else{
                                        //check the argument mapping whether they are correct
                                        int paramsTypeCorrect = 1;
                                        for(int idx = 0; idx < varAttributes.paramsLength; idx++){
                                            //argument input correct with parameter?
                                            if(varAttributes.paramsOrdering[idx] != argumentCheck.paramsOrdering[idx] || varAttributes.eachParamsHowManyElements[idx] != argumentCheck.eachParamsHowManyElements[idx]){
                                                paramsTypeCorrect = 0;
                                                printf("Error %d: %i-th parameter of %s %s has incompatible type, expect: ", linenum, idx+1, errorMessageHelper, $1.varName);
                                                paramsTypePrintingHelperInC(varAttributes.paramsOrdering[idx], varAttributes.eachParamsHowManyElements[idx]);
                                                printf(", get: ");
                                                paramsTypePrintingHelperInC(argumentCheck.paramsOrdering[idx], argumentCheck.eachParamsHowManyElements[idx]);
                                                printf("\n");
                                                errorExist = 1;
                                            }
                                        }

                                        if(paramsTypeCorrect){
                                            // parameter is valid
                                            // right now since we don't know  yet how to operate a function, anything that has function will have value unevaluated
                                            res.isConst = 0;
                                            res.isError = 0;
                                            if(varAttributes.varConstOrResType == INTEGER_TYPE){
                                                res.exprType = IEXPR;
                                            }else if(varAttributes.varConstOrResType == DOUBLE_TYPE){
                                                res.exprType = DEXPR;
                                            }else if(varAttributes.varConstOrResType == STRING_TYPE){
                                                res.exprType = SEXPR;
                                            }else if(varAttributes.varConstOrResType == BOOL_TYPE){
                                                res.exprType = BEXPR;
                                            }else if(varAttributes.varConstOrResType == VOID_TYPE){
                                                res.exprType = VEXPR;
                                            }else{
                                                printf("Error %d: Should not enter here: Invalid identifier type for %s %s : ", linenum, errorMessageHelper, $1.varName);
                                                typePrintingHelperInC(varAttributes.varConstOrResType);
                                                printf("\n");
                                                res.isError = 1;
                                                errorExist = 1;
                                            }
                                            ////////////////////WRITE CODE SECTION
                                            callFunction(&errorExist, $1, argumentCheck);
                                            //////////////////////////////////////
                                        }else{
                                            // wrong parameter type, so expression is an error
                                            res.isError = 1;
                                        }

                                        
                                        //deallocate dynamic memory when we are done using the argumentCheck
                                        if(argumentCheck.paramsLength > 0){
                                            free(argumentCheck.paramsOrdering);
                                            free(argumentCheck.eachParamsHowManyElements);
                                        }
                                    }
                                }else if(varAttributes.entryType == ARRAY_ENTTYPE){
                                    printf("Error %d: Invalid identifier %s, It is an array, not a function/procedure\n", linenum, $1.varName);
                                    res.isError = 1;
                                    errorExist = 1;
                                }else{
                                    printf("Error %d: Something wrong with the parser, IdentifierConst should not enter here \n", linenum);
                                    typePrintingHelperInC(varAttributes.varConstOrResType);
                                    printf("\n");
                                    res.isError = 1;
                                    errorExist = 1;
                                }
                            }else if($2.rightHandSideSpec == IS_ARRAY_CALL){
                                Trace("Array Call\n");
                                //must be array call
                                struct EntryAttributes varAttributes = fromIdxPairReturnAttributes($1, debugMode);
                                
                                // only function type is valid
                                if(varAttributes.entryType == VAR_ENTTYPE){
                                    printf("Error %d: Invalid identifier %s, It is a variable, not an array\n", linenum, $1.varName);
                                    res.isError = 1;
                                    errorExist = 1;
                                }else if(varAttributes.entryType == CONST_ENTTYPE){
                                    printf("Error %d: Invalid identifier %s, It is a const, not an array\n", linenum, $1.varName);
                                    res.isError = 1;
                                    errorExist = 1;
                                }else if(varAttributes.entryType == FUNCTION_ENTTYPE){
                                    // Need to check whether the length of the params is 0
                                    char errorMessageHelper[256] = "function";
                                    if(varAttributes.varConstOrResType == VOID_TYPE){
                                        strcpy(errorMessageHelper, "procedure");
                                    }
                                    printf("Error %d: Invalid identifier %s, it is a %s, not an array\n", linenum, $1.varName, errorMessageHelper);
                                    res.isError = 1;
                                    errorExist = 1;
                                }else if(varAttributes.entryType == ARRAY_ENTTYPE){
                                    //check for the validity of the function
                                    //type check whether it is an integer expr or not is done in the ArrayCallBrackets
                                    struct expr IndexExprSpec = $2.arrayRHSIntExpr; //check the argument provided by the program
                                    ////////////////////WRITE CODE SECTION
                                    encounterUnableToExpress(&errorExist, "Array RHS", linenum);
                                    //////////////////////////////////////
                                    if(IndexExprSpec.isError == 0 && !exprIsArray(IndexExprSpec.exprType) && IndexExprSpec.exprType == IEXPR){
                                        int indexValid = 1;
                                        int indexCanBeExtracted = (IndexExprSpec.isConst);
                                        //can only check index validity if the expression value can be counted
                                        if(constIntExprCanCheckIndexValidity && indexCanBeExtracted)
                                        {
                                            if(!arrayIndexValidityChecker(varAttributes, IndexExprSpec.iVal)){
                                                indexValid = 0;
                                                printf("Error %d: Expr Access Array Element %s, index value %i is invalid with index %i to %i\n", linenum, $1.varName, IndexExprSpec.iVal, varAttributes.startIndices, varAttributes.endIndices);
                                                errorExist = 1;
                                            }
                                        }


                                        //only do if all these categories are fulfilled
                                        if(indexValid){
                                            res.isError = 0;
                                            res.isConst = 0;
                                                                                     
                                            if(varAttributes.varConstOrResType == INTEGER_TYPE){
                                                //assignment value to the function
                                                res.exprType = IEXPR;
                                            }else if(varAttributes.varConstOrResType == DOUBLE_TYPE){
                                                res.exprType = DEXPR;
                                            }else if(varAttributes.varConstOrResType == STRING_TYPE){
                                                printf("Error %d: Array assignment type error, %s is an array, type of string is invalid\n", linenum, $1.varName);
                                                res.isError = 1;
                                                errorExist = 1;
                                            }else if(varAttributes.varConstOrResType == BOOL_TYPE){
                                                res.exprType = BEXPR;
                                            }else{
                                                // should not enter here, if it does then it is my error
                                                printf("SelfError %d: Expr Array access failed: Invalid identifier type for array %s", linenum, $1.varName);
                                                typePrintingHelperInC(varAttributes.varConstOrResType);
                                                printf("\n");
                                                errorExist = 1;
                                            }
                                        }else{
                                            //index invalid
                                            printf("Error %d: Array %s access expression invalid index\n", linenum, $1.varName);
                                            res.isError = 1;
                                            errorExist = 1;
                                            
                                        }
                                    }else{
                                        if(IndexExprSpec.isError){
                                            printf("Error %d: Array Element Expr Access %s failed, index expression is an error\n", linenum, $1.varName);
                                            errorExist = 1;
                                        }else if(exprIsArray(IndexExprSpec.exprType)){
                                            printf("Error %d: Array Element Expr Access %s failed, index expression is an array\n", linenum, $1.varName);
                                            errorExist = 1;
                                        }else if(IndexExprSpec.exprType != INTEGER_TYPE){
                                            printf("Error %d: Array Element Expr Access %s failed, only integer index is valid for array index\n", linenum, $1.varName);
                                            errorExist = 1;
                                        }
                                        res.isError = 1;
                                    }
                                }else{
                                    printf("SelfError %d: Something wrong with the parser, IdentifierConst should not enter here \n", linenum);
                                    typePrintingHelperInC(varAttributes.varConstOrResType);
                                    printf("\n");
                                    res.isError = 1;
                                    errorExist = 1;
                                }
                            }else{
                                //should not enter here, if enter here then it is programmer's mistake
                                printf("SelfError %d: Don't know right hand side of identifier type\n", linenum);
                                res.isError = 1;
                                errorExist = 1;
                            }
                        }
                        $$ = res;
                    }
                    ;

RightOfIdentifier:  /*empty*/
                    {
                        Trace("Reducing to RightOfIdentifier 1 (Empty)\n");
                        struct RightOfIdentifierInformation res = defaultRightOfIdentifierInformationValue();
                        res.rightHandSideSpec = IS_EMPTY;
                        $$ = res;
                    }| FunctionCallBrackets{
                        Trace("Reducing to RightOfIdentifier 2 (FunctionCallBrackets)\n");
                        struct RightOfIdentifierInformation res = defaultRightOfIdentifierInformationValue();
                        res.rightHandSideSpec = IS_FUNCTION_CALL;
                        res.argAcc = $1;
                        $$ = res;
                    }| ArrayCallBrackets{
                        Trace("Reducing to RightOfIdentifier 3 (ArrayCallBrackets)\n");
                        struct RightOfIdentifierInformation res = defaultRightOfIdentifierInformationValue();
                        res.rightHandSideSpec = IS_ARRAY_CALL;
                        res.arrayRHSIntExpr = $1;
                        $$ = res;
                    }

FunctionCallBrackets:   OPENPARENTHESES FunctionParameters CLOSINGPARENTHESES
                        {
                            Trace("Reducing to FunctionCallBrackets\n");

                            // no type checking, just directly pass to the RightOfIdentifier
                            $$ = $2;
                        }


ArrayCallBrackets:  OPENSQUAREBRACKET Expr CLOSINGSQUAREBRACKET
                    {
                        Trace("Reducing to ArrayCallBrackets\n");

                        // should be an integer and not an array
                        struct expr resExpr = $2;
                        if(!resExpr.isError){
                            if(exprIsArray(resExpr.exprType)){
                                resExpr.isError = 1;
                                printf("Error %d: Index to access array is error, because it is an array\n", linenum);
                                errorExist = 1;
                            }
                            if(resExpr.exprType != IEXPR){
                                resExpr.isError = 1;
                                printf("Error %d: Index to access array is error, because it is not an integer expression, instead: ", linenum);
                                exprTypePrintingHelper(resExpr.exprType, resExpr.arrLength);
                                printf("\n");
                                errorExist = 1;
                            }
                        }
                        $$ = resExpr;
                    }

FunctionParameters: /*empty*/
                    {
                        Trace("Reducing to FunctionParameters 1 (Empty Params)\n");
                        //return empty Function 
                        struct ArgAccumulation resultArgument = defaultArgAccumulationValue();
                        $$ = resultArgument;
                    }
                    | FunctionParametersFollowUp Expr 
                    {
                        Trace("Reducing to FunctionParameters 2 (Expr Params followed by FunctionParametersFollowUp)\n");
                        // differentiate function based on whether Expr is an array or not, because I use different function
                        struct ArgAccumulation resultArgument = defaultArgAccumulationValue();
                        if(exprIsArray($2.exprType)){
                            //is an array
                            int isDeclaration = 0; //isDeclaration: 1 if this is a declaration, 0 if it is part of a function call
                            struct IdxPair identifierPos = defaultIdxPairValue(); //identifierPos: Identifier specification for declaration, not used if it is a function call
                            enum Type varType = translatorExprType($2.exprType); //varType: type of identifier that is going to use for declaration / function or procedure call
                            //because when passing to a function, we only care same type of array to be array with same length, we can put anything for the start and end indices, as long as length is the same
                            int startIndices = 0; //startIndices: start index of the array
                            int endIndices = $2.arrLength -1; //endIndices: end index of the array
                            struct ArgAccumulation followUpArguments = $1; //followUpArguments, the list of arguments that come after it (because argument is in left recursion)
                            int linenumber = linenum; //current line number
                            int callExprIsError = $2.isError; //whether expression used for parameters is error
                            resultArgument = functionArrayArgumentChecker(isDeclaration, identifierPos, varType, startIndices, endIndices, followUpArguments, linenumber, callExprIsError);
                        }else{
                            // not an array
                            int isDeclaration = 0; //isDeclaration: 1 if this is a declaration, 0 if it is part of a function call
                            struct IdxPair identifierPos = defaultIdxPairValue(); //identifierPos: Identifier specification for declaration, not used if it is a function call
                            enum Type varType = translatorExprType($2.exprType); //varType: type of identifier that is going to use for declaration
                            struct ArgAccumulation followUpArguments = $1;//followUpArguments, the list of arguments that come after it (because argument is in left recursion)
                            int linenumber = linenum; //current line number
                            int callExprIsError = $2.isError; //whether expression used for parameters is error
                            resultArgument = functionVarArgumentChecker(isDeclaration, identifierPos, varType, followUpArguments, linenumber, callExprIsError);
                        }
                        $$ = resultArgument;
                    }

FunctionParametersFollowUp: /*empty*/
                            {
                                Trace("Reducing to FunctionParametersFollowUp 1 (Empty Follow Up)\n");
                                struct ArgAccumulation resultArgument = defaultArgAccumulationValue();
                                $$ = resultArgument;
                            }
                            | FunctionParametersFollowUp Expr COMMA
                            {
                                Trace("Reducing to FunctionParametersFollowUp 2 (Follow Up Expr)\n");
                                struct ArgAccumulation resultArgument = defaultArgAccumulationValue();
                                if(exprIsArray($2.exprType)){
                                    //is an array
                                    int isDeclaration = 0; //isDeclaration: 1 if this is a declaration, 0 if it is part of a function call
                                    struct IdxPair identifierPos = defaultIdxPairValue(); //identifierPos: Identifier specification for declaration, not used if it is a function call
                                    enum Type varType = translatorExprType($2.exprType); //varType: type of identifier that is going to use for declaration / function or procedure call
                                    //because when passing to a function, we only care same type of array to be array with same length, we can put anything for the start and end indices, as long as length is the same
                                    int startIndices = 0; //startIndices: start index of the array
                                    int endIndices = $2.arrLength -1; //endIndices: end index of the array
                                    struct ArgAccumulation followUpArguments = $1; //followUpArguments, the list of arguments that come after it (because argument is in left recursion)
                                    int linenumber = linenum; //current line number
                                    int callExprIsError = $2.isError; //whether expression used for parameters is error
                                    resultArgument = functionArrayArgumentChecker(isDeclaration, identifierPos, varType, startIndices, endIndices, followUpArguments, linenumber, callExprIsError);
                                }else{
                                    // not an array
                                    int isDeclaration = 0; //isDeclaration: 1 if this is a declaration, 0 if it is part of a function call
                                    struct IdxPair identifierPos = defaultIdxPairValue(); //identifierPos: Identifier specification for declaration, not used if it is a function call
                                    enum Type varType = translatorExprType($2.exprType); //varType: type of identifier that is going to use for declaration
                                    struct ArgAccumulation followUpArguments = $1;//followUpArguments, the list of arguments that come after it (because argument is in left recursion)
                                    int linenumber = linenum; //current line number
                                    int callExprIsError = $2.isError; //whether expression used for parameters is error
                                    resultArgument = functionVarArgumentChecker(isDeclaration, identifierPos, varType, followUpArguments, linenumber, callExprIsError);
                                }
                                $$ = resultArgument;
                            }
                            
Expr:           OPENPARENTHESES Expr CLOSINGPARENTHESES
                {
                    Trace("Reducing to Expr 1 (PARENTHESES)\n");
                    struct expr resExpr = ParenthesesUnaryMinExpr($2, "PARENTHESES");
                    resExpr.isFunc = $2.isFunc;
                    $$ = resExpr;
                }
                | SUBTRACTION Expr %prec UMINUS
                {
                    Trace("Reducing to Expr 2 (UMINUS)\n");
                    struct expr resExpr = ParenthesesUnaryMinExpr($2, "UMINUS");
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | Expr ADDITION Expr
                {
                    Trace("Reducing to Expr 3 (ADDITION)\n");
                    // only numerical expression is valid
                    struct expr resExpr = MathematicalOperation($1, "ADDITION", $3);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | Expr SUBTRACTION Expr
                {
                    Trace("Reducing to Expr 4 (SUBTRACTION)\n");
                    // only numerical expression is valid
                    struct expr resExpr = MathematicalOperation($1, "SUBTRACTION", $3);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | Expr MULTIPLICATION Expr 
                {
                    Trace("Reducing to Expr 5 (MULTIPLICATION)\n");
                    // only numerical expression is valid
                    struct expr resExpr = MathematicalOperation($1, "MULTIPLICATION", $3);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | Expr DIVISION Expr
                {
                    Trace("Reducing to Expr 6 (DIVISION)\n");
                    // only numerical expression is valid
                    struct expr resExpr = MathematicalOperation($1, "DIVISION", $3);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | Expr REMAINDER Expr
                {
                    Trace("Reducing to Expr 7 (REMAINDER)\n");
                    // only int expression is valid
                    struct expr resExpr = MathematicalOperation($1, "REMAINDER", $3);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | LOGICALNOT Expr
                {
                    Trace("Reducing to Expr 8 (LOGICALNOT)\n");
                    // Expr should be a boolean, result is also a boolean
                    struct expr tempLHS = defaultExprValue();
                    struct expr resExpr = LogicalAndOrNotOperation(tempLHS, "not", $2);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | Expr LOGICALAND Expr
                {
                    Trace("Reducing to Expr 9 (LOGICALAND)\n");
                    // Both Expr should be a boolean, result is also a boolean
                    struct expr resExpr = LogicalAndOrNotOperation($1, "and", $3);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | Expr LOGICALOR Expr
                {
                    Trace("Reducing to Expr 10 (LOGICALOR)\n");
                    // Both Expr should be a boolean, result is also a boolean
                    struct expr resExpr = LogicalAndOrNotOperation($1, "or", $3);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | Expr RELATIONALEQ Expr
                {
                    Trace("Reducing to Expr 11 (RELATIONALEQ)\n");
                    // valid combination
                    // numerical with numerical (int or double)
                    // string with string
                    // bool with bool
                    // resulting a boolean
                    struct expr resExpr = relationalStatementChecker($1, "=",$3);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | Expr RELATIONALNOT Expr
                {
                    Trace("Reducing to Expr 12 (RELATIONALNOT)\n");
                    // valid combination
                    // numerical with numerical (int or double)
                    // string with string
                    // bool with bool
                    // resulting a boolean
                    struct expr resExpr = relationalStatementChecker($1, "not=",$3);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | Expr RELATIONALGE Expr
                {
                    Trace("Reducing to Expr 13 (RELATIONALGE)\n");
                    // valid combination
                    // numerical with numerical (int or double)
                    // string with string
                    // resulting a boolean
                    struct expr resExpr = relationalStatementChecker($1, ">=",$3);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | Expr RELATIONALGT Expr
                {
                    Trace("Reducing to Expr 14 (RELATIONALGT)\n");
                    // valid combination
                    // numerical with numerical (int or double)
                    // string with string
                    // resulting a boolean
                    struct expr resExpr = relationalStatementChecker($1, ">",$3);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | Expr RELATIONALLE Expr
                {
                    Trace("Reducing to Expr 15 (RELATIONALLE)\n");
                    // valid combination
                    // numerical with numerical (int or double)
                    // string with string
                    // resulting a boolean
                    struct expr resExpr = relationalStatementChecker($1, "<=",$3);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | Expr RELATIONALLT Expr
                {
                    Trace("Reducing to Expr 16 (RELATIONALLT)\n");
                    // valid combination
                    // numerical with numerical (int or double)
                    // string with string
                    // resulting a boolean
                    struct expr resExpr = relationalStatementChecker($1, "<",$3);
                    resExpr.isFunc = 0;
                    $$ = resExpr;
                }
                | IdentifierConsts
                {
                    Trace("Reducing to Expr 17 (IdentifierConst)\n");
                    $$ = $1;
                }
                ;
/* Declarations */
/* Const Declaration can be type less or not*/
ConstDeclConstruct: CONST IDENTIFIER {
                        /////////////WRITE CODE SECTION
                        //global variable declaration
                        setCurrentlyInGlobalDeclare(1);
                        ///////////////////////////////
                    }COLON Type ASSIGNMENT Expr
                    {
                        // complete declaration
                        Trace("Reducing to ConstDeclConstruct 1 (Complete)\n");
                        int isValueless = 0; //going to assign value or not
                        int isTypeless = 0; //is the declaration typeless?
                        int isConst = 1; //is it a const?
                        struct IdxPair identifierSpec = $2; //symbol table info pass from lex
                        enum Type typeSpec = $5; //if not typeless, send the type specification
                        struct expr exprSpec = $7; //if not valueless, send the expression specification
                        int linenumber = linenum; //declared line number
                        /////////////WRITE CODE SECTION
                        //global variable declaration off
                        setCurrentlyInGlobalDeclare(0);
                        ///////////////////////////////
                        VariableDeclarationSteps(isValueless, isTypeless, isConst, identifierSpec, typeSpec, exprSpec, linenumber);

                    }
                    | CONST IDENTIFIER {
                        /////////////WRITE CODE SECTION
                        //global variable declaration
                        setCurrentlyInGlobalDeclare(1);
                        ///////////////////////////////
                    }ASSIGNMENT Expr
                    {
                        // typeless declaration
                        Trace("Reducing to ConstDeclConstruct 2 (Typeless)\n");
                        int isValueless = 0; //going to assign value or not
                        int isTypeless = 1; //is the declaration typeless?
                        int isConst = 1; //is it a const?
                        struct IdxPair identifierSpec = $2; //symbol table info pass from lex
                        enum Type typeSpec = defaultTypeValue(); //if not typeless, send the type specification
                        struct expr exprSpec = $5; //if not valueless, send the expression specification
                        int linenumber = linenum; //declared line number
                        /////////////WRITE CODE SECTION
                        //global variable declaration off
                        setCurrentlyInGlobalDeclare(0);
                        ///////////////////////////////
                        VariableDeclarationSteps(isValueless, isTypeless, isConst, identifierSpec, typeSpec, exprSpec, linenumber);
                    }
                    ;

/* Variable Declaration can be type less (as long as there is expr) or assignment less as long as there is type
Also, array is part of VarDeclConstruct*/
VarDeclConstruct:   VAR IDENTIFIER COLON Type ASSIGNMENT {
                       if(symbolTableScopeSize(debugMode) == 1){
                            /////////////WRITE CODE SECTION
                            //global variable declaration
                            setCurrentlyInGlobalDeclare(1);
                            ///////////////////////////////
                       }
                    }Expr
                    {
                        // complete declaration
                        Trace("Reducing to VarDeclConstruct 1 (Complete)\n");
                        int isValueless = 0; //going to assign value or not
                        int isTypeless = 0; //is the declaration typeless?
                        int isConst = 0; //is it a const?
                        struct IdxPair identifierSpec = $2; //symbol table info pass from lex
                        enum Type typeSpec = $4; //if not typeless, send the type specification
                        struct expr exprSpec = $7; //if not valueless, send the expression specification
                        int linenumber = linenum; //declared line number
                        /////////////WRITE CODE SECTION
                        //global variable declaration off
                        setCurrentlyInGlobalDeclare(0);
                        ///////////////////////////////
                        VariableDeclarationSteps(isValueless, isTypeless, isConst, identifierSpec, typeSpec, exprSpec, linenumber);
                    }
                    | VAR IDENTIFIER ASSIGNMENT {
                        if(symbolTableScopeSize(debugMode) == 1){
                            /////////////WRITE CODE SECTION
                            //global variable declaration
                            setCurrentlyInGlobalDeclare(1);
                            ///////////////////////////////
                       }
                    }Expr
                    {
                        // typeless declaration
                        Trace("Reducing to VarDeclConstruct 2 (Typeless)\n");
                        int isValueless = 0; //going to assign value or not
                        int isTypeless = 1; //is the declaration typeless?
                        int isConst = 0; //is it a const?
                        struct IdxPair identifierSpec = $2; //symbol table info pass from lex
                        enum Type typeSpec = defaultTypeValue(); //if not typeless, send the type specification
                        struct expr exprSpec = $5; //if not valueless, send the expression specification
                        int linenumber = linenum; //declared line number
                        /////////////WRITE CODE SECTION
                        //global variable declaration off
                        setCurrentlyInGlobalDeclare(0);
                        ///////////////////////////////
                        VariableDeclarationSteps(isValueless, isTypeless, isConst, identifierSpec, typeSpec, exprSpec, linenumber);

                        //turn off global var declaration
                    }
                    | VAR IDENTIFIER COLON Type
                    {
                        // asignment less declaration
                        Trace("Reducing to VarDeclConstruct 3 (Valueless)\n");
                        int isValueless = 1; //going to assign value or not
                        int isTypeless = 0; //is the declaration typeless?
                        int isConst = 0; //is it a const?
                        struct IdxPair identifierSpec = $2; //symbol table info pass from lex
                        enum Type typeSpec = $4; //if not typeless, send the type specification
                        struct expr exprSpec = defaultExprValue(); //if not valueless, send the expression specification
                        int linenumber = linenum; //declared line number
                        VariableDeclarationSteps(isValueless, isTypeless, isConst, identifierSpec, typeSpec, exprSpec, linenumber);
                    }
                    ;

/* Construct to declare array, no assignment allowed*/
ArrayDeclConstruct: VAR IDENTIFIER COLON ARRAY INTCONST DOT DOT INTCONST OF Type
                    {
                        /////////////WRITE CODE SECTION
                        encounterUnableToExpress(&errorExist, "Array Declare Construct", linenum);
                        ///////////////////////////////
                        // index enumeration should be int and more than 0, left index should be less than right index
                        // type can only bool, int , double
                        Trace("Reducing to ArrayDeclConstruct\n");
                        // see whether same name is already declared inside the symbol table
                        struct IdxPair symTableLocation = $2;
                        if(identifierNotExistInThisScopeChecker(symTableLocation)){
                            // variable not found, valid
                            struct EntryAttributes toBeInputted = defaultEntryAttributesValue();
                            // check the start and ending indices, where start index should be <= end index
                            if($5 <= $8){
                                // type checking, can only either INTEGER, DOUBLE, or BOOL
                                // entryType
                                toBeInputted.entryType = ARRAY_ENTTYPE;
                                // declared in which line number
                                toBeInputted.declaredLine = linenum;
                                // indices and length spec
                                toBeInputted.startIndices = $5;
                                toBeInputted.endIndices = $8;
                                int arrLength = $8 - $5 + 1;
                                toBeInputted.arrLength = arrLength;
                                // type of the array
                                toBeInputted.varConstOrResType = $10;
                                // only init dynamic array and push to symbolTable if type is valid
                                if($10 == INTEGER_TYPE){
                                    // set all arrayElementIsUnassigned is 0
                                    // set array value also to 0
                                    struct IdxPair entryPosition = insert($2.varName, debugMode);
                                    editAttributesOnIndex(entryPosition, toBeInputted, debugMode);
                                }else if($10 == DOUBLE_TYPE){
                                    // set all arrayElementIsUnassigned is 0
                                    // set array value also to 0
                                    struct IdxPair entryPosition = insert($2.varName, debugMode);
                                    editAttributesOnIndex(entryPosition, toBeInputted, debugMode);
                                }else if($10 == BOOL_TYPE){
                                    // set all arrayElementIsUnassigned is 0
                                    // set array value also to 0
                                    struct IdxPair entryPosition = insert($2.varName, debugMode);
                                    editAttributesOnIndex(entryPosition, toBeInputted, debugMode);
                                }else{
                                    printf("Error %d: %s array not initialized, due to invalid type: ", linenum, $2.varName);
                                    typePrintingHelperInC($10);
                                    printf("\n");
                                    errorExist = 1;
                                }
                            }else{
                                // not valid, left index bigger than right index
                                printf("Error %d: %s array not initialized, due to the left index %i is more than right index %i\n", linenum, $2.varName, $5, $8);
                                errorExist = 1;
                            }
                        }else{
                            printf("Error %d: %s identifier is already exist inside symbol table,cant declare var\n", linenum, $2.varName);
                            errorExist = 1;
                        }
                    }
                    ;

%%
yyerror(msg)
char* msg;
{
    fprintf(stderr, "%s\n", msg);
}

main(int argc, char *argv[])
{
    //set global variable
    functionResultTracker = defaultResultTrackerValue();
    // init symbol table
    create(debugMode, 1);

    char outputClassName[256];
    /* open the source program file */
    if (argc != 2) {
        printf ("Usage: sc filename\n");
        exit(1);
    }else{
        printf("Reminder! For filename, if it is in a directory, use / instead of \\\\\n");
        printf("Reminder! For Filename, there is only possible 1 . (dot) in it\n");
        char filename[256];
        strcpy(filename, argv[1]);
        char target = '/';
        char dot = '.';
        int dotIdx = -1;
        int slashIdx = -1;
        int idx = strlen(filename) - 1;
        while(idx > -1){
            if(filename[idx] == '.'){
                if(dotIdx != -1){
                    printf("Error, filename can only have 1 .\n");
                    exit(1);
                }
                dotIdx = idx;
            }else if(filename[idx] == '/'){
                slashIdx = idx;
                break;
            }
            idx -= 1;
        }
        
        //get substring
        int endIdx = dotIdx;
        if(dotIdx == -1){
            strlen(filename);
        }

        for(int idx = slashIdx + 1; idx < endIdx; idx++){
            outputClassName[idx - slashIdx - 1] = filename[idx];
        }
        outputClassName[endIdx - slashIdx - 1] = '\0';
    }
    yyin = fopen(argv[1], "r"); /* open input file */
    if(yyin == NULL){
        printf("%s does not exist\n", argv[1]);
        exit(1);
    }
    //give classname information to the code maker
    ////////WRITE CODE SECTION
    setFilename(outputClassName);
    //initialize main code in java
    initializeMain(&errorExist);
    ///////////////////////////
    /* perform parsing */
    if (yyparse() == 1){
        popBack(debugMode, 1);
        yyerror("Parsing error !"); /* syntax error */
        exit(1);
    }else{
        popBack(debugMode, 1);
        ////////WRITE CODE SECTION
        //write the output java file
        dumpFile(&errorExist);
        ///////////////////////////
    }
}