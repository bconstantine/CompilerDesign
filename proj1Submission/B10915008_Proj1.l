%{
#include "stdio.h"
#include "stdlib.h"
#include "symbolTableAPI.h" //symbol table implemented in C++
#define NIL -1 //defining what is NIL, used for symbolTable return
#define MAX_LINE_LENG 256 //maximum char in a line (and also string)
#define LIST strcat(buf,yytext) //append keyword into buf
#define token(t) {LIST; printf("<%s>\n",t);} //general token
#define tokenInteger(t,i) {LIST; printf("<%s:%d>\n",t,i);} //int token
#define tokenReal(t, r) {LIST; printf("<%s:%lf>\n", t, r);} //double token
#define tokenString(t,s) {printf("<%s:%s>\n",t,s);} //note I remove the "LIST;" since I have unput() in String operation
#define tokenIdentifier(t, s) {LIST; printf("<%s:%s>\n",t,s);} //token for identifier
#define singleLineCommentStart strcat(buf, "//") //begin single line comment, for append to BUF
#define multiLineCommentStart strcat(buf, "/*") //begin multiline comment, for append to buf
#define multiLineCommentFinished strcat(buf, "*/") //finish multiline comment, for append to buf
#define LISTSTR strcat(yylval.strContent, yytext)

int linenum = 1; //number of lines
char buf[MAX_LINE_LENG]; //for printing every line command
int Opt_L = 1; // Decide whether to print the printf or not

union tempType{
    char        strContent[256];
    int         intContent;
    double      doubleContent;
};
union tempType yylval; //fake yylval

int debugMode = 0; //for symbol table debug messages, set 0 for no output

//St Documentation: https://archive.org/details/technicalreportc153univ/page/n1/mode/1up
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
    STRING: Normal String State
    CAUTIOUS_STRING: I met closing quotation, need to check whether it is indeed closing or just escape char for quotation mark*/
%x MULTILINE_COMMENT
%x SINGLELINE_COMMENT
%x STRING
%x CAUTIOUS_STRING

%%
    /*Comment, when comment begin, make sure to print the rest of the line
      CAUTION: DO NOT LIST THE COMMENT FOR EVERY CLOSING SYMBOL
      Since we need to use %} I use the % for the multiline comment which will read the next letter*/
"{%"                        {
                                multiLineCommentStart; 
                                BEGIN MULTILINE_COMMENT;
                            }
<MULTILINE_COMMENT>\n       {
                                LIST;
                                if (Opt_L){
                                    printf("%d: %s", linenum, buf);
                                }
                                linenum++;
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
                                singleLineCommentStart; 
                                BEGIN SINGLELINE_COMMENT;
                            }
<SINGLELINE_COMMENT>\n      {
                                //there is no LIST because \n is not part of the comment
                                //instead, I insert \n manually on the printf
                                if (Opt_L) printf("%d: %s\n", linenum, buf);
                                linenum++;
                                buf[0] = '\0';
                                BEGIN INITIAL;
                            }
<SINGLELINE_COMMENT><<EOF>> {
                                if (Opt_L) printf("%d: %s\n", linenum, buf);
                                linenum++;
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
"array"                     {token("ARRAY")}
"begin"                     {token("BEGIN")}
"bool"                      {token("BOOL")}
"char"                      {token("CHAR")}
"const"                     {token("CONST")}
"decreasing"                {token("DECREASING")}
"default"                   {token("DEFAULT")}
"do"                        {token("DO")}
"else"                      {token("ELSE")}
"end"                       {token("END")}
"exit"                      {token("EXIT")}
"false"                     {token("FALSE")} 
"for"                       {token("FOR")}
"function"                  {token("FUNCTION")}
"get"                       {token("GET")}
"if"                        {token("IF")}
"int"                       {token("INT")}
"loop"                      {token("LOOP")}
"of"                        {token("OF")}
"put"                       {token("PUT")}
"procedure"                 {token("PROCEDURE")}
"real"                      {token("REAL")}
"result"                    {token("RESULT")}
"return"                    {token("RETURN")}
"skip"                      {token("SKIP")}
"string"                    {token("STRING")}
"then"                      {token("THEN")}
"true"                      {token("TRUE")}  
"var"                       {token("VAR")}
"when"                      {token("WHEN")}

    /*Operators, note that 
    not= should above not and =.
    <= >= should above < and > and = respectively 
    */
"+"                         {token("ADDITION")}
"-"                         {token("SUBTRACTION")}
"*"                         {token("MULTIPLICATION")}
"/"                         {token("DIVISION")}
"mod"                       {token("REMAINDER")}
":="                        {token("ASSIGNMENT")}
"not="                      {token("RELATIONALNOT")}
"<="                        {token("RELATIONALLE")}
"<"                         {token("RELATIONALLT")}
">="                        {token("RELATIONALGE")}
">"                         {token("RELATIONALGT")}
"="                         {token("RELATIONALEQ")}
"and"                       {token("LOGICALAND")}
"or"                        {token("LOGICALOR")}
"not"                       {token("LOGICALNOT")}
    /*Numbers. Note that:
    NUMREAL should above numint
    NUMREAL should above . (".") dot identifier*/

{NUMREAL}                   {
                                sscanf(yytext, "%lf", &yylval.doubleContent);
                                tokenReal("REAL", yylval.doubleContent)
                            }
{NUMINT}                    {
                                sscanf(yytext, "%d", &yylval.intContent);
                                tokenInteger("INT", yylval.intContent)
                            }
    
    /*Identifiers, since underscore is not a special symbol, it is just need to be below
    keywords. Symbol table implemented inside SymbolTableAPI.h */
{IDENTIFIERS}               {
                                if(lookup(yytext, debugMode) != NIL){
                                    if(debugMode) printf("Not inserting to symbol table, id already exist\n");
                                }else{
                                    int idx = insert(yytext, debugMode);
                                }
                                tokenIdentifier("ID", yytext)
                            }

    /*Strings, since quotation mark doesn't appear anywhere, so it is no problem placed here*/
\"                          {
                                LIST;
                                //resetting the string buffer, just in case
                                yylval.strContent[0] = '\0';
                                BEGIN STRING;
                            }
<STRING>\"                  {LIST; BEGIN CAUTIOUS_STRING;}
<STRING>.                   {LIST; LISTSTR;}
<STRING>\n                  {
                                //Meet invalid case, no multiline string directly stop string operation
                                //and just begin initial
                                printf("String error on line %d, no closing quotation detected on string, newline met, string fail\n", linenum);
                                unput(yytext[0]); // so that it will enter the newline on initial
                                BEGIN INITIAL;
                            }
<STRING><<EOF>>             {
                                //invalid string ending with EOF
                                printf("String error on line %d, no closing quotation detected on string, EOF met, string fail\n", linenum);
                                //print the remaining buffer,
                                //note that the \n is manually added because string does not end with newline
                                if(Opt_L) printf("%d: %s\n", linenum, buf);
                                linenum++;
                                buf[0]='\0';
                                BEGIN INITIAL;
                            }
<CAUTIOUS_STRING>\"         {
                                //if directly follows by quotation mark, it means it is still a string
                                LIST;
                                //append the String with just one quotatin
                                strcat(yylval.strContent, "\"");
                                //reset to normal string state
                                BEGIN STRING;
                            }
