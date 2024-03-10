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

var outsideBooleanVar : bool := true

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
        exit
    end
end loop


%15.c
begin
    var a := 10
    var inner := 10
    outsideVar := 100

    aProc()
    skip
    put "100: "
    put aFunc()
    skip
    put "10: "
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
        put "Should enter here"
        skip
    else
        put "Should not enter here"
        skip
    end if

    for index: 1 .. n 
        sum := sum + index
    end for

    exit when a<10
    put "should print this"
    skip
    exit when a = 10
    put "should not print this"
    skip
    put "loop dont look at result from this point: "
    skip
end