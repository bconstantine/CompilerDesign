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
const n: int := 10
var a:= 0
var outsideVar := 10
var sum := 100
var outsideBooleanVarArray: array 1 .. 10 of bool


%12.a %this is valid
function aFunc() : int
    loop
        result 1
    end loop
end aFunc

procedure aProc()
    loop
        return
    end loop
end aProc

%12.c still valid
loop
end loop

%12.d still valid 
loop
    var a:= 10
end loop

loop
    put "hi"
end loop

%12 b, 12 f, 12 g, 12.i, mix, might be valid or not
loop
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
        a := a + index
    end for

    exit
    exit when a<10
    exit when 10+1 %invalid exit
    exit when outsideBooleanVarArray
    

end loop

%12.h this should be invalid
put a