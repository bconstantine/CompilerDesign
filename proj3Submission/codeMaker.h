#ifndef CODEMAKER_CPP
#define CODEMAKER_CPP
#define MAXSTACK 15
#define MAXLOCAL 15
#include <iostream>
#include <vector>
#include <fstream>
#include "symbolTableFix.h"
#include "symbolTableAPIFix.h"

//construct that needs branching
enum ConstructType{ 
    IF,
    IFELSE,
    WHILEFORLOOP, 
};


//global declaration type
enum GlobalDeclareType{
    FUNCTIONPROCEDURE,
    GLOBALVAR,
};

struct ConstructInfo{
    std::string contents;
    std::string enterBranchCode; //branch code to enter here
    std::string exitBranchCode; //branch code to exit
    enum ConstructType ct;

    /*note that for an if branch
        enterBranchCode: code to enter the else part, if not exist just leave it blank, like:
            enterBranchCode:
            exitBranchCode:
        exitBranchCode: exit the if section (nevertheless the loop goes to ifscope part or else part, it exits to this branch )
    */

    /*for a loop branch:
        enterBranchCode: branch code to enter the loop
        exitBranchCode: branch code to exit the loop
    */
};

struct GlobalDeclareInfo{
    /*to be printed before the main */
    std::string contents;
    enum GlobalDeclareType gdt;

    //if gdt is function/procedure, use these constructs
    int functionGlobalExitExist;
    std::string exitName;
};

class CodeMaker{
    public:
        //used to define max_stack and max_locals
        int defaultMaxStack;
        int defaultMaxLocal;

        //tab amount
        int tabAmount;

        //store the global declaration sections
        std::vector<GlobalDeclareInfo> declarationSectionStacks;

        //store program construct that require branching
        std::vector<ConstructInfo> temporaryConstructStacks;
        
        //main program holder
        std::string mainProgram;


        //set filename
        std::string filename;

        //for second expr of for, it should be written after branch code, so dump it here first
        std::string temporaryCanvas;

        //for comment, because comment is evaluated first before string end, so write comment to a temp string
        std::string commentCanvas;

        //for exit branch of main, if there is exit exists in global
        std::string mainExitBranch;
        int globalExitExists;
        
        //for global declaration, and if it is in a function, this should be on
        int writeToDeclareSectionStacks = 0;

        //when global declare, expression should not be written
        int currentlyInAGlobalDeclare;

        //if currently in a for loop, force write to canvas first, and the rest will be ignored
        int secondForExpressionForceWriteToCanvas;

        //branchCode
        int branchCode; // only to make sure branch has no duplicate

        CodeMaker(){
            defaultMaxLocal = MAXLOCAL;
            defaultMaxStack = MAXSTACK;
            tabAmount = 1;
            branchCode = 0;
            temporaryCanvas = "";
            currentlyInAGlobalDeclare = 0;
            commentCanvas = "";
            mainExitBranch = "MainExitBranch";
            globalExitExists = 0;
        }

        ////////////HELPER FUNCTION, ONLY USED INSIDE THE CLASS
        std::string processTabs(std::string followUp){
            std::string outputStr = "";
            for(int i = 0; i < tabAmount; i++){
                outputStr += "\t";
            }
            outputStr += followUp;
            return outputStr;
        }
        
        //dump to canvas for these construct: 
        /*
        - for second expression

        */
        void dumpConstructToCanvas(std::string toBeDumped){
            if(secondForExpressionForceWriteToCanvas){
                temporaryCanvas += toBeDumped;
            }else if(currentlyInAGlobalDeclare){
                //do not write anything
            }else{
                dumpConstructToCorrectTarget(toBeDumped);
            }
        }

        void flushCanvas(){
            dumpConstructToCorrectTarget(temporaryCanvas);
            resetCanvas();
        }

        void resetCanvas(){
            temporaryCanvas = "";
        }

        void flushCommentCanvas(){
            dumpConstructToCorrectTarget(commentCanvas);
            resetCommentCanvas();
        }

        void resetCommentCanvas(){
            commentCanvas = "";
        }

        void dumpConstructToCorrectTarget(std::string toBeDumped){
            //final construct will be dumped to the last target, which follows the following rule:
                //if the ConstructStack previous it is not empty, dump it to previous stack
                //else if globalDeclareDone, dump it to main
                //else dump it into the last declarationSectionStacks
            if(temporaryConstructStacks.size() > 0){
                temporaryConstructStacks[temporaryConstructStacks.size() - 1].contents += toBeDumped;
            }else if(writeToDeclareSectionStacks){
                if(declarationSectionStacks.size() == 0){
                    std::cout << "Fault in program dumpConstructToCorrectTarget: declarationSectionStacks is empty\n";
                    exit(1);
                }
                declarationSectionStacks[declarationSectionStacks.size() - 1].contents += toBeDumped;
            }else{
                mainProgram += toBeDumped;
            }
        }

        //dump temporaryConstructStack into target
        void DumpLastConstructStack(){
            //final construct will be dumped to the following rule:
                //if the ConstructStack previous it is not empty, dump it to previous stack
                //else if globalDeclareDone, dump it to main
                //else dump it into the last declarationSectionStacks
            if(temporaryConstructStacks.size() < 1){
                std::cout << "Error when dumping temporary construct stack, has 0 stack\n";
                exit(1);
            }
            std::string toBeDumped = temporaryConstructStacks[temporaryConstructStacks.size() - 1].contents;
            temporaryConstructStacks.pop_back();
            dumpConstructToCorrectTarget(toBeDumped);
        }
        
        void increaseTabs(){
            tabAmount += 1;
        }

