%mix expression check

var aFalse := not 10+12*7 >= 2*5
var bFalse := true and 10+12*7 < 2*5
var cTwelve := 2+3-1*7
const dTrue := true = (not false)
const eFalse := true and 10+12*7 < 2*5

put "false: "
put aFalse  %false
skip

put "false: "
put bFalse %false
skip

put "-2: "
put cTwelve
skip

put "true: "
put dTrue %true
skip

put "false: "
put eFalse %false
skip

put "false: "
put not 10+12*7 >= 2*5  %false
skip

put "false: "
put true and 10+12*7 < 2*5 %false
skip

put "-2: "
put 2+3-1*7
skip

put "true: "
put true = (not false) %true
skip

put "true: "
put true and 10+12*7 < 2*5 or (not false) %true
skip

if (true) then
    var aFalse := not 10+12*7 >= 2*5
    var bFalse := true and 10+12*7 < 2*5
    var cTwelve := 2+3-1*7
    const dTrue := true = (not false)
    const eFalse := true and 10+12*7 < 2*5
    put "false: "
    put aFalse  %false
    skip

    put "false: "
    put bFalse %false
    skip

    put "-2: "
    put cTwelve
    skip

    put "true: "
    put dTrue %true
    skip

    put "false: "
    put eFalse %true
    skip
end if