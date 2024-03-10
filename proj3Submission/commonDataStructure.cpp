#include "commonDataStructure.h"
int debugMode = 0; //set 1 to print the error message of symbol table, set 0 to not print
int linenum = 1; //current line number, communicate between yacc and lex
int doDumpLastEntryDuringPop = 0; //during pop back of scope, dump the last scope entry before pop back
int doInsertInfoAndDumpLastEntryDuringPopProject3 = 1; //same as previous, but follow project 3 format (dump last and insert information)

//plus point feature of project 2, it is that symbolTable can store value if it is not const
//now set to false
int symbolTableStoreValue = 0;  //whether symbol table store value, currently there is problem, that is if:
                                //    - in if, whether it is entered or not, the value will be updated
                                //      in function, whether it is called or not, the value will be updated
                                //      in loop and for, whether it is called or not, the value will be updated
int putCanPrintExpression = 0;  //put can print the expression
int getCanScanfIdentifier = 0;  //get can scanf identifier (and store the value in symbol table if enabled) if getCanScanfIdenifier is on
int constIntExprCanCheckIndexValidity = 1; //when expression contains array access index that access an array is const, it checks for index validity

int errorExist = 0;//whether error exist in the middle when writing code, in which code writing will stop

int writeCommentToJasm = 0; // This might cause problem, when writing / (/*12 / 3*/)