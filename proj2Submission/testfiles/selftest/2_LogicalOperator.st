%Test case related to Logical Operators%

%2.h 2.i 2.j, these should all be valid
var z:array 1..10 of bool
var az:bool := false
const bz := true
const cz := not bz
const dz := bz or false
const ez := bz or false
put az
put bz
put cz
put dz
put ez

%2.a, only the first three valid, the other not
put false and true
put false or false
put not false

true and 1
false and 1.0
true and "ss"
1 and false
1.0 and false
"ss" and true
true and z
z and false

true or 1
false or 1.0
true or "ss"
1 or false
1.0 or false
"ss" or true
true or Z
z or false

not 1
not 1.0
not "ss"
not z
not (z)
not "ss"

%2.b, these should all be valid
put true and true
put true and false
put false and true
put (false and false)

put true or true
put true or false
put false or true
put false or false

put not true
put not false

%2.c these should all be valid
put false or true and not true %should be false
put false or not false and true %should be true

%2.d 2.e 2.f 2.g these should all be valid, the last part should be not valid
begin
    function randomBool() : bool
        result true
    end randomBool

    put az and bz
    put az or bz
    put not az
    put randomBool() and randomBool()
    put randomBool() or randomBool()
    put not randomBool()

    put 10/0 > 1 and bz
end