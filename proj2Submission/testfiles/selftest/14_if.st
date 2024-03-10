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
        result 10
    else
        result outsideVar
    end if
end aFunc

procedure aProc()
    if(not 10*9 < 10 + 2) then
        return
    end if
end aProc

var outsideRealVar := 1000.0
var outsideBooleanVar : bool := true
var outsideBooleanVarArray : array 1 .. 100 of bool
%14.h still valid
if(10 < 1) then
end if

if(10 < 1) then
else
end if

%14.i still valid 
if(true) then
    a := 1
end if

if(true) then
else
    a := 1
end if

if(true) then
    put "hi"
end if

if(true) then
else
    put "hi"
end if

%14.f this is valid
loop
    if(not 10*9 < 10+2) then
        exit
    else
        outsideVar = outsideVar + 1
    end if
end loop

for i : 1 .. n
    if(not 10*9 < 10+2) then
        exit
    else
        outsideVar = outsideVar + 1
    end if
end for

%13.a this all should be valid
if(false) then
    if(true) then
        10 + 2
    end if
else
    skip
end if

if(false) then
    skip
else
    if(true) then
        10 + 2
    end if
end if
if(false) then
    if(true) then
        put 10 + 2
    else
        put 10*2
    end if
else
    skip
end if

if(false) then
    skip
else
    if(true) then
        put 10 + 2
    else
        put 10*2
    end if
end if

if(false) then
    if(true) then
        put 10 + 2
    else
        put 10*2
    end if
end if



%14.b, 14.d
if(10 not= 20) then
    var a := 10
    var b := 10.0
    var c : array 1 .. 10 of int
    var inner := 10

    {%Warning, uncommentingthis will cause syntax error
        %this part is invalid
        function funcDeclare() : int
            result 10
        end funcDeclare

        %this part is invalid
        procedure procDeclare()
        end procDeclare
    %}

    outsideVar := 100

    aProc()
    aFunc()
    put a
    get a

    loop 
        a = a+ 1
        exit
    end loop

    begin
        a:= 10
    end

    if a = 10 then
        a + 10
    else
        a + 100
    end if

    for index: 1 .. n 
    sum := sum + index
    end for

    %this part is invalid
    exit
    exit when a<10
    exit when 10+1 %invalid exit
    
    return % this should be error
    result 100 %this should be error
    100 < 200
else
    var a := 10
    var b := 10.0
    var c : array 1 .. 10 of int

    {% Warning, uncommenting this will cause syntax error
        %this part is invalid
        function funcDeclare() : int
            result 10
        end funcDeclare

        %this part is invalid
        procedure procDeclare()
        end procDeclare
    %}

    outsideVar := 100


    aProc()
    aFunc()
    put a
    get a

    loop 
        a = a+ 1
        exit
    end loop

    begin
        a:= 10
    end

    if a = 10 then
        a + 10
    else
        a + 100
    end if

    for index: 1 .. n 
    sum := sum + index
    end for

    exit
    exit when a<10
    exit when 10+1 %invalid exit
    
    return % this should be error
    result 100 %this should be error
    100 < 200
end if

%14.c this should be invalid
put inner

%14.j the first should be valid, the rest is not
if(outsideBooleanVar) then
    put "valid"
end if 

if(outsideRealVar) then
    put "not valid"
end if

if(10+2.2) then
    put "not valid also"
end if

if(outsideBooleanVarArray) then
end if