        void decreaseTabs(){
            tabAmount -= 1;
        }

        int returnAndIncreaseBranchCode(){
            int oldVal = branchCode;
            branchCode += 1;
            return oldVal;
        }

        ConstructInfo BuildConstructInfo(std::string contents, enum ConstructType ct, std::string enterBranchCode, std::string exitBranchCode){
            ConstructInfo a;
            a.contents = contents;
            a.ct = ct;
            a.enterBranchCode = enterBranchCode;
            a.exitBranchCode = exitBranchCode;
            return a;
        }

        GlobalDeclareInfo BuildGlobalDeclareInfo(std::string contents, enum GlobalDeclareType gdt, int functionGlobalExitExist, std::string exitName){
            GlobalDeclareInfo a;
            a.contents = contents;
            a.gdt = gdt;
            a.functionGlobalExitExist = functionGlobalExitExist;
            a.exitName = exitName;
            return a;
        }

        void closingIfOrElseBeginHelper(std::string elseBranchEntry, std::string ifBranchExit){
            std::string exitBranching = processTabs("goto " + ifBranchExit + "\n");
            dumpConstructToCorrectTarget(exitBranching);
            BranchingAssist(elseBranchEntry);
        }

        void clossingLoopOrForHelper(std::string branchBegin, std::string branchExit){
            std::string gotoString = processTabs("goto " + branchBegin + "\n");
            dumpConstructToCorrectTarget(gotoString);
            //insert the exit code
            BranchingAssist(branchExit);
        }

        void functionReturnTypeListing(int* errorExist, std::string& target, enum Type returnType){
            if(returnType == INTEGER_TYPE){
                target += "int ";
            }else if (returnType == BOOL_TYPE){
                target += "int ";
            }else if(returnType == VOID_TYPE)
            {
                target += "void ";
            }
            else{
                std::cout << "###Code Maker Error: this code maker only takes case return value of Integer, bool and void non array, get: ";
                typePrintingHelper(returnType, "");
                std::cout << "\n";
                *errorExist = 1;
                return;
            }
        }

        void functionArgumentListing(int* errorExist, std::string& target, struct ArgAccumulation argumentList){
            if(!(*errorExist)){
                for(int i = 0; i < argumentList.paramsLength; i++){
                    // no array is considered
                    if(i > 0){
                        target += ", ";
                    }
                    
                    if(argumentList.paramsOrdering[i] == IPARAM){
                        target += "int";
                    }else if(argumentList.paramsOrdering[i] == BPARAM){
                        target += "int";
                    }else{
                        std::cout << "argumentList.paramsLength: " << argumentList.paramsLength << "\n";
                        std::cout << "value: " << argumentList.paramsOrdering[i] << "\n";
                        std::cout << "###Code maker error - this code maker only takes case of argument with Integer, bool non array parameter, get:";
                        paramsTypePrintingHelper(argumentList.paramsOrdering[i], argumentList.eachParamsHowManyElements[i], "");
                        std::cout << "\n";
                        *errorExist = 1;
                        return;
                    }
                }
            }
        }
        
        void flushForSecondExpression(int* errorExist){
            if(!(*errorExist)){
                //for always 
                flushCanvas();
                secondForExpressionForceWriteToCanvas = 0;
            }
        }

        ///////////////////////////////////////////////////////

