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
var outsideVar := 10
var sum := 100
const n: int := 10
%15.d %this is valid
function aFunc() : int
    begin
        result outsideVar
    end
end aFunc

procedure aProc()
    begin
        return
    end
end aProc
var outsideRealVar := 1000.0
var outsideBooleanVar : bool := true
var outsideBooleanVarArray : array 1 .. 100 of bool

%15.h still valid
begin
end

%15.i still valid 
begin
    a := 1
end

begin
    put "hi"
end

%15.e this is valid
loop
    begin
        exit when n = 100
    end
end loop


%15.c
begin
    var a := 10
    var b := 10.0
    var c : array 1 .. 10 of int
    var inner := 10
    %this part is valid
    function funcDeclare() : int
        result 10
    end funcDeclare

    %this part is valid
    procedure procDeclare()
    end procDeclare

    outsideVar := 100

    aProc()
    aFunc()
    procDeclare()
    funcDeclare()
    put a
    get a

    loop 
        a = a + 1
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
end

%15.b this should be invalid
put inner
funcDeclare()