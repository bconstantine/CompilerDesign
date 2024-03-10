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

loop
    exit
end loop

%12.d still valid 
loop
    var a:= 10
    exit
end loop

put "print hi 9 times: "
loop
    var c := 0
    loop
        put "hi "
        c := c+1
        exit when c > 2 
    end loop
    a := a+1
    exit when a > 2 
end loop
skip

loop
    outsideVar := 100
    aProc()
    
    put "3: "
    put a

    begin
        a:= 10
    end
    

    if a = 10 then
        put "should enter here"
        skip
    else
        put "should not enter here"
        skip
    end if
    

    for index: 1 .. n 
        a := a + index
    end for
    

    put "65: "
    put a
    skip
    
    exit when a<10
    put "should print this"
    skip
    exit when a = 65
    put "should not print this"
    skip
    
end loop