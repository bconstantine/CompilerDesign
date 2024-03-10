%Test case related to Relational Operator%

const aint:int := 100
var bint:int := 2
const abool: bool := true
var bbool: bool := false

function intFunc1(): int
    result 1
    put "This should not be printed"
    skip
end intFunc1

function intFunc2(): int
    result 2
    put "This should not be printed"
    skip
end intFunc2

function boolFuncTrue(): bool
    result true
end boolFuncTrue

function boolFuncFalse(): bool
    result false
end boolFuncFalse

procedure voidProc()
end voidProc

const randVar1 : bool := true = false
var randVar2 : bool := randVar1 not= true
put "The answer should be false: "
put randVar1
skip
put "The answer should be true: "
put randVar2
skip

put "true: "
put 10 > 9
skip
put "false: "
put 10 < 9
skip
put "false: "
put 10 <= 9
skip
put "true: "
put 10 >= 9
skip
put "false: "
put 10 = 9
skip
put "true: "
put 10 not= 9
skip
put "========"
skip
put "false: "
put 10 > 10
skip
put "false: "
put 10 < 10
skip
put "true: "
put 10 <= 10
skip
put "true: " 
put 10 >= 10
skip
put "true: "
put 10 = 10
skip
put "false: "
put 10 not= 10
put "=============="
skip
put "true: "
put true = true
skip
put "false: "
put false not= false
skip
put "false:" 
put false = true
put "true: "
put false not= true
skip
put "=============="
put "false: "
put aint <= bint
skip
put "true: "
put aint > bint
skip
put "false: "
put abool = bbool
skip
put "true: "
put abool not= bbool
skip
put "============="
skip
put "false: "
put 200 < aint
skip
put "true: "
put 100 = aint
skip
put "===="
skip
put "true: "
put (10 > 9 = true not= false) %true
skip
put "true: "
put (10 < 19 not= false = true) %true
skip

%3.e %3.i these expressions should be valid
begin
    put "true: "
    put intFunc1() <= intFunc2()
    skip
    put "false: "
    put intFunc1() > intFunc2()
    skip
    put "false: "
    put boolFuncTrue() = boolFuncFalse()
    skip
    put "true: "
    put boolFuncTrue() not= boolFuncFalse()
end
