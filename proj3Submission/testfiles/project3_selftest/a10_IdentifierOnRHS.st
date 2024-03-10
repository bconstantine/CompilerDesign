var a := 10

function d(b:int, c: bool, a: int, f: bool):int
    result a
end d

function j(b:int, c: bool, a: int, f: bool):bool
    result f
end j

put "100: "
put a * d(0, false, 10, true)
skip

%10.b valid
put "1: "
put d(0, false, 10, true) / 10
skip

%10.a 10.c valid, the next part should be invalid
put "10: "
put d(0, false, 10, true)
skip
put "true: "
put j(0, false, 10, true)