#ifndef CODEMAKER_CPP_API
#define CODEMAKER_CPP_API
#include <stdio.h>
#include "commonDataStructure.h"
#ifdef __cplusplus
extern "C" {
#endif 
    //init API Engine.
    //this function will be the same as the one in codeMaker.h
    //written this way so that C can call C++ functions
    void initCodeMakerEngine();
    void setFilename(const char* filename);
    void setCurrentlyInGlobalDeclare(int value);
    //Declaration Sections
    void functionDeclarationBegin(int* errorExist, struct IdxPair functionIdxEntry, enum Type returnType, struct ArgAccumulation  argumentList);
    void functionDeclarationEnd(int* errorExist, enum Type resultType);
    void declareGlobalVar(int* errorExist, struct IdxPair symbolTableEntryIdx, int valueless);
    //NonDeclaration statement sections (+ declaration of local variable)

    void declareLocalVar(int* errorExist, struct IdxPair symbolTableEntryIdx, int valueless);
    void callFunction(int* errorExist, struct IdxPair functionIdxEntry, struct ArgAccumulation  argumentList);
    void resultReturnStatement(int* errorExist, enum Type returnType);
    void beginBlockBegin(int* errorExist);
    void beginBlockEnd(int* errorExist);
    void skipStatement(int* errorExist);
    void ifStatementBegin(int* errorExist);
    void elseStatementBegin(int* errorExist);
    void ifStatementEnd(int* errorExist);
    void putStatementPreparation(int* errorExist);
    void putStatementIntBoolean(int* errorExist);
    void putStatementString(int* errorExist);
    void loopStatementBegin(int* errorExist);
    void loopStatementEnd(int* errorExist);
    void forStatementUntilFirstExpression(int* errorExist);
    void forStatementBegin(int* errorExist, struct IdxPair forVariable, int isDecreasing);
    void forStatementEnd(int* errorExist, struct IdxPair forVariable, int isDecreasing);
    void exitStatement(int* errorExist, int functionOrGlobalExit, int unconditionalExit);
    //operand operations, to be put to the stack
    void storeGlobalVarInt(int* errorExist, struct IdxPair globalVariableIdx);
    void storeGlobalVarBoolean(int* errorExist, struct IdxPair globalVariableIdx);
    void loadGlobalVarInt(int* errorExist, struct IdxPair globalVariableIdx);
    void loadGlobalVarBoolean(int* errorExist, struct IdxPair globalVariableIdx);
    void loadConstantBoolean(int* errorExist, int value);
    void loadConstantInteger(int* errorExist, int value);
    void loadConstantString(int* errorExist, const char* value);
    void loadLocalVariableInteger(int* errorExist, struct IdxPair entryLocation);
    void loadLocalVariableBoolean(int* errorExist, struct IdxPair entryLocation);
    void storeLocalVariableInteger(int* errorExist, struct IdxPair entryLocation);
    void storeLocalVariableBoolean(int* errorExist, struct IdxPair entryLocation);
    //operator operations
    void arithmeticOperators(int* errorExist, const char* symbol);
    void relationalOperators(int* errorExist, const char* symbol);
    void logicalOperators(int* errorExist, const char* symbol);
    //going to be used for expression without assignment, since nothing will pop it from the stack
    void removeTopOperandStack(int* errorExist);
    //main function related
    void initializeMain(int* errorExist);
    void finishMain(int* errorExist);
    //dump the whole program into a file
    void dumpFile(int* errorExist);
    void writeCommentLine(int* errorExist, const char* stmt);
    void popExpression(int* errorExist);


    void encounterUnableToExpress(int* errorExist, const char* feature, int linenum);
#ifdef __cplusplus
}
#endif 

#endif 