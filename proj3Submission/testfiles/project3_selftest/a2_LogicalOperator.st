%Test case related to Logical Operators%

var az:bool := false
const bz := true
const cz := not bz
const dz := bz or false
var ez := bz and false
function randomBoolTrue() : bool
    result true
end randomBoolTrue

function randomBoolFalse() : bool
    result false
end randomBoolFalse

put "The result should be false: "
put az
skip
put "The result should be true: "
put bz
skip
put "The result should be false: "
put cz
skip 
put "The result should be true: "
put dz
skip
put "The result should be false"
put ez
skip

put "The result should be false: "
put false and true
skip
put "The result should be false: "
put false or false
skip
put "The result should be true: "
put not false
skip

%2.b, these should all be valid
put "The result should be true: "
put true and true
skip
put "The result should be false: "
put true and false
skip
put "The result should be false: "
put false and true
skip
put "The result should be false: "
put (false and false)
skip
put "The result should be true: "
put bz and bz
skip
put "The result should be false: "
put bz and cz
skip
put "The result should be false: "
put cz and bz
skip
put "The result should be false: "
put (cz and cz)
skip

put "The result should be true: "
put true or true
skip
put "The result should be true: "
put true or false
skip
put "The result should be true: "
put false or true
skip
put "The result should be false: "
put (false or false)
skip
put "The result should be true: "
put bz or bz
skip
put "The result should be true: "
put bz or cz
skip
put "The result should be true: "
put cz or bz
skip
put "The result should be true22: "
put (cz or bz)
skip

put "The result should be false: "
put not true
skip
put "The result should be true: "
put not false
skip
put "The result should be false: "
put not bz
skip
put "The result should be true: "
put not cz
skip

%2.c these should all be valid
put "The result should be false: "
put false or true and not true %should be false
skip
put "The result should be true: "
put false or not false and true %should be true
skip

%2.d 2.e 2.f 2.g these should all be valid, the last part should be not valid
begin
    var faz:= false
    var taz:bool := true
    put "The result should be false: "
    put taz and faz
    skip
    put "The result should be true: "
    put taz or faz
    skip
    put "The result should be true: " 
    put not az
    skip
    put "The result should be false: "
    put randomBoolTrue() and randomBoolFalse()
    skip
    put "The result should be true: "
    put randomBoolTrue() or randomBoolFalse()
    skip
    put "The result should be false: "
    put not randomBoolTrue()
    skip
end