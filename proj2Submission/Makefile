res: lex.yy.c y.tab.c libst.so libstapi.so libcommon.so
	gcc -o res lex.yy.c y.tab.c -lfl -L. -lst -lstapi -lcommon
	echo "!!!!NEED TO EXPORT LD_LIBRARY_PATH, SEE README_IMPORTANT.md FIRST!!!!"

lex.yy.c: y.tab.c B10915008_Proj2.l
	flex B10915008_Proj2.l

y.tab.c y.tab.h: B10915008_Proj2.y
	yacc -d -v B10915008_Proj2.y

libcommon.so:
	g++ -fpic -shared commonDataStructure.cpp -o libcommon.so

libst.so: libcommon.so
	g++ -fpic -shared symbolTableFix.cpp -L. -lcommon -o libst.so

libstapi.so: libst.so libcommon.so
	g++ -fpic -shared symbolTableAPIFix.cpp -L. -lst -lcommon -o libstapi.so

clean: 
	rm libstapi.so libst.so libcommon.so y.tab.h y.tab.c lex.yy.c res y.output