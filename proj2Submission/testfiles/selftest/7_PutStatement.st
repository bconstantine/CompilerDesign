%Put statement related

%most of put is already used in another st files, so the test won't be much

procedure voidProc()
    return
end voidProc

var testArray : array 1 .. 100 of int
const testConst : real := 100.0
var a := 100.0
%7.b these put statement in the first section will succeed, the next part will fail
put 10*100
put 10 - 1.0
put "A lot of cases need to be considered"
put true

put (voidProc())

%7.a these put statement will fail
put testArray
put 10 / 0
put 10 < true
put not 10
put - false and 10

%7.c
put testConst
put 100.0
put testConst % 100.0

%7.d
put 100.0 + a
