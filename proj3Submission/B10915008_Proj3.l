%{
#include "stdio.h"
#include "stdlib.h"
#include "symbolTableAPIFix.h" //symbol table  in C++ plus Data Structure implemented for Yacc and Lex altogether, especially for yylval purposes
#include "y.tab.h" //yacc token definitions
#include "string.h"
#include "codeMakerAPI.h"
#define MAX_LINE_LENG 256 //maximum char in a line (and also string)
#define LIST strcat(buf,yytext) //append keyword into buf
/*stringify a token: https://stackoverflow.com/questions/12844117/printing-defined-constants*/
#define LISTNONCOMMENT strcat(nonCommentBuf,yytext)
#define token(t) {LIST; LISTNONCOMMENT; if(Opt_L) printf("<%s>\n", #t); return (t);} //general token
#define tokenInteger(t,i) {LIST; LISTNONCOMMENT; if(Opt_L) printf("<%s:%d>\n", #t,i); return INTCONST;} //int token
#define tokenReal(t, r) {LIST; LISTNONCOMMENT; if(Opt_L) printf("<%s:%lf>\n", #t, r); return REALCONST;} //double token
#define tokenString(t,s) {if(Opt_L) printf("<%s:%s>\n", #t,s); return STRINGCONST;} //note I remove the "LIST;" since I have unput() in String operation
#define tokenIdentifier(t, s) {LIST; LISTNONCOMMENT; if(Opt_L) printf("<%s:%s>\n", #t ,s); return IDENTIFIER;} //token for identifier
#define singleLineCommentStart strcat(buf, "//") //begin single line comment, for append to buf
#define multiLineCommentStart strcat(buf, "/*") //begin multiline comment, for append to buf
#define multiLineCommentFinished strcat(buf, "*/") //finish multiline comment, for append to buf
#define LISTSTR strcat(tempStrBuf, yytext)
#define NEXTTOKENPLUSLINENUM {if(linenumState == 2){linenum = LexLineNum;linenumState = 0;}else if(linenumState == 1){linenumState = 2;}}
#define PREPARENEXTTOKENPLUSLINENUM {if(linenumState == 1){linenumState = 2;}}
#define MODIFYLINENUMREGULAR {if(linenumState == 0) {linenumState = 1;}else if(linenumState == 1){linenumState = 1;} else if(linenumState == 2){linenumState = 1; linenum = LexLineNum;} LexLineNum += 1;}
#define MODIFYLINENUMCOMMENT {if(linenumState == 0) {linenumState = 1;}LexLineNum++;}
#define PRINTPROGRAMTOJAVA(x) {char forWritingSentence[512]; sprintf(forWritingSentence, "/*%d: %s*/\n", LexLineNum, x) ; writeCommentLine(&errorExist, forWritingSentence); x[0] = '\0';}

char buf[MAX_LINE_LENG]; //for printing every line command
char nonCommentBuf[MAX_LINE_LENG]; // for printing non comment program of st to java as comment
int Opt_L = 0; // Decide whether to print the printf or not

char tempStrBuf[256];

//St Documentation: https://archive.org/details/technicalreportc153univ/page/n1/mode/1up

extern YYSTYPE yylval;
int LexLineNum = 1;
int linenumState = 0;
/*Linenum sync method, a little bit complicated (this is because lex reads a token, it reads a false token and just then the line is appended)
See ChangesToScanner.txt for full details
*/

%}
    /*Identifiers, Numerical
    Since inside the PDF it is said numerical is basically digits, and doesn't specify can't
    start with 0, so I have the first digit to be 0 valid
    Note for number, I won't include sign in front of it, so -100 will only have NumInt as 100*/
NUMREAL [0-9]+"."([0-9])+ 
NUMINT [0-9]+
    /*Regular identifiers*/
IDENTIFIERS [a-zA-Z_][a-zA-Z0-9_]*
    /*Identifier that contains number in a word, must be handled to prevent error e.g. array11*/

    /*For String, I convert two state:
    STRING_STATE: Normal String State
    CAUTIOUS_STRING: I met closing quotation, need to check whether it is indeed closing or just escape char for quotation mark*/