        void SetFilename(const char* filename){
            std::string goalfilename = filename;
            if((goalfilename[0] >= '0' && goalfilename[0] <= '9')){
                goalfilename = "randomName";
            }
            this->filename = goalfilename;
        }
        void SetCurrentlyInAGlobalDeclare(int value){
            this->currentlyInAGlobalDeclare = value;
        }
        //////////////////////////////////////Declaration Sections
        void FunctionDeclarationBegin(int* errorExist, IdxPair functionIdxEntry, enum Type returnType, struct ArgAccumulation  argumentList){
            //make new entry, but leave the return type for later
            if(!(*errorExist)){
                //error checking in argument list, because by this point errorExist is still 0
                writeToDeclareSectionStacks = 1;
                if(argumentList.isEncounterError){
                    *errorExist = 1;
                    std::cout << "###Code maker detects error in argument and will modify error exist!\n";
                }else{
                    std::string functionHeader = "\tmethod public static ";
                    // return type
                    functionReturnTypeListing(errorExist, functionHeader, returnType);
                    if((*errorExist)){
                        return;
                    }
                    functionHeader += functionIdxEntry.varName;

                    //parameters
                    functionHeader += "(";
                    functionArgumentListing(errorExist, functionHeader, argumentList);
                    if((*errorExist)){
                        return;
                    }
                    functionHeader += ")\n";
                    std::string contents = functionHeader;
                    contents += "\tmax_stack " + std::to_string(defaultMaxStack) + "\n";
                    contents += "\tmax_locals " + std::to_string(defaultMaxLocal) + "\n";
                    contents += "\t{\n";
                    std::string functionExitBranch = "FPExit_";
                    functionExitBranch += functionIdxEntry.varName;
                    GlobalDeclareInfo gdi = BuildGlobalDeclareInfo(contents, FUNCTIONPROCEDURE, 0, functionExitBranch);
                    increaseTabs();
                    declarationSectionStacks.push_back(gdi);

                    ///////////flush comment after finish a construct
                    flushCommentCanvas();
                    ////////////////////////////////////////////////
                }
            }
        }
        void FunctionDeclarationEnd(int* errorExist, enum Type returnType){
            if(!(*errorExist)){
                //verify that temporary construct stack should be empty, not currently in main, and last declarationSectionStacks is FUNCTIONPROCEDURE
                int verifyCorrect = 0;
                int conditionA = temporaryConstructStacks.size() == 0;
                int conditionB = writeToDeclareSectionStacks == 1;
                int conditionC = declarationSectionStacks.size() > 0 && declarationSectionStacks[declarationSectionStacks.size() - 1].gdt == FUNCTIONPROCEDURE;
                if( conditionA && conditionB && conditionC ){
                    verifyCorrect = 1;
                }

                if(!verifyCorrect){
                    std::cout << "###Code maker error in function declaration end due to one of these condition not fulfilled: ";
                    if(!conditionA){
                        std::cout << "conditionA ";
                    }
                    if(!conditionB){
                        std::cout << "conditionB ";
                    }
                    if(!conditionC){
                        std::cout << "conditionC ";
                    }
                    std::cout << "\n";
                    *errorExist = 1;
                }

                //add closing bracket
                if(declarationSectionStacks[declarationSectionStacks.size() - 1].functionGlobalExitExist){
                    BranchingAssist(declarationSectionStacks[declarationSectionStacks.size() - 1].exitName);
                }

                //add default exit
                if(returnType == INTEGER_TYPE){
                    dumpConstructToCorrectTarget(processTabs("iconst_0\n"));
                    dumpConstructToCorrectTarget(processTabs("ireturn\n"));
                    ///////////flush comment after finish a construct
                    flushCommentCanvas();
                    ////////////////////////////////////////////////
                }else if (returnType == BOOL_TYPE){
                    dumpConstructToCorrectTarget(processTabs("iconst_0\n"));
                    dumpConstructToCorrectTarget(processTabs("ireturn\n"));
                    ///////////flush comment after finish a construct
                    flushCommentCanvas();
                    ////////////////////////////////////////////////
                }else if(returnType == VOID_TYPE)
                {
                    dumpConstructToCorrectTarget(processTabs("return\n"));
                    ///////////flush comment after finish a construct
                    flushCommentCanvas();
                    ////////////////////////////////////////////////
                }
                else{
                    std::cout << "###Code Maker error: this code maker only takes case return value of Integer, bool non array\n";
                    *errorExist = 1;
                }

                decreaseTabs();
                dumpConstructToCorrectTarget("\t}\n");
                ///////////flush comment after finish a construct
                flushCommentCanvas();
                ////////////////////////////////////////////////
                writeToDeclareSectionStacks = 0;
            }
        }

        void DeclareGlobalVar(int* errorExist, IdxPair symbolTableEntryIdx, int valueless){
            if(!(*errorExist)){
                writeToDeclareSectionStacks = 1;
                std::string resultStr = "";
                std::string varName = symbolTableEntryIdx.varName;
                EntryAttributes variableInfo = fromIdxPairReturnAttributes(symbolTableEntryIdx, 0);
                if(variableInfo.entryType == VAR_ENTTYPE){
                    if(variableInfo.varConstOrResType == INTEGER_TYPE){
                        //resultStr += processTabs("field static int " + varName);
                        //since field static global variable is in outside, don't use process tabs
                        resultStr += ("\tfield static int " + varName);
                        if(!valueless){
                            resultStr+="= ";
                            resultStr += std::to_string(variableInfo.iVal);
                        }
                        resultStr += "\n";
                    }else if (variableInfo.varConstOrResType == BOOL_TYPE){
                        //resultStr += processTabs("field static int " + varName);
                        //since field static global variable is in outside, don't use process tabs
                        resultStr += ("\tfield static int " + varName);
                        if(!valueless){
                            resultStr+="= ";
                            resultStr += std::to_string(variableInfo.boolVal);
                        }
                        resultStr += "\n";
                    }else{
                        std::cout << "###Code generation error: non integer/boolean variable is being called with declare global var\n";
                        *errorExist = 1;
                        return;
                    }
                }else{
                    std::cout << "###Code generation error: non variable entity is being called with declare global var\n";
                    *errorExist = 1;
                    return;
                }
                GlobalDeclareInfo gdi = BuildGlobalDeclareInfo(resultStr, GLOBALVAR, 0, "");
                declarationSectionStacks.push_back(gdi);
                ///////////flush comment after finish a construct
                flushCommentCanvas();
                ////////////////////////////////////////////////
                writeToDeclareSectionStacks = 0;
            }
        }
        
        /////////////////////////NonDeclaration statement sections (+ declaration of local variable)
        void DeclareLocalVar(int* errorExist, IdxPair symbolTableEntryIdx, int valueless){
            //local variable number is located already in entry attributes
            if(!(*errorExist)){
                EntryAttributes variableInfo = fromIdxPairReturnAttributes(symbolTableEntryIdx, 0);
                int localVariableNumber = variableInfo.localVariableNumber;
                
                if(variableInfo.entryType == VAR_ENTTYPE){
                    std::string resultStr = "";
                    if(variableInfo.varConstOrResType == INTEGER_TYPE){
                        if(!valueless){
                            resultStr += processTabs("istore ");
                            resultStr += std::to_string(localVariableNumber);
                            resultStr += "\n";
                        }else{
                            //for now set to default value
                            resultStr += processTabs("sipush 0");
                            resultStr += processTabs("istore ");
                            resultStr += std::to_string(localVariableNumber);
                            resultStr += "\n";
                        }
                        dumpConstructToCorrectTarget(resultStr);
                        ///////////flush comment after finish a construct
                        flushCommentCanvas();
                        ////////////////////////////////////////////////
                    }else if (variableInfo.varConstOrResType == BOOL_TYPE){
                        if(!valueless){
                            resultStr += processTabs("istore ");
                            resultStr += std::to_string(localVariableNumber);
                            resultStr += "\n";
                        }else{
                            //for now set to default value
                            resultStr += processTabs("sipush 0");
                            resultStr += processTabs("istore ");
                            resultStr += std::to_string(localVariableNumber);
                            resultStr += "\n";
                        }
                        dumpConstructToCorrectTarget(resultStr);
                        ///////////flush comment after finish a construct
                        flushCommentCanvas();
                        ////////////////////////////////////////////////
                    }else{
                        std::cout << "###Code generation error: non integer/boolean variable is being called with declare local var\n";
                        *errorExist = 1;
                        return;
                    }
                }else{
                    std::cout << "###Code generation error: non variable entity is being called with declare local var\n";
                    *errorExist = 1;
                    return;
                }   
            }
        }

