%Test case related to Function and Procedure%

procedure universalproc()
    {%This comment should 
    not affect%}put "Test case is a lot"
    skip %testing comment should not affect
    put "HERRO""IM LOCAL" {%This comment should not affect%}
    skip{%This comment should not 
    affect%}
end universalproc

function randomExitFunc(n: bool): bool
    exit when n
    put "this should be printed when n is false"
    skip
    exit
    put "this should not be printed at all"
    skip
    result true
end randomExitFunc

procedure randomExitProc(n: int)
    exit when n > 0
    put "this should be printed when n is false"
    skip
    exit
    put "this should not be printed at all"
    skip
end randomExitProc

function zint(a: int, c: bool): int
    {%This comment should not affect%}result a
end zint

function zbool(a: int, c: bool): bool
    result c
end zbool

function constintreturn():int
    result 10
end constintreturn

function constboolreturn():bool
    result false
end constboolreturn

function intFunc(): int
    result 100
end intFunc

function anotherintFunc(n:int): int
    result n
end anotherintFunc

procedure complexcalculation()
    put "Answer should be false: "
    put not 10+12*7 >= 2*5  %false
    skip
    put "Answer should be false: "
    put true and 10+12*7 < 2*5 %false
    skip
    put "Answer should be -2: "
    put 2+3-1*7
    skip
    put "Answer should be true: "
    put true = (not false) %true
    skip
    put "Answer should be true: "
    put true and 10+12*7 < 2*5 or (not false) %true
    skip
end complexcalculation

procedure justreturn()
    return
    put "This should not be printed"
    skip
end justreturn

begin
    const a:=10
    var b:=-10
    const c := true
    const d := false
    put "The answer should be 10: "
    put a
    skip
    put "The answer should be -10: "
    put b
    skip
    put "The answer should be true: "
    put c
    skip
    put "The answer should be false: "
    put d
    skip
    universalproc()
end

begin
    put "The answer should be 100: "
    put zint(100, false)
    skip
    put "The answer should be false: "
    put zbool(100, false)
    skip
    complexcalculation()
end

justreturn()

%1.a.b, 1.a.e this should result error except the last one
begin
    put "Result should be 10: "
    put constintreturn()
    skip
    put "Result should be false: "
    put constboolreturn()
    skip
    put "Result should be 20: "
    put 10 + constintreturn() %20
    skip
end
put "Result should be 100: "
put anotherintFunc(intFunc())
skip
put "Result should be 100: "
put (anotherintFunc(intFunc()))
skip
(universalproc())
skip
put "random exit func result should be not printing anything: "
randomExitProc(1)
skip
put "random exit func result should be printing only when n not 1: "
randomExitProc(0)
skip
put "random exit func result should be not printing anything, and result is false:  "
put randomExitFunc(true)
skip
put "random exit func result should be printing only when n is false, and result is false:  "
put randomExitFunc(false)
skip

