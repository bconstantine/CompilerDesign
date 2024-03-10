%Test case related to Mathematical Operators%

%4.j 4.i
var b:array 1..1 of int
var c:array 1..2 of real
const a : int := 10
const als := 10.0
var e : int
var f := 12.0 
var y := 10.1 / als
const x := 10.1 / als
function z() : int
    result 10
end z
function l() : real
    result 10.1
end l

put a
put als
put e
put f
put y
put x

%4.a, 4.b the first part should be valid, the other not
put 10 + 20
put 10 + 10.1
put 10.1 + 10
put 10.1 + 10.1
put 10 - 20
put 10 - 10.1
put 10.1 - 10
put 10.1 - 10.1
put 10 * 20
put 10 * 10.1
put 10.1 * 10
put 10.1 * 10.1
put 10 / 20
put 10 / 10.1
put 10.1 / 10
put 10.1 / 10.1
put 10 mod 3
put -10 mod -3
put -10 mod 3
put 10 mod -3
put (10)
put (10.1+1)
put (10.7)
put -10
put -10 / -7
put -10 * -7
put -10.0 * 7

put 10 + "aaa"
put 10 - b
put 10.1 * c
put 10.1 / true
put "aaa"mod 3
put 3 mod 3.0
put 3.0 mod 1
put b - 3
put c * 5
put true + 2
put (false+1)
put -false
put -true / -1
put -10 * -z

%4.c these should be valid
put (10+2/4.0*7.0) %13.5
put (2/4.0*(7.0-10)) %01.5
put (1+2 mod 3)

%4.d these should result -70?
put -10*--7

%4.e 4.g these should be valid
begin
    put a + als
    put a - f
    put a * e
    put a / als
    put als
    put a % 1
end

%4.f
put z() + 10
put l() * 10.0

%4.h
put 10/0
put 10.1/0
put 10 mod 0