#include "commonDataStructure.h"
int debugMode = 0; //set 1 to print the error message of symbol table, set 0 to not print
int linenum = 1; //current line number, communicate between yacc and lex
int doDumpLastEntryDuringPop = 1; //during pop back of scope, dump the last scope entry before pop back

//plus point feature
int symbolTableStoreValue = 1;  //whether symbol table store value, currently there is problem, that is if:
                                //    - in if, whether it is entered or not, the value will be updated
                                //      in function, whether it is called or not, the value will be updated
                                //      in loop and for, whether it is called or not, the value will be updated
int putCanPrintExpression = 1;  //put can print the expression
int getCanScanfIdentifier = 1;  //get can scanf identifier (and store the value in symbol table if enabled) if getCanScanfIdenifier is on
int constIntExprCanCheckIndexValidity = 1; //when expression contains array access index that access an array is const, it checks for index validity