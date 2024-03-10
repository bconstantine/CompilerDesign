var a : int
var d : bool

const ca := 100
const cc := "aa"
const cd := false


function intFunc(n: int):int
    result n
end intFunc


function boolFunc(n : bool):bool
    result n
end boolFunc

% 9.c valid set value
a := 10 + 10 * 10 / 10 mod 10
d := true or false

put "10: "
put a
skip 
put "true: "
put d
skip



for i: 1 .. 0*1+1
    var a : int
    var d : bool
    a := intFunc(90+2*5)
    d := boolFunc(not true and false)
    put "100: "
    put a
    skip
    put "false: "
    put d
    skip
    a := 10 + 10 * 10 / 10 mod 10
    d := true or false
    put "10: "
    put a
    skip 
    put "true: "
    put d
    skip
end for 

%9.a This is valid
a := intFunc(90+2*5)
d := boolFunc(not true and false)
put "100: "
put a
skip
put "false: "
put d
skip