        void CallFunction(int* errorExist, IdxPair functionIdxEntry, struct ArgAccumulation  argumentList){
            if(!(*errorExist)){
                if(argumentList.isEncounterError){
                    *errorExist = 1;
                    std::cout << "###Code maker detects error in argument and will modify error exist!\n";
                }else{
                    std::string functionHeader = processTabs("invokestatic ");
                    EntryAttributes functionEntry = fromIdxPairReturnAttributes(functionIdxEntry, 0);
                    enum Type returnType = functionEntry.varConstOrResType;
                    // return type
                    functionReturnTypeListing(errorExist, functionHeader, returnType);
                    if((*errorExist)){
                        return;
                    }
                    functionHeader += functionIdxEntry.varName;
                    //parameters
                    functionHeader += "(";
                    functionArgumentListing(errorExist, functionHeader, argumentList);
                    if((*errorExist)){
                        return;
                    }
                    functionHeader += ")\n";
                    dumpConstructToCorrectTarget(functionHeader);
                    ///////////flush comment after finish a construct
                    flushCommentCanvas();
                    ////////////////////////////////////////////////
                }
            }
        }

        void BeginBlockBegin(int* errorExist){
            if(!(*errorExist)){
                ///////////flush comment after finish a construct
                flushCommentCanvas();
                ////////////////////////////////////////////////
                increaseTabs();
            }
        }

        void BeginBlockEnd(int* errorExist){
            if(!(*errorExist)){
                ///////////flush comment after finish a construct
                flushCommentCanvas();
                ////////////////////////////////////////////////
                decreaseTabs();
            }
        }
        void ResultReturnStatement(int* errorExist, enum Type returnType){
            if(!(*errorExist)){
                // return type
                if(returnType == INTEGER_TYPE){
                    dumpConstructToCorrectTarget(processTabs("ireturn\n"));
                    ///////////flush comment after finish a construct
                    flushCommentCanvas();
                    ////////////////////////////////////////////////
                }else if (returnType == BOOL_TYPE){
                    dumpConstructToCorrectTarget(processTabs("ireturn\n"));
                    ///////////flush comment after finish a construct
                    flushCommentCanvas();
                    ////////////////////////////////////////////////
                }else if(returnType == VOID_TYPE)
                {
                    dumpConstructToCorrectTarget(processTabs("return\n"));
                    ///////////flush comment after finish a construct
                    flushCommentCanvas();
                    ////////////////////////////////////////////////
                }
                else{
                    std::cout << "###Code Maker error: this code maker only takes case return value of Integer, bool non array\n";
                    *errorExist = 1;
                }
            }
        }

        void SkipStatement(int* errorExist){
            if(!(*errorExist)){
                PutStatementPreparation(errorExist);
                dumpConstructToCorrectTarget(processTabs("invokevirtual void java.io.PrintStream.println()\n"));
                ///////////flush comment after finish a construct
                flushCommentCanvas();
                ////////////////////////////////////////////////
            }
        }
        void IfStatementBegin(int* errorExist){
            if(!(*errorExist)){
                std::string elseBranchEntry = "LFalse_"+ std::to_string(returnAndIncreaseBranchCode());
                std::string ifExitBranch = "Lexit_"+std::to_string(returnAndIncreaseBranchCode());
                //for the if body
                std::string ifOpening = processTabs("ifeq " + elseBranchEntry+"\n");
                ConstructInfo now = BuildConstructInfo(ifOpening, IF, elseBranchEntry, ifExitBranch);
                temporaryConstructStacks.push_back(now);
                ///////////flush comment after finish a construct
                flushCommentCanvas();
                ////////////////////////////////////////////////
                increaseTabs();
            }
        }
        void ElseStatementBegin(int* errorExist){
            if(!(*errorExist)){
                int verifyCorrect = 0;
                
                //verify that the last entry should be if, no else existed yet
                if(temporaryConstructStacks.size() > 0 && temporaryConstructStacks[temporaryConstructStacks.size() - 1].ct == IF){
                    verifyCorrect = 1;
                }

                if(!verifyCorrect){
                    *errorExist = 1;
                    std::cout << "###Code maker error, either stack is not 0 or last entry is not an if\n";
                    return;
                } 

                std::string elseBranchEntry = temporaryConstructStacks[temporaryConstructStacks.size() - 1].enterBranchCode;
                std::string ifExitBranch = temporaryConstructStacks[temporaryConstructStacks.size() - 1].exitBranchCode;

                //modify the if construct type to be IFELSE
                temporaryConstructStacks[temporaryConstructStacks.size() - 1].ct = IFELSE;
                //write the goto and false branch
                closingIfOrElseBeginHelper(elseBranchEntry, ifExitBranch);
                ///////////flush comment after finish a construct
                flushCommentCanvas();
                ////////////////////////////////////////////////
            }
        }
        void IfStatementEnd(int* errorExist){
            if(!(*errorExist)){
                int verifyCorrect = 0;
                
                //verify that the last entry should be if or ifelse
                if(temporaryConstructStacks.size() > 0 && (temporaryConstructStacks[temporaryConstructStacks.size() - 1].ct == IF || temporaryConstructStacks[temporaryConstructStacks.size() - 1].ct == IFELSE)){
                    verifyCorrect = 1;
                }

                if(!verifyCorrect){
                    *errorExist = 1;
                    std::cout << "###Code maker error, either stack is not 0 or last entry is not an if or ifelse\n";
                    return;
                } 

                std::string elseBranchEntry = temporaryConstructStacks[temporaryConstructStacks.size() - 1].enterBranchCode;
                std::string ifExitBranch = temporaryConstructStacks[temporaryConstructStacks.size() - 1].exitBranchCode;

                
                //the case if there is else, no need to rewrite else branch and goto exit
                //the case if there is no else, need to rewrite else branch and goto exit
                if(temporaryConstructStacks[temporaryConstructStacks.size() - 1].ct == IF){
                    closingIfOrElseBeginHelper(elseBranchEntry, ifExitBranch);
                }

                //add the exit branch code
                BranchingAssist(ifExitBranch);

                ///////////flush comment after finish a construct
                flushCommentCanvas();
                ////////////////////////////////////////////////

                //merge with other construct
                std::cout << "Before dump last construct: ";
                for(int i = 0; i < temporaryConstructStacks.size(); i++){
                    std::cout << temporaryConstructStacks[i].ct << " ";
                }
                std::cout << "\n";
                DumpLastConstructStack();
                std::cout << "After dump last construct: ";
                for(int i = 0; i < temporaryConstructStacks.size(); i++){
                    std::cout << temporaryConstructStacks[i].ct << " ";
                }
                std::cout << "\n";
                decreaseTabs();
            }
        }