<CAUTIOUS_STRING><<EOF>>    {
                                //Implement if string at the end of file (no \n)
                                //Store string and reset strContent
                                tokenString("STRING", yylval.strContent);
                                yylval.strContent[0] = '\0';

                                //do routine as in \n of initial if ending is "\n"
                                //Need to manually add \n because there is no \n after last string (i.e. EOF)
                                if(Opt_L) printf("%d: %s\n", linenum, buf);
                                linenum++;
                                buf[0]='\0';
                                BEGIN INITIAL;
                            }
<CAUTIOUS_STRING>[^\"]      {
                                /*no longer a string
                                pack token and reset strContent*/
                                tokenString("STRING", yylval.strContent);
                                yylval.strContent[0] = '\0';

                                //return the token to INITIAL for normal state parsing
                                unput(yytext[0]);
                                BEGIN INITIAL;
                            }

    /*Delimiters, should be below operators, comment and also numbers (otherwise might detect float)*/
"."                         {token("dot")}
","                         {token("comma")}
":"                         {token("colon")}
";"                         {token("semicolon")}
"("                         {token("openParentheses")}
")"                         {token("closingParentheses")}
"["                         {token("openSquareBracket")}
"]"                         {token("closingSquareBracket")}
"{"                         {token("openBracket")}
"}"                         {token("closingBracket")}

    /*Print the whole line*/
\n                          {
                                LIST;
                                if (Opt_L) printf("%d: %s", linenum, buf);
                                linenum++;
                                buf[0] = '\0';
                            }
    /*Ignore space and tab, append what is inside yytext to buf, this means that space and tab
    are also inserted to the buf*/
[ \t]*                      {LIST;}

<<EOF>>                     {
                                //cleaning up
                                //print the remaining line if buf is not empty
                                //guard just in case the file doesnt end with \n
                                //in this case, add the \n manually inside printf
                                if(buf[0] != '\0'){
                                    if (Opt_L) printf("%d: %s\n", linenum, buf);
                                    linenum++;
                                    buf[0] = '\0';
                                }

                                //EOF is already defined inside lex.yy.c
                                //must be returned, otherwise infinite loop
                                return EOF;
                            }
    /*Unrecognized character*/
.                           {
                                LIST;
                                printf("%d:%s\n", linenum+1, buf);
                                printf("bad character:’%s’\n",yytext);
                                exit(-1);
                            }
%%
int main(int argc, char*argv[]){
    /*init symbol table*/
    create(debugMode);

    if (argc == 1)
    {
        /*Receive input from keyboard*/
        yylex();
    }else if(argc == 2) {
        /* open desired file, exit if no file found
        */
        FILE *myfile = fopen(argv[1], "r");
        if (!myfile) {
            printf("Bad error: File %s open fail\n", argv[1]); 
            exit(1);
        }

        /*Retrieve file  input*/
        yyin = myfile;
        yylex();

        /*Closing file*/
        fclose(myfile);
    }else{
        //invalid val
        printf("Invalid argc, ending the program\n");
        printf("After launching the exe, insert one string which is filename, or not insert anything for keyboard\n");
        exit(1);
    }

    /*Printing the leftover buffer*/
    fflush(yyout);
    /*Printing the symbol table*/
    dump(debugMode);

    /*Just for testing lookup*/
    //run on example.st
    //printf("Printing lookup content for id a,expected idx: %d\n", lookup("a", debugMode));
    //printf("Printing lookup content for id z, expected NIL: %d\n", lookup("z", debugMode));
    exit(0);
}

