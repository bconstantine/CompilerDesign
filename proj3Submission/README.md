Do Lexical Analysis + Syntax Analysis + Java Byte Code Generation for the Turing language. See Proj3.pdf for instruction detail.

# How to launch the program?

Prerequisite: 
Make sure Flex yacc and gcc is installed inside device

Make sure these few files exist: 
- B10915008_Proj3.l
- B10915008_Proj3.y
- symbolTableFix.cpp, symbolTableFix.h (Symbol table implemented in CPP)
- symbolTableAPIFix.cpp, symbolTableAPIFix.h (Symbol table C and CPP bridge, called in yacc and lex)
- commonDataStructure.cpp commonDataStructure.h (Data Structure used together in all programs)
- codeMaker.h codeMaker.cpp (Code generation implemented in CPP)
- codeMakerAPIFix.cpp, codeMakerAPIFix.h (Code Generation C and CPP bridge, called in yacc and lex)
- Makefile
- jasmOutputs/ (the output jasm will be by default pasted here)
- javaa file in working directory

Supplementary Files
- testfiles/ folder (available test files, with comment details which part of feature is tested in handledCase.txt)
- ChangesToParser.txt (the changes that I made to the scanner from project 2)


Notes:
- in B10915008_Proj3.y, Opt_Print can be set to 1 or 0 whether to print tracing
- in B10915008_Proj3.l, Opt_L can be set to 1 or 0 whether to print token
- in commonDataStructure.cpp, there are flag that can turn on or off debug features or feature for plus points, see file comment for further details
- Except a filename uses name beginning with number, the name of the class and the file will be the same with the name of the file. If name of the file begins with number, output class and jasm will be named randomName
- filename should not have two dot (e.g. hi.2.st)
- The program is implemented in static scoping, refer and run testfiles/project3_selftest/staticDynamicCheck.st for clear result
- To do fast debugging, use make fastDebug ARG="insert_filename_here_without_st" and put the file inside testfiles/project3_selftest/ (e.g. to run testfiles/project3_selftest/HelloWorld.st, use ARG="HelloWorld")
- Comment of original .st program is not included inside the .jasm file because it might give problem when the original program uses / (e.g. /* 12/5 */ in jasm has bug)
- in jasm, every branching is followed by a nop, this is to prevent syntax error bug in javaa
    java disallows: 
        branch:
        anotherBranch:
    structure
- in jasm, to prevent the error of function o

How to launch? ($ means enter in terminal)
1.  ```bash $ make -B```
2. Tell the terminal where our libst.so placed, so that we can link the library when launching exe
    ```bash
        $ sudo find / -name libst.so
        #or usually use pwd
        $ pwd
    ```
3. After you get the output from 2, place the output inside here:
    ```bash
        $ LD_LIBRARY_PATH= {path printed in 2}
        #Example: 
        $ LD_LIBRARY_PATH=/home/B10915008/proj3Submission/
    ```
4.  
    ```bash $ export LD_LIBRARY_PATH```
5. Launch the file
    ```bash
    #Inputting from file: 
    $ ./res {path to file from the pwd}
    $ cd jasmOutputs
    $ .javaa {path to file from jasmOutputs dir}
    $ java {filename, without .st or .jasm}
    #Or, for fast launch/debugging
    $ make fastDebug ARG={filename inside testfiles/project3_selftest/}
    ```

Notes:
- Step 2, 3, 4 can't be implemented in makefile because each part of makefile is executed in different shell