        //because the getstatic java.io.PrintStream java.lang.System.out needs to be called before computing the expression
        void PutStatementPreparation(int* errorExist){
            if(!(*errorExist)){
                //no need to write comment
                dumpConstructToCorrectTarget(processTabs("getstatic java.io.PrintStream java.lang.System.out\n"));
            }
        }
        void PutStatementIntBoolean(int* errorExist){
            if(!(*errorExist)){
                dumpConstructToCorrectTarget(processTabs("invokevirtual void java.io.PrintStream.print(int)\n"));
                ///////////flush comment after finish a construct
                flushCommentCanvas();
                ////////////////////////////////////////////////
            }
        }
        void PutStatementString(int* errorExist){
            if(!(*errorExist)){
                dumpConstructToCorrectTarget(processTabs("invokevirtual void java.io.PrintStream.print(java.lang.String)\n"));
                ///////////flush comment after finish a construct
                flushCommentCanvas();
                ////////////////////////////////////////////////
            }
        }
        void LoopStatementBegin(int* errorExist){
            if(!(*errorExist)){
                //make a new scope for inside the loop
                std::string loopingBranchEnter = "LBegin_" + std::to_string(returnAndIncreaseBranchCode());
                std::string loopingBranchExit = "LExit_" + std::to_string(returnAndIncreaseBranchCode());

                
                //for the loop body
                ConstructInfo now = BuildConstructInfo("", WHILEFORLOOP, loopingBranchEnter, loopingBranchExit);
                temporaryConstructStacks.push_back(now);
                BranchingAssist(loopingBranchEnter);
                 //std::cout << "tempStackSize: " << temporaryConstructStacks.size() << "\n";
                ///////////flush comment after finish a construct
                flushCommentCanvas();
                ////////////////////////////////////////////////
                increaseTabs();

            }
        }
        void LoopStatementEnd(int* errorExist){
            //verify that the last entry is a loop
            if(!(*errorExist)){
                int verifyCorrect = 0;
                if(temporaryConstructStacks.size() > 0 && temporaryConstructStacks[temporaryConstructStacks.size() - 1].ct == WHILEFORLOOP){
                    verifyCorrect = 1;
                }

                if(!verifyCorrect){
                    *errorExist = 1;
                    std::cout << "###Code maker error in loop statement end, either stack is not 0 or last entry is not a loop\n";
                    return;
                } 
                
                std::string loopingBranchBegin = temporaryConstructStacks[temporaryConstructStacks.size() - 1].enterBranchCode;
                std::string loopingBranchExit = temporaryConstructStacks[temporaryConstructStacks.size() - 1].exitBranchCode;
                //insert the name of the loop to the main program
                clossingLoopOrForHelper(loopingBranchBegin, loopingBranchExit);
                ///////////flush comment after finish a construct
                flushCommentCanvas();
                ////////////////////////////////////////////////
                //merge with previous construct
                DumpLastConstructStack();
                decreaseTabs();
            }
        }

        void ForStatementUntilFirstExpression(int* errorExist){
            if(!(*errorExist)){
                //if for first expression is in the first statement in non declaration, first expression will still be in temporaryCanvas
                secondForExpressionForceWriteToCanvas = 1;
                increaseTabs();
            }
        }