%x MULTILINE_COMMENT
%x SINGLELINE_COMMENT
%x STRING_STATE
%x CAUTIOUS_STRING

%%
    /*Comment, when comment begin, make sure to print the rest of the line
      CAUTION: DO NOT LIST THE COMMENT FOR EVERY CLOSING SYMBOL
      Since we need to use %} I use the % for the multiline comment which will read the next letter*/
"{%"                        {
                                //if non comment non empty, print that first into the java
                                if(strlen(nonCommentBuf) != 0){
                                    PRINTPROGRAMTOJAVA(nonCommentBuf);
                                }

                                multiLineCommentStart; 
                                BEGIN MULTILINE_COMMENT;
                            }
<MULTILINE_COMMENT>\n       {
                                LIST;
                                if (Opt_L){
                                    printf("%d: %s", LexLineNum, buf);
                                }
                                //linenum++;
                                MODIFYLINENUMCOMMENT;
                                buf[0] = '\0';
                            }
<MULTILINE_COMMENT>"%}"     {
                                //end of the comment
                                multiLineCommentFinished;
                                //CAUTION: DONOT PRINT FIRST, THERE MAY BE FOLLOW UP STATEMENTS
                                BEGIN INITIAL;
                            }
<MULTILINE_COMMENT>.        {
                                LIST;
                            }
"%"                         {
                                //if non comment non empty, print that first into the java
                                if(strlen(nonCommentBuf) != 0){
                                    PRINTPROGRAMTOJAVA(nonCommentBuf);
                                }
                                singleLineCommentStart; 
                                BEGIN SINGLELINE_COMMENT;
                            }
<SINGLELINE_COMMENT>\n      {
                                //there is no LIST because \n is not part of the comment
                                //instead, I insert \n manually on the printf
                                if (Opt_L) printf("%d: %s\n", LexLineNum, buf);
                                //linenum++;
                                MODIFYLINENUMCOMMENT;
                                buf[0] = '\0';
                                BEGIN INITIAL;
                            }
<SINGLELINE_COMMENT><<EOF>> {
                                if (Opt_L) printf("%d: %s\n", LexLineNum, buf);
                                //linenum++;
                                MODIFYLINENUMCOMMENT;
                                buf[0] = '\0';
                                BEGIN INITIAL;
                            }
<SINGLELINE_COMMENT>.       {LIST;}

    /*Keywords, Note that:
    it should be above identifiers
    Note that these few case will be handled well due to priority in lex is matching the longest string, then earliest rule: 
        array11 (valid identifier)
        arraybegin (valid identifier)
    */
