res: lex.yy.c libst.so libstapi.so
	gcc -o res lex.yy.c -lfl -L. -lst -lstapi

lex.yy.c:
	flex B10915008_Proj1.l

libst.so:
	g++ -fpic -shared symbolTable.cpp -o libst.so

libstapi.so: libst.so
	g++ -fpic -shared symbolTableAPI.cpp -L. -lst -o libstapi.so