        void ForStatementBegin(int* errorExist, IdxPair forVariable, int isDecreasing){
            if(!(*errorExist)){
                //when writing a for
                std::string varName = forVariable.varName;
                EntryAttributes varInfo = fromIdxPairReturnAttributes(forVariable, 0);
                

                std::string ForBranchEnter = "LForBegin_" + std::to_string(returnAndIncreaseBranchCode());
                std::string ForBranchExit = "LForExit_" + std::to_string(returnAndIncreaseBranchCode());
                //open new branch
                ConstructInfo now = BuildConstructInfo("", WHILEFORLOOP, ForBranchEnter, ForBranchExit);
                temporaryConstructStacks.push_back(now);
                
                //initialize forVariable

                //the first expression has been written in ForStatementUntilFirstExpression()
                //the second expression (expression after ..) is still in canvas
                if(varInfo.varConstOrResType == INTEGER_TYPE && varInfo.entryType == VAR_ENTTYPE){
                    secondForExpressionForceWriteToCanvas = 0;
                    StoreLocalVariableInteger(errorExist, forVariable, 0);
                }else{
                    std::cout << "###Code maker Error, for variable can only be integer variable type\n";
                    *errorExist = 1;
                    return;
                }
                
                //for the for opening
                BranchingAssist(ForBranchEnter);
                //create exit condition
                LoadLocalVariableInteger(errorExist, forVariable);
                flushForSecondExpression(errorExist);
                if(isDecreasing){
                    // exit when (forVariable < finishValue)
                    RelationalOperators(errorExist, "<");
                }else{
                    // exit when (forVariable > finishValue)
                    RelationalOperators(errorExist, ">");
                }
                //flush comment is already in exit statement
                ExitStatement(errorExist, 0, 0, 1);
            }
        }
        void ForStatementEnd(int* errorExist, IdxPair forVariable, int isDecreasing){
            if(!(*errorExist)){
                int verifyCorrect = 0;
                if(temporaryConstructStacks.size() > 0 && temporaryConstructStacks[temporaryConstructStacks.size() - 1].ct == WHILEFORLOOP){
                    verifyCorrect = 1;
                }

                if(!verifyCorrect){
                    *errorExist = 1;
                    std::cout << "###Code maker error: in for statement end, either stack is not 0 or last entry is not a loop\n";
                    return;
                } 
                
                std::string forBranchBegin = temporaryConstructStacks[temporaryConstructStacks.size() - 1].enterBranchCode;
                std::string forBranchExit = temporaryConstructStacks[temporaryConstructStacks.size() - 1].exitBranchCode;
                //increment or decrement
                LoadLocalVariableInteger(errorExist, forVariable);
                LoadConstantInteger(errorExist, 1);
                if(isDecreasing){
                    //i := i - 1
                    ArithmeticOperators(errorExist, "SUBTRACTION");
                }else{
                    //i := i + 1
                    ArithmeticOperators(errorExist, "ADDITION");
                }
                StoreLocalVariableInteger(errorExist, forVariable, 0);
                //closing of the for loop
                clossingLoopOrForHelper(forBranchBegin, forBranchExit);
                ///////////flush comment after finish a construct
                flushCommentCanvas();
                ////////////////////////////////////////////////
                //merge with previous construct
                DumpLastConstructStack();
                decreaseTabs();
            }
        }
        void ExitStatement(int* errorExist, int functionOrGlobalExit, int unconditionalExit, int flushComment){
            if(!(*errorExist)){
                std::string loopingBranchExit;
                if(functionOrGlobalExit)
                {
                    if(writeToDeclareSectionStacks){
                        //verify that the last declaration section stacks should be function procedure type
                        if(declarationSectionStacks.size() > 0 && declarationSectionStacks[declarationSectionStacks.size() - 1].gdt == FUNCTIONPROCEDURE){
                            //valid
                            loopingBranchExit = declarationSectionStacks[declarationSectionStacks.size() - 1].exitName;
                            declarationSectionStacks[declarationSectionStacks.size() - 1].functionGlobalExitExist = 1;
                        }else{
                            *errorExist = 1;
                            std::cout << "###Code maker error: exit statement cannot find target function or procedure\n";
                            return;
                        }
                    }else{
                        loopingBranchExit = mainExitBranch;
                        globalExitExists = 1;
                    }
                    

                }
                else{
                    //loop might not the last section
                    //in this case, exit will search gradually from the back for a loop
                    int correspondLoop = temporaryConstructStacks.size() - 1;
                    //std::cout << "correspond loop: " << correspondLoop << "\n";
                    while(correspondLoop > -1){
                        //std::cout << "Entering here\n";
                        if(temporaryConstructStacks[correspondLoop].ct == WHILEFORLOOP){
                            break;
                        }
                        correspondLoop--;
                    }
                    
                    if(correspondLoop > -1){
                        //valid
                        loopingBranchExit = temporaryConstructStacks[correspondLoop].exitBranchCode;
                    }else{
                        *errorExist = 1;
                        std::cout << "###Code maker error: exit statement cannot find target loop\n";
                        return;
                    }
                }

                //valid and begin writing the exit
                if(!unconditionalExit){
                    dumpConstructToCorrectTarget(processTabs("ifne " + loopingBranchExit+"\n"));
                }else{
                    //no condition, always exit
                    dumpConstructToCorrectTarget(processTabs("goto " + loopingBranchExit+ "\n"));
                }


                if(flushComment)
                {
                    ///////////flush comment after finish a construct
                    flushCommentCanvas();
                    ////////////////////////////////////////////////
                }
            }
        }
        //operand operations, to be put to the stack
        void StoreGlobalVarInt(int* errorExist, IdxPair globalVariableIdx, int flushComment){
            if(!(*errorExist)){
                std::string globalVarName = globalVariableIdx.varName;
                dumpConstructToCorrectTarget(processTabs("putstatic int " + filename + "." + globalVarName + "\n"));

                if(flushComment)
                {
                    ///////////flush comment after finish a construct
                    flushCommentCanvas();
                    ////////////////////////////////////////////////
                }
            }
        }
        void StoreGlobalVarBoolean(int* errorExist, IdxPair globalVariableIdx, int flushComment){
            if(!(*errorExist)){
                std::string globalVarName = globalVariableIdx.varName;
                dumpConstructToCorrectTarget(processTabs("putstatic int " + filename + "." + globalVarName + "\n"));

                if(flushComment)
                {
                    ///////////flush comment after finish a construct
                    flushCommentCanvas();
                    ////////////////////////////////////////////////
                }
            }
        }
        