"array"                     {NEXTTOKENPLUSLINENUM; token(ARRAY);PREPARENEXTTOKENPLUSLINENUM}
"begin"                     {NEXTTOKENPLUSLINENUM; token(BEGINKWD);PREPARENEXTTOKENPLUSLINENUM}
"bool"                      {NEXTTOKENPLUSLINENUM; token(BOOL);PREPARENEXTTOKENPLUSLINENUM}
"char"                      {NEXTTOKENPLUSLINENUM; token(CHAR);PREPARENEXTTOKENPLUSLINENUM}
"const"                     {NEXTTOKENPLUSLINENUM; token(CONST);PREPARENEXTTOKENPLUSLINENUM}
"decreasing"                {NEXTTOKENPLUSLINENUM; token(DECREASING);PREPARENEXTTOKENPLUSLINENUM}
"default"                   {NEXTTOKENPLUSLINENUM; token(DEFAULT);PREPARENEXTTOKENPLUSLINENUM}
"do"                        {NEXTTOKENPLUSLINENUM; token(DO);PREPARENEXTTOKENPLUSLINENUM}
"else"                      {NEXTTOKENPLUSLINENUM; token(ELSE);PREPARENEXTTOKENPLUSLINENUM}
"end"                       {NEXTTOKENPLUSLINENUM; token(END);PREPARENEXTTOKENPLUSLINENUM}
"exit"                      {NEXTTOKENPLUSLINENUM; token(EXIT);PREPARENEXTTOKENPLUSLINENUM}
"false"                     {NEXTTOKENPLUSLINENUM; token(FALSE);PREPARENEXTTOKENPLUSLINENUM} 
"for"                       {NEXTTOKENPLUSLINENUM; token(FOR);PREPARENEXTTOKENPLUSLINENUM}
"function"                  {NEXTTOKENPLUSLINENUM; token(FUNCTION);PREPARENEXTTOKENPLUSLINENUM}
"get"                       {NEXTTOKENPLUSLINENUM; token(GET);PREPARENEXTTOKENPLUSLINENUM}
"if"                        {NEXTTOKENPLUSLINENUM; token(IF);PREPARENEXTTOKENPLUSLINENUM}
"int"                       {NEXTTOKENPLUSLINENUM; token(INT);PREPARENEXTTOKENPLUSLINENUM}
"loop"                      {NEXTTOKENPLUSLINENUM; token(LOOP);PREPARENEXTTOKENPLUSLINENUM}
"of"                        {NEXTTOKENPLUSLINENUM; token(OF);PREPARENEXTTOKENPLUSLINENUM}
"put"                       {NEXTTOKENPLUSLINENUM; token(PUT);PREPARENEXTTOKENPLUSLINENUM}
"procedure"                 {NEXTTOKENPLUSLINENUM; token(PROCEDURE);PREPARENEXTTOKENPLUSLINENUM}
"real"                      {NEXTTOKENPLUSLINENUM; token(REAL);PREPARENEXTTOKENPLUSLINENUM}
"result"                    {NEXTTOKENPLUSLINENUM; token(RESULT);PREPARENEXTTOKENPLUSLINENUM}
"return"                    {NEXTTOKENPLUSLINENUM; token(RETURN);PREPARENEXTTOKENPLUSLINENUM}
"skip"                      {NEXTTOKENPLUSLINENUM; token(SKIP);PREPARENEXTTOKENPLUSLINENUM}
"string"                    {NEXTTOKENPLUSLINENUM; token(STRING);PREPARENEXTTOKENPLUSLINENUM}
"then"                      {NEXTTOKENPLUSLINENUM; token(THEN);PREPARENEXTTOKENPLUSLINENUM}
"true"                      {NEXTTOKENPLUSLINENUM; token(TRUE);PREPARENEXTTOKENPLUSLINENUM}  
"var"                       {NEXTTOKENPLUSLINENUM; token(VAR);PREPARENEXTTOKENPLUSLINENUM}
"when"                      {NEXTTOKENPLUSLINENUM; token(WHEN);PREPARENEXTTOKENPLUSLINENUM}

    /*Operators, note that 
    not= should above not and =.
    <= >= should above < and > and = respectively 
    */
"+"                         {NEXTTOKENPLUSLINENUM; token(ADDITION);PREPARENEXTTOKENPLUSLINENUM}
"-"                         {NEXTTOKENPLUSLINENUM; token(SUBTRACTION);PREPARENEXTTOKENPLUSLINENUM}
"*"                         {NEXTTOKENPLUSLINENUM; token(MULTIPLICATION);PREPARENEXTTOKENPLUSLINENUM}
"/"                         {NEXTTOKENPLUSLINENUM; token(DIVISION);PREPARENEXTTOKENPLUSLINENUM}
"mod"                       {NEXTTOKENPLUSLINENUM; token(REMAINDER);PREPARENEXTTOKENPLUSLINENUM}
":="                        {NEXTTOKENPLUSLINENUM; token(ASSIGNMENT);PREPARENEXTTOKENPLUSLINENUM}
"not="                      {NEXTTOKENPLUSLINENUM; token(RELATIONALNOT);PREPARENEXTTOKENPLUSLINENUM}
"<="                        {NEXTTOKENPLUSLINENUM; token(RELATIONALLE);PREPARENEXTTOKENPLUSLINENUM}
"<"                         {NEXTTOKENPLUSLINENUM; token(RELATIONALLT);PREPARENEXTTOKENPLUSLINENUM}
">="                        {NEXTTOKENPLUSLINENUM; token(RELATIONALGE);PREPARENEXTTOKENPLUSLINENUM}
">"                         {NEXTTOKENPLUSLINENUM; token(RELATIONALGT);PREPARENEXTTOKENPLUSLINENUM}
"="                         {NEXTTOKENPLUSLINENUM; token(RELATIONALEQ);PREPARENEXTTOKENPLUSLINENUM}
"and"                       {NEXTTOKENPLUSLINENUM; token(LOGICALAND);PREPARENEXTTOKENPLUSLINENUM}
"or"                        {NEXTTOKENPLUSLINENUM; token(LOGICALOR);PREPARENEXTTOKENPLUSLINENUM}
"not"                       {NEXTTOKENPLUSLINENUM; token(LOGICALNOT);PREPARENEXTTOKENPLUSLINENUM}
    /*Numbers. Note that:
    NUMREAL should above numint
    NUMREAL should above . (".") dot identifier*/

