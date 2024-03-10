res: lex.yy.c y.tab.c libst.so libstapi.so libcommon.so libcmaker.so libcmakerapi.so
	gcc -o res lex.yy.c y.tab.c -lfl -L. -lst -lstapi -lcommon -lcmaker -lcmakerapi
	echo "!!!!NEED TO EXPORT LD_LIBRARY_PATH, SEE README_IMPORTANT.md FIRST!!!!"

lex.yy.c: y.tab.c B10915008_Proj3.l
	flex B10915008_Proj3.l

y.tab.c y.tab.h: B10915008_Proj3.y
	yacc -d -v B10915008_Proj3.y

libcommon.so:
	g++ -fpic -shared commonDataStructure.cpp -o libcommon.so

libst.so: libcommon.so
	g++ -fpic -shared symbolTableFix.cpp -L. -lcommon -o libst.so

libstapi.so: libst.so libcommon.so
	g++ -fpic -shared symbolTableAPIFix.cpp -L. -lst -lcommon -o libstapi.so

libcmaker.so: libstapi.so libst.so libcommon.so
	g++ -fpic -shared codeMaker.cpp -L. -lst -lcommon -lstapi -o libcmaker.so
libcmakerapi.so: libstapi.so libst.so libcommon.so libcmaker.so
	g++ -fpic -shared codeMakerAPI.cpp -L. -lst -lcommon -lstapi -lcmaker -o libcmakerapi.so

clean: 
	rm libcmakerapi.so libcmaker.so libstapi.so libst.so libcommon.so y.tab.h y.tab.c lex.yy.c res y.output
	cd jasmOutputs && rm *.jasm
	cd jasmOutputs && rm *.class

#reference for passing argument to makefile: https://stackoverflow.com/questions/2214575/passing-arguments-to-make-run
#example: make runOut ARG="HelloWorld.st"
#note that input is filename, including its directory and its extension
#output will be in jasm
runOut:
	./res $(ARG)

#example: make fastDebug ARG="HelloWorld"
#note that input must be located in testfiles/ and have extension of .st!
#input is not including file directory and extension
fastDebug:
	./res testfiles/project3_selftest/$(ARG).st
	cd jasmOutputs && ./javaa $(ARG).jasm
	cd jasmOutputs && java $(ARG)