        void StoreLocalVariableInteger(int* errorExist, IdxPair entryLocation, int flushComment){
            if(!(*errorExist)){
                EntryAttributes varInfo = fromIdxPairReturnAttributes(entryLocation, 0);
                int localVariableNumber = varInfo.localVariableNumber;
                dumpConstructToCanvas(processTabs("istore " + std::to_string(localVariableNumber)+"\n"));

                if(flushComment)
                {
                    ///////////flush comment after finish a construct
                    flushCommentCanvas();
                    ////////////////////////////////////////////////
                }
            }
        }
        void StoreLocalVariableBoolean(int* errorExist, IdxPair entryLocation, int flushComment){
            if(!(*errorExist)){
                EntryAttributes varInfo = fromIdxPairReturnAttributes(entryLocation, 0);
                int localVariableNumber = varInfo.localVariableNumber;
                dumpConstructToCorrectTarget(processTabs("istore " + std::to_string(localVariableNumber)+"\n"));

                if(flushComment)
                {
                    ///////////flush comment after finish a construct
                    flushCommentCanvas();
                    ////////////////////////////////////////////////
                }
            }
        }

        /////////////////No need to flush comments for load and operators, because they are in RHS
        //these values needs to be written to canvas because we are unsure whether they needs to be written e.g. when delcaration to global variable
        void LoadGlobalVarInt(int* errorExist, IdxPair globalVariableIdx){
            if(!(*errorExist)){
                std::string globalVarName = globalVariableIdx.varName;
                dumpConstructToCanvas(processTabs("getstatic int " + filename + "." + globalVarName + "\n"));
            }
        }
        void LoadGlobalVarBoolean(int* errorExist, IdxPair globalVariableIdx){
            if(!(*errorExist)){
                std::string globalVarName = globalVariableIdx.varName;
                dumpConstructToCanvas(processTabs("getstatic int " + filename + "." + globalVarName + "\n"));
            }
        }
        void LoadConstantBoolean(int* errorExist, int value){
            if(!(*errorExist)){
                if(!value){
                    dumpConstructToCanvas(processTabs("iconst_0\n"));
                }else{
                    dumpConstructToCanvas(processTabs("iconst_1\n"));
                }
            }
        }
        void LoadConstantInteger(int* errorExist, int value){
            if(!(*errorExist)){
                if(!value){
                    dumpConstructToCanvas(processTabs("sipush "+ std::to_string(value) + "\n"));
                }else{
                    dumpConstructToCanvas(processTabs("sipush "+std::to_string(value)+ "\n"));
                }
            }
        }
        void LoadConstantString(int* errorExist, const char* value){
            if(!(*errorExist)){
                std::string originalString = value;
                std::string targetString = "";
                for(int i = 0; i < originalString.size(); i++){
                    if(originalString[i] == '\"'){
                        targetString += "\\";
                    }
                    targetString+=originalString[i];
                }
                std::string goalSentence = "ldc ";
                goalSentence += "\"";
                goalSentence += targetString;
                goalSentence += "\"";
                goalSentence += "\n";
                dumpConstructToCanvas(processTabs(goalSentence));
            }
        }
        void LoadLocalVariableInteger(int* errorExist, IdxPair entryLocation){
            if(!(*errorExist)){
                EntryAttributes varInfo = fromIdxPairReturnAttributes(entryLocation, 0);
                int localVariableNumber = varInfo.localVariableNumber;
                dumpConstructToCanvas(processTabs("iload " + std::to_string(localVariableNumber) + "\n"));
            }
        }
        void LoadLocalVariableBoolean(int* errorExist, IdxPair entryLocation){
            if(!(*errorExist)){
                EntryAttributes varInfo = fromIdxPairReturnAttributes(entryLocation, 0);
                int localVariableNumber = varInfo.localVariableNumber;
                dumpConstructToCanvas(processTabs("iload " + std::to_string(localVariableNumber) + "\n"));
            }
        }
        //operator operations
        //they use letter instead of symbol due to how I implement in YACC
        void ArithmeticOperators(int* errorExist, const char* symbol){
            if(!(*errorExist)){
                std::string symbolStr = symbol;
                if(symbolStr == "ADDITION"){
                    dumpConstructToCanvas(processTabs("iadd\n"));
                }else if(symbolStr == "SUBTRACTION"){
                    dumpConstructToCanvas(processTabs("isub\n"));
                }else if(symbolStr == "MULTIPLICATION"){
                    dumpConstructToCanvas(processTabs("imul\n"));
                }else if(symbolStr == "DIVISION"){
                    dumpConstructToCanvas(processTabs("idiv\n"));
                }else if(symbolStr == "REMAINDER"){
                    dumpConstructToCanvas(processTabs("irem\n"));
                }else if(symbolStr == "UMINUS"){
                    dumpConstructToCanvas(processTabs("ineg\n"));
                }else{
                    printf("###Code maker error: should not enter here in arithmetic operator: %s\n", symbol);
                    *errorExist = 1;
                    return;
                }
            }
        }
        void RelationalOperators(int* errorExist, const char* symbol){
            //since all the operation is only int and bool, we can comfortly use subtraction
            if(!(*errorExist)){
                dumpConstructToCanvas(processTabs("isub\n"));
                std::string symbolStr = symbol;
                std::string branchCorrect = "RelOpCorrect_" + std::to_string(returnAndIncreaseBranchCode());
                std::string branchGather = "RelOpGather_"+std::to_string(returnAndIncreaseBranchCode());
                if(symbolStr == "="){
                    dumpConstructToCanvas(processTabs("ifeq " + branchCorrect +" \n"));
                }else if(symbolStr == "not="){
                    dumpConstructToCanvas(processTabs("ifne " + branchCorrect +" \n"));
                }else if(symbolStr == "<="){
                    dumpConstructToCanvas(processTabs("ifle " + branchCorrect +" \n"));
                }else if(symbolStr == "<"){
                    dumpConstructToCanvas(processTabs("iflt " + branchCorrect +" \n"));
                }else if(symbolStr == ">"){
                    dumpConstructToCanvas(processTabs("ifgt " + branchCorrect +" \n"));
                }else if(symbolStr == ">="){
                    dumpConstructToCanvas(processTabs("ifge " + branchCorrect +" \n"));
                }else{
                    printf("###Code maker error: should not enter here in relational operator: %s\n", symbol);
                    *errorExist = 1;
                    return;
                }
                //wrong branch
                dumpConstructToCanvas(processTabs("iconst_0\n"));
                dumpConstructToCanvas(processTabs("goto " + branchGather + "\n"));
                //correct branch
                BranchingAssist(branchCorrect);
                dumpConstructToCanvas(processTabs("iconst_1\n"));
                //gather branch
                BranchingAssist(branchGather);
            }
        }
        void LogicalOperators(int* errorExist, const char* symbol){
            if(!(*errorExist)){
                std::string symbolStr = symbol;
                if(symbolStr == "and"){
                    dumpConstructToCanvas(processTabs("iand\n"));
                }else if(symbolStr == "or"){
                    dumpConstructToCanvas(processTabs("ior\n"));
                }else if(symbolStr == "not"){
                    dumpConstructToCanvas(processTabs("sipush 1\n"));
                    dumpConstructToCanvas(processTabs("ixor\n"));
                }else{
                    printf("###Code maker error: should not enter here in logical operator: %s", symbol);
                    *errorExist = 1;
                    return;
                }
            }
        }

