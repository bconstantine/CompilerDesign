{%
- 12 kind of sentence needs to be checked in all scope:
    - assignment
    - put
    - get
    - loop 
    - block
    - If
    - For
    - Return
    - Result
    - Expr
    - Result
    - Skip
%}
var a:= 0
const n: int := 10
var outsideVar := 10
var sum := 100

%13.a %this is valid
function aFunc() : int
    for index: 1 .. n
        result 10
    end for
end aFunc

procedure aProc()
    for index: 1 .. n
        return
    end for
end aProc

%13.c still valid
for index: 1 .. n
end for

%13.d still valid 
for index: 1 .. n
    var a:= 10
end for

for index: 1 .. n
    put "hi"
end for
skip

%13.b, 13.f, 13.g, 13.i 13.k
for i: 1 .. n
    var a := 10
    outsideVar := 100

    aProc()
    put "10: "
    put aFunc()
    skip 
    put "10: "
    put a
    skip

    loop 
        a := a + 1
        exit
    end loop
    put "11: "
    put a
    skip

    begin
        a:= 10
    end

    if a = 10 then
        put "Enter here"
        skip
    else
        put "Should not enter here"
        skip
    end if

    put "100: "
    put sum
    skip

    for index: 1 .. n 
        sum := sum + index
    end for

    put "155: "
    put sum
    skip

    exit when a<10
    put "should print this"
    skip
    exit when i = 1
    put "should not print this"
    skip
    put "loop dont look at result from this point: "
    skip
end for

put "loop finishes: "
skip

put "10 - 1: "
for decreasing i: n .. 1
    put " "
    put i
end for
skip
put "10 - 1: "
for decreasing i: 2*5 .. 1
    put " "
    put i
end for
skip
put "1 - 10: "
for outsideVar: 100 mod 99 .. n
    put " "
    put outsideVar
end for
skip