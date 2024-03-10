%Test case related to Relational Operator%

const areal:real := 100.0
var breal:real := 2.0
const aint:int := 100
var bint:int := 2
const ast: string := "z"
var bst: string := "a"
const abool: bool := true
var bbool: bool := false
var varint : array 1..1 of int
function intFunc(): int
    result 1
end intFunc

function boolFunc(): bool
    result true
end boolFunc

function realFunc() : real
    result 10.1
end realFunc

function strFunc() : string
    result "10.1"
end strFunc

procedure voidProc()
end voidProc

%3.i valid
const randVar1 : bool := true = false
var randVar2 : bool := randVar1 not= true
put randVar1
put randVar2

%3.a, 3.b, 3.c,3.f,3.g, 3.h the first part should be valid, while the other not
put 10 > 9
put 10 < 9
put 10 <= 9
put 10 >= 9
put 10 = 9
put 10 not= 9
put "========"
put 9 > 10.0
put 9 < 10.0
put 9 <= 10.0
put 9 >= 10.0
put 9 = 10.0
put 9 not= 10.0
put "========"
put 10.0 > 10
put 10.0 > 10.0
put 10.0 < 10
put 10.0 < 10.0
put 10.0 <= 10
put 10.0 <= 10.0
put 10.0 >= 10
put 10.0 >= 10.0
put 10.0 = 10
put 10.0 = 10.0
put 10.0 not= 10
put 10.0 not= 10.0
put "=============="
put "aasd" > "absd"
put "aasd" < "absd"
put "aasd" <= "absd"
put "aasd" >= "absd"
put "aasd" = "absd"
put "aasd" not= "absd"
put "=============="
put "absd" > "aasd"
put "absd" < "aasd"
put "absd" <= "aasd"
put "absd" >= "aasd"
put "absd" = "aasd"
put "absd" not= "aasd"
put "=============="
put "aasd" > "aasd"
put "aasd" < "aasd"
put "aasd" <= "aasd"
put "aasd" >= "aasd"
put "aasd" = "aasd"
put "aasd" not= "aasd"
put "=============="
put true = true
put false not= false
put false = true
put false not= true
put "=============="
put areal > breal
put aint <= bint
put areal <= aint
put aint > aint
put ast > bst
put abool = bbool
put abool not= bbool

put "============="

put "=invalidparts="
put 100 > "string"
put 200 < varint
put 200 not= true
put 100.0 > "string"
put 200.0 < varint
put 200.0 not= true
put true > false
put abool < bbool
put abool <= bbool
put abool >= bbool
put voidProc() not= 1
put voidProc() = 1
put voidProc() > 1.0
put voidProc() < true
put voidProc() <= false
put voidProc() >= abool

%3.d these expressions should be valid
put (10 > 9 = true not= false) %true
put ("s" < "z" not= false = true) %true

%3.e %3.i these expressions should be valid
begin
    put areal > breal
    put aint <= bint
    put areal <= aint
    put aint > aint
    put ast > bst
    put abool = bbool
    put abool not= bbool
end
