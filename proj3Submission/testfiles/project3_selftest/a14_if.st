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
%14.e %this is valid
var a:= 0
const n: int := 10
var sum := 100
var outsideVar : int := 100
function aFunc() : int
    if(not 10*9 < 10+2) then
        put "It should enter here"
        skip
        result 10
    else
        put "hello"
    end if
    result 10
end aFunc

procedure aProc()
    if(not 10*9 < 10 + 2) then
        put "It should enter here"
        skip
        return
    end if
end aProc

if(10 < 1) then
end if

if(10 < 1) then
else
end if

%14.i still valid 
if(true) then
    put "Should enter here"
    skip
    a := 1
end if

if(true) then
else
    put "Should not enter here"
    skip
    a := 10000
end if

if(true) then
    put "Should enter here 22"
    skip
end if

if(true) then
else
    put "Should not enter here 22"
    skip
end if

%14.f this is valid
loop
    if(10*9 < 10+2) then
        put "should not enter here"
        skip
    else if(10*9 < 10+2) then
        put "should not enter here also"
        skip
    else
        put "should enter here"
        skip
    end if
    end if
    exit
end loop

for i : 1 .. n
    if(10*9 < 10+2) then
        put "should not enter here"
        skip
    else if(10*9 < 10+2) then
        put "should not enter here also"
        skip
    else
        put "should enter here"
        skip
    end if
    end if

    if(true) then
        put "should enter"
        skip
    else if(10*9 < 10+2) then
        put "should not enter here also"
        skip
    else
        put "should not enter here"
        skip
    end if
    end if

    if(10*9 < 10+2) then
        put "should not enter here"
        skip
    else if(true) then
        put "should enter here"
        skip
    else
        put "should not enter here"
        skip
    end if
    end if
    exit
end for



%13.a this all should be valid
if(true) then
    if(true) then
        put "Should enter here"
        skip
    else
        put "should not enter here"
        skip
    end if
else
    put "should not enter here"
    skip
end if


if(true) then
    if(false) then
        put "Should not enter here"
        skip
    else
        put "should enter here"
        skip
    end if
else
    put "should not enter here"
    skip
end if


if(false) then
    put "should not enter here"
    skip
else
    if(true) then
        put "Should enter here"
        skip
    else
        put "should not enter here"
        skip
    end if
end if



if(false) then
    put "should not enter here"
    skip
else
    if(false) then
        put "Should not enter here"
        skip
    else
        put "should enter here"
        skip
    end if
end if



if(10 not= 20) then
    var a := 10
    var inner := 10
    outsideVar := 100

    aProc()
    put aFunc()
    skip
    put "10: "
    put a
    skip

    loop 
        a := a+ 1
        exit
    end loop

    begin
        a:= 10
    end

    if a = 10 then
        put "enter here"
        skip
    else
        put "not enter here"
        skip
    end if

    for index: 1 .. n 
        sum := sum + index
    end for
    put "155: "
    put sum
    skip
else
    put "should not enter here"
    skip
end if

if(10 = 20) then
    put "should not enter here"
    skip
else
    skip
    var a := 1
    var inner := 10
    outsideVar := 100

    aProc()
    put aFunc()
    skip
    put "1: "
    put a
    skip

    loop 
        a := a + 1
        exit
    end loop

    begin
        a:= 10
    end

    if a = 10 then
        put "enter here"
        skip
    else
        put "not enter here"
        skip
    end if

    exit when a < 10
    put "should print thisaa"
    skip
    exit when a = 10
    put "should not print this"
    skip
    put "loop dont look at result from this point: "
    skip
end if