        //going to be used for expression without assignment, since nothing will pop it from the stack
        void RemoveTopOperandStack(int* errorExist){
            if(!(*errorExist)){
                dumpConstructToCorrectTarget(processTabs("pop\n"));
            }
        }
        //main function related
        void InitializeMain(int* errorExist){
            if(!(*errorExist)){
                mainProgram += processTabs("method public static void main(java.lang.String[])\n");
                mainProgram += processTabs("max_stack " + std::to_string(defaultMaxStack) + "\n");
                mainProgram += processTabs("max_locals " + std::to_string(defaultMaxLocal) + "\n");
                mainProgram += processTabs("{\n");
                increaseTabs();
            }
        }
        void FinishMain(int* errorExist){
            if(!(*errorExist)){
                //if there is global exit exists
                if(globalExitExists){
                    mainProgram += mainExitBranch + ": \n";
                    mainProgram += processTabs("nop\n");
                }
                mainProgram += processTabs("return\n");
                decreaseTabs();
                mainProgram += processTabs("}\n");
            }
        }
        //dump the whole program into a file
        void DumpFile(int* errorExist){
            if(!(*errorExist)){
                FinishMain(errorExist);
                std::string tempStr = filename;
                std::string filenameStr = tempStr;

                //create an output file
                std::fstream classFile;
                classFile.open("jasmOutputs/"+ filenameStr + ".jasm", std::ios::out);
                classFile << "class " << tempStr << "\n" << "{\n"; 
                //put each global section into the class file

                // for(int i = 0; i < declarationSectionStacks.size(); i++){
                //     classFile << declarationSectionStacks[i].contents;
                // }

                // new approach: dump the variable declaration first, then the functions
                for(int i = 0; i < declarationSectionStacks.size(); i++){
                    if(declarationSectionStacks[i].gdt == GLOBALVAR){
                        classFile << declarationSectionStacks[i].contents;
                    }
                }
                for(int i = 0; i < declarationSectionStacks.size(); i++){
                    if(declarationSectionStacks[i].gdt == FUNCTIONPROCEDURE){
                        classFile << declarationSectionStacks[i].contents;
                    }
                }
                //put the main section
                classFile << mainProgram << "\n";
                classFile << "}\n";
                classFile.close();
            }else{
                std::cout << "Code not generated due to meet syntax error or unable to be expressed construct\n";
                exit(1);
            }
        }

        void WriteCommentLine(int* errorExist, const char* stmt){
            if(!(*errorExist)){
                std::string strstmt = stmt;
                if(writeCommentToJasm){
                    commentCanvas += stmt;
                }
            }
        }

        // in case of a line is only expression : 12 + 13 only, then pop this expression
        void PopExpression(int* errorExist){
            if(!(*errorExist)){
                dumpConstructToCorrectTarget(processTabs("pop\n"));
            }
        }

        // this is because if branch is empty and two branch are together, example:
        // a:
        // b:
        // when using jasm it will output error, so between a and b should insert nop
        void NoopEmptyBranching(){
            dumpConstructToCorrectTarget(processTabs("nop\n"));
        }

        // after every branching add noop
        void BranchingAssist(std::string branchName){
            dumpConstructToCorrectTarget(branchName + ": \n");
            NoopEmptyBranching();
        }
        ////////////////////////Printing helpers
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
};
#endif