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
var outsideRealVar := 100.0
var outsideArray: array 1  .. 10 of int

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

%13.b, 13.f, 13.g, 13.i 13.k
for i: 1 .. n
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
end for

%13.j this should be invalid
put a

%13.g 13.hthe first part should succeed, the rest should fail 

for decreasing i: n .. 1
    put n
end for
for decreasing i: 100+30 .. 1
    put n
end for
for decreasing outsideVar: 100*30 .. n
    put n
end for

for decreasing i: 1 .. n
    put n
end for
for i: n .. 1
    put n
end for
for decreasing i :  z .. 1
    put i
end for
for decreasing i : outsideVar .. 1
    put i
end for
for decreasing i: "hello" .. 1
    put i
end for
for decreasing i: "hello" .. 1
    put n
end for
for decreasing i: outsideRealVar .. 1
    put i
end for

for decreasing i: outsideArray .. 2
    put i
end for