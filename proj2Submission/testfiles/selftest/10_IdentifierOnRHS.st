var a := 10
const b := 101.0

function d():int
    result 1011
end d

function e():real
    result 1011.0
end e

procedure j()
    return
end j


var s : array 2 .. 10 of real
var shorterarray : array 1 .. 1 of real

function inOfArray(s: array 0 .. 8 of real): real
    result s[0]
end inOfArray


put a + 10

%10.b valid
put b - 10
put b / 10
put a / 10

%10.a 10.c valid, the next part should be invalid
put a
put b
put d()
put j()
put s[10]
put inOfArray(s)
put s[a]
put s[d()]



put inOfArray(shorterarray)
put a[0]
put b[0]
put d[0]
put j[0]
put d
put j
put s
put inOfArray
put a()
put b()
put s()