{NUMREAL}                   {
                                NEXTTOKENPLUSLINENUM; 
                                sscanf(yytext, "%lf", &yylval.doubleContent);
                                tokenReal(REALCONST, yylval.doubleContent);
                                PREPARENEXTTOKENPLUSLINENUM
                            }
{NUMINT}                    {
                                NEXTTOKENPLUSLINENUM; 
                                sscanf(yytext, "%d", &yylval.intContent);
                                tokenInteger(INTCONST, yylval.intContent);
                                PREPARENEXTTOKENPLUSLINENUM
                            }
    
    /*Identifiers, since underscore is not a special symbol, it is just need to be below
    keywords. Symbol table implemented inside SymbolTableAPI.h */
{IDENTIFIERS}               {
                                NEXTTOKENPLUSLINENUM; 
                                struct IdxPair  res = lookupIndexFromLast(yytext, debugMode);
                                //put the name also in IDENTIFIERS, because the one who responsible for insertion is YACC
                                strcpy(res.varName, yytext);
                                yylval.idx = res;
                                tokenIdentifier(IDENTIFIER, yytext);
                                PREPARENEXTTOKENPLUSLINENUM;
                            }

    /*Strings, since quotation mark doesn't appear anywhere, so it is no problem placed here*/
\"                          {
                                LIST;
                                LISTNONCOMMENT; 
                                //resetting the string buffer, just in case
                                tempStrBuf[0] = '\0';
                                BEGIN STRING_STATE;
                            }
<STRING_STATE>\"            {LIST; LISTNONCOMMENT; BEGIN CAUTIOUS_STRING;}
<STRING_STATE>.             {LIST; LISTNONCOMMENT; LISTSTR;}
<STRING_STATE>\n            {
                                //Meet invalid case, no multiline string directly stop string operation
                                //and just begin initial
                                printf("String error on line %d, no closing quotation detected on string, newline met, string fail\n", linenum);
                                errorExist = 1;
                                unput(yytext[0]); // so that it will enter the newline on initial
                                BEGIN INITIAL;
                            }
<STRING_STATE><<EOF>>       {
                                //invalid string ending with EOF
                                printf("String error on line %d, no closing quotation detected on string, EOF met, string fail\n", linenum);
                                errorExist = 1;
                                //print the remaining buffer,
                                //note that the \n is manually added because string does not end with newline
                                if(Opt_L) printf("%d: %s\n", LexLineNum, buf);
                                //linenum++;
                                MODIFYLINENUMCOMMENT;
                                buf[0]='\0';
                                BEGIN INITIAL;
                            }
<CAUTIOUS_STRING>\"         {
                                //NEXTTOKENPLUSLINENUM; 
                                //if directly follows by quotation mark, it means it is still a string
                                LIST;
                                LISTNONCOMMENT; 
                                //append the String with just one quotatin
                                strcat(tempStrBuf, "\"");
                                //reset to normal string state
                                BEGIN STRING_STATE;
                            }
<CAUTIOUS_STRING><<EOF>>    {
                                NEXTTOKENPLUSLINENUM; 
                                //Implement if string at the end of file (no \n)
                                //Store string and reset strContent
                                strcpy(yylval.strContent, tempStrBuf);
                                tempStrBuf[0] = '\0';
                                

                                //do routine as in \n of initial if ending is "\n"
                                //Need to manually add \n because there is no \n after last string (i.e. EOF)
                                if(Opt_L) printf("%d: %s\n", LexLineNum, buf);

                                //print to java
                                if(strlen(nonCommentBuf) != 0){
                                    PRINTPROGRAMTOJAVA(nonCommentBuf);
                                }

                                //write to java program


                                //linenum++;
                                MODIFYLINENUMREGULAR;
                                buf[0]='\0';
                                BEGIN INITIAL;
                                tokenString(STRINGCONST, yylval.strContent);
                                PREPARENEXTTOKENPLUSLINENUM;
                            }
