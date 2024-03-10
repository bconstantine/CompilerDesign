Do Lexical Analysis for the Turing Programming language

# How to launch the program?

Prerequisite: 
Make sure Flex and gcc is installed inside device

Make sure these few files exist: 
- B10915008_Proj1.l
- symbolTable.cpp, symbolTable.h
- symbolTableAPI.cpp, symbolTable.h
- Makefile

How to launch? ($ means enter in terminal)
1.  $ make -B
2. Tell the terminal where our libst.so placed, so that we can link the library when launching exe
    $ sudo find / -name libst.so
   or
    $ pwd
3. After you get the output from 2, place the output inside here:
    $ LD_LIBRARY_PATH= {path printed in 2}
   Example: 
    $ LD_LIBRARY_PATH=/home/B10915008/CompilerProject/proj1Submission/
    $ LD_LIBRARY_PATH=/media/sf_Compiler/CompilerProject/proj1/
4.  $ export LD_LIBRARY_PATH
5. Launch the file, 2 options are available: 
   Inputting from keyboard, recommended to be one line at a time to avoid confusion:
    $ ./res 
    $ Ctrl+D for ending input
   Inputting from file: 
    $ ./res {path to file from the pwd}