#include <iostream>
#include "codeMakerAPI.h"
#include "codeMaker.h"

//https://stackoverflow.com/questions/3789340/combining-c-and-c-how-does-ifdef-cplusplus-work
#ifdef __cplusplus
extern "C" {
#endif

    static CodeMaker *cm = NULL;

    void initCodeMakerEngine(){
        if(cm == NULL){
            printf("Creating new CodeMaker dynamic object\n");
            cm = new CodeMaker();
        }
    }
    void setFilename(const char* filename){
        initCodeMakerEngine();
        cm->SetFilename(filename);
    }
    void setCurrentlyInGlobalDeclare(int value){
        initCodeMakerEngine();
        cm->SetCurrentlyInAGlobalDeclare(value);
    }
    void functionDeclarationBegin(int* errorExist, struct IdxPair functionIdxEntry, enum Type returnType, struct ArgAccumulation  argumentList){
        initCodeMakerEngine();
        cm->FunctionDeclarationBegin(errorExist, functionIdxEntry, returnType, argumentList);
    }
    void functionDeclarationEnd(int* errorExist, enum Type resultType){
        initCodeMakerEngine();
        cm->FunctionDeclarationEnd(errorExist, resultType);
    }
    
    void declareGlobalVar(int* errorExist, struct IdxPair symbolTableEntryIdx, int valueless){
        initCodeMakerEngine();
        cm->DeclareGlobalVar(errorExist, symbolTableEntryIdx, valueless);
    }
    //NonDeclaration statement sections (+ declaration of local variable)
    void callFunction(int* errorExist, struct IdxPair functionIdxEntry, struct ArgAccumulation  argumentList){
        initCodeMakerEngine();
        cm->CallFunction(errorExist, functionIdxEntry, argumentList);
    }
    void beginBlockBegin(int* errorExist){
        initCodeMakerEngine();
        cm->BeginBlockBegin(errorExist);
    }
    void beginBlockEnd(int* errorExist){
        initCodeMakerEngine();
        cm->BeginBlockEnd(errorExist);
    }
    void resultReturnStatement(int* errorExist, enum Type returnType){
        initCodeMakerEngine();
        cm->ResultReturnStatement(errorExist, returnType);
    }
    void declareLocalVar(int* errorExist, struct IdxPair symbolTableEntryIdx, int valueless){
        initCodeMakerEngine();
        cm->DeclareLocalVar(errorExist, symbolTableEntryIdx, valueless);
    }
    void skipStatement(int* errorExist){
        initCodeMakerEngine();
        cm->SkipStatement(errorExist);
    }
    void ifStatementBegin(int* errorExist){
        initCodeMakerEngine();
        cm->IfStatementBegin(errorExist);
    }
    void elseStatementBegin(int* errorExist){
        initCodeMakerEngine();
        cm->ElseStatementBegin(errorExist);
    }
    void ifStatementEnd(int* errorExist){
        initCodeMakerEngine();
        cm->IfStatementEnd(errorExist);
    }
    void putStatementPreparation(int* errorExist){
        initCodeMakerEngine();
        cm->PutStatementPreparation(errorExist);
    }
    void putStatementIntBoolean(int* errorExist){
        initCodeMakerEngine();
        cm->PutStatementIntBoolean(errorExist);
    }
    void putStatementString(int* errorExist){
        initCodeMakerEngine();
        cm->PutStatementString(errorExist);
    }
    void loopStatementBegin(int* errorExist){
        initCodeMakerEngine();
        cm->LoopStatementBegin(errorExist);
    }
    void loopStatementEnd(int* errorExist){
        initCodeMakerEngine();
        cm->LoopStatementEnd(errorExist);
    }
    void forStatementUntilFirstExpression(int* errorExist){
        initCodeMakerEngine();
        cm->ForStatementUntilFirstExpression(errorExist);
    }
    void forStatementBegin(int* errorExist, struct IdxPair forVariable, int isDecreasing){
        initCodeMakerEngine();
        cm->ForStatementBegin(errorExist, forVariable, isDecreasing);
    }
    void forStatementEnd(int* errorExist, struct IdxPair forVariable, int isDecreasing){
        initCodeMakerEngine();
        cm->ForStatementEnd(errorExist, forVariable, isDecreasing);
    }
    void exitStatement(int* errorExist, int functionOrGlobalExit, int unconditionalExit){
        initCodeMakerEngine();
        cm->ExitStatement(errorExist, functionOrGlobalExit, unconditionalExit, 1);
    }
    //operand operations, to be put to the stack
    void storeGlobalVarInt(int* errorExist, struct IdxPair globalVariableIdx){
        initCodeMakerEngine();
        cm->StoreGlobalVarInt(errorExist, globalVariableIdx, 1);
    }
    void storeGlobalVarBoolean(int* errorExist, struct IdxPair globalVariableIdx){
        initCodeMakerEngine();
        cm->StoreGlobalVarBoolean(errorExist, globalVariableIdx, 1);
    }
    void loadGlobalVarInt(int* errorExist, struct IdxPair globalVariableIdx){
        initCodeMakerEngine();
        cm->LoadGlobalVarInt(errorExist, globalVariableIdx);
    }
    void loadGlobalVarBoolean(int* errorExist, struct IdxPair globalVariableIdx){
        initCodeMakerEngine();
        cm->LoadGlobalVarBoolean(errorExist, globalVariableIdx);
    }
    void loadConstantBoolean(int* errorExist, int value){
        initCodeMakerEngine();
        cm->LoadConstantBoolean(errorExist, value);
    }
    void loadConstantInteger(int* errorExist, int value){
        initCodeMakerEngine();
        cm->LoadConstantInteger(errorExist, value);
    }
    void loadConstantString(int* errorExist, const char* value){
        initCodeMakerEngine();
        cm->LoadConstantString(errorExist, value);
    }
    void loadLocalVariableInteger(int* errorExist, struct IdxPair entryLocation){
        initCodeMakerEngine();
        cm->LoadLocalVariableInteger(errorExist, entryLocation);
    }
    void loadLocalVariableBoolean(int* errorExist, struct IdxPair entryLocation){
        initCodeMakerEngine();
        cm->LoadLocalVariableBoolean(errorExist, entryLocation);
    }
    void storeLocalVariableInteger(int* errorExist, struct IdxPair entryLocation){
        initCodeMakerEngine();
        cm->StoreLocalVariableInteger(errorExist, entryLocation, 1);
    }
    void storeLocalVariableBoolean(int* errorExist, struct IdxPair entryLocation){
        initCodeMakerEngine();
        cm->StoreLocalVariableBoolean(errorExist, entryLocation, 1);
    }
    //operator operations
    void arithmeticOperators(int* errorExist, const char* symbol){
        initCodeMakerEngine();
        cm->ArithmeticOperators(errorExist, symbol);
    }
    void relationalOperators(int* errorExist, const char* symbol){
        initCodeMakerEngine();
        cm->RelationalOperators(errorExist, symbol);
    }
    void logicalOperators(int* errorExist, const char* symbol){
        initCodeMakerEngine();
        cm->LogicalOperators(errorExist, symbol);
    }
    //going to be used for expression without assignment, since nothing will pop it from the stack
    void removeTopOperandStack(int* errorExist){
        initCodeMakerEngine();
        cm->RemoveTopOperandStack(errorExist);
    }
    //main function related
    void initializeMain(int* errorExist){
        initCodeMakerEngine();
        cm->InitializeMain(errorExist);
    }
    void finishMain(int* errorExist){
        initCodeMakerEngine();
        cm->FinishMain(errorExist);
    }
    //dump the whole program into a file
    void dumpFile(int* errorExist){
        initCodeMakerEngine();
        cm->DumpFile(errorExist);
    }
    void writeCommentLine(int* errorExist, const char* stmt){
        initCodeMakerEngine();
        cm->WriteCommentLine(errorExist, stmt);
    }

    void popExpression(int*errorExist){
        initCodeMakerEngine();
        cm->PopExpression(errorExist);
    }

    void encounterUnableToExpress(int* errorExist, const char* feature, int linenum){
        initCodeMakerEngine();

        printf("Due to meeting feature that can't be implemented: %s in line %d, can't implement code maker\n", feature, linenum);
        *errorExist = 1;
    }
#ifdef __cplusplus
}
#endif