<CAUTIOUS_STRING>[^\"]      {
                                NEXTTOKENPLUSLINENUM; 
                                /*no longer a string
                                pack token and reset strContent*/
                                strcpy(yylval.strContent, tempStrBuf);
                                tempStrBuf[0] = '\0';

                                //return the token to INITIAL for normal state parsing
                                unput(yytext[0]);
                                BEGIN INITIAL;
                                tokenString(STRINGCONST, yylval.strContent);
                                PREPARENEXTTOKENPLUSLINENUM;
                            }

    /*Delimiters, should be below operators, comment and also numbers (otherwise might detect float)*/
"."                         {NEXTTOKENPLUSLINENUM; token(DOT);PREPARENEXTTOKENPLUSLINENUM}
","                         {NEXTTOKENPLUSLINENUM; token(COMMA);PREPARENEXTTOKENPLUSLINENUM}
":"                         {NEXTTOKENPLUSLINENUM; token(COLON);PREPARENEXTTOKENPLUSLINENUM}
";"                         {NEXTTOKENPLUSLINENUM; token(SEMICOLON);PREPARENEXTTOKENPLUSLINENUM}
"("                         {NEXTTOKENPLUSLINENUM; token(OPENPARENTHESES);PREPARENEXTTOKENPLUSLINENUM}
")"                         {NEXTTOKENPLUSLINENUM; token(CLOSINGPARENTHESES);PREPARENEXTTOKENPLUSLINENUM}
"["                         {NEXTTOKENPLUSLINENUM; token(OPENSQUAREBRACKET);PREPARENEXTTOKENPLUSLINENUM}
"]"                         {NEXTTOKENPLUSLINENUM; token(CLOSINGSQUAREBRACKET);PREPARENEXTTOKENPLUSLINENUM}
"{"                         {NEXTTOKENPLUSLINENUM; token(OPENBRACKET);PREPARENEXTTOKENPLUSLINENUM}
"}"                         {NEXTTOKENPLUSLINENUM; token(CLOSINGBRACKET);PREPARENEXTTOKENPLUSLINENUM}

    /*Print the whole line*/
\n                          {
                                //NEXTTOKENPLUSLINENUM; 
                                LIST;
                                if (Opt_L) printf("%d: %s", LexLineNum, buf);
                                if(strlen(nonCommentBuf) != 0){
                                    // no need to list nonComment buf because it already includes "\n"
                                    PRINTPROGRAMTOJAVA(nonCommentBuf);
                                }
                                //linenum++;
                                MODIFYLINENUMREGULAR;
                                buf[0] = '\0';
                            }
    /*Ignore space and tab, append what is inside yytext to buf, this means that space and tab
    are also inserted to the buf*/
[ \t]*                      { 
                            LIST;
                            LISTNONCOMMENT;}

<<EOF>>                     {
                                //cleaning up
                                //print the remaining line if buf is not empty
                                //guard just in case the file doesnt end with \n
                                //in this case, add the \n manually inside printf
                                if(buf[0] != '\0'){
                                    if (Opt_L) printf("%d: %s\n", LexLineNum, buf);
                                    //linenum++;
                                    MODIFYLINENUMREGULAR;
                                    buf[0] = '\0';
                                }
                                if(strlen(nonCommentBuf) != 0){
                                    PRINTPROGRAMTOJAVA(nonCommentBuf);
                                }

                                //EOF is already defined inside lex.yy.c
                                //must be returned, otherwise infinite loop
                                return EOF;
                            }
    /*Unrecognized character*/
.                           {
                                LIST;
                                LISTNONCOMMENT;
                                printf("%d:%s\n", LexLineNum, buf);
                                printf("bad character: %s on line %d\n",yytext, LexLineNum);
                                exit(-1);
                            }
%%

int yywrap() {
    return 1;
}