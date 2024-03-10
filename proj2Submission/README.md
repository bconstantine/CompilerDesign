Do Lexical Analysis + Syntax Analysis for the Turing Programming language. See Proj2.pdf for instruction detail.

# How to launch the program?

Prerequisite: 
Make sure Flex yacc and gcc is installed inside device

Make sure these few files exist: 
- B10915008_Proj2.l
- B10915008_Proj2.y
- symbolTableFix.cpp, symbolTableFix.h (Symbol table implemented in CPP)
- symbolTableAPIFix.cpp, symbolTableAPIFix.h (Symbol table C and CPP bridge, called in yacc and lex)
- commonDataStructure.cpp commonDataStructure.h (Data Structure used together in all programs)
- Makefile

Supplementary Files
- testfiles/ folder (available test files, with comment details which part of feature is tested in handledCase.txt)
- handledCase.txt (specification of each feature and plus point implemented)
- ChangesToScanner.txt (the changes that I made to the scanner from project 1)


Notes:
- in B10915008_Proj2.y, Opt_Print can be set to 1 or 0 whether to print tracing
- in B10915008_Proj2.l, Opt_L can be set to 1 or 0 whether to print token
- in commonDataStructure.cpp, there are flag that can turn on or off debug features or feature for plus points, see file comment for further details

How to launch? ($ means enter in terminal)
1.  $ make -B
2. Tell the terminal where our libst.so placed, so that we can link the library when launching exe
    ```bash
    $ sudo find / -name libst.so
    #or usually
    $ pwd
3. After you get the output from 2, place 
    ```
    the output inside here:
    $ LD_LIBRARY_PATH= {path printed in 2}
   Example: 
    $ LD_LIBRARY_PATH=/home/B10915008/proj2Submission/
4.  ```bash$ export LD_LIBRARY_PATH```
5. Launch the file 
    Inputting from file: 
    ```bash$ ./res {path to file from the pwd}```

Notes:
- Step 2, 3, 4 can't be implemented in makefile because each part of makefile is executed in different shell