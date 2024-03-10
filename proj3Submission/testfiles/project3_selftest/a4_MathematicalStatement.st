%Test case related to Mathematical Operators%

const aTen : int := 10
const aHundred := 100
var eOne : int := 1
var yOne := 101 / aHundred
const xHundred := 999+101 / aHundred - 900
function zTen() : int
    result 10
end zTen

put "10: "
put aTen
skip
put "100: "
put aHundred
skip
put "1: "
put eOne
skip
put "1: "
put yOne
skip
put "100: "
put xHundred
skip

put "30: "
put 10 + 20
skip
put "-10: "
put 10 - 20
skip
put "200: "
put 10 * 20
skip
put "5: "
put 100 / 20
skip
put "1: "
put 10 mod 3
skip
put "10: "
put (10)
skip
put "102: "
put (101+1)
skip
put "-10: "
put -10
skip
put "1: "
put -10 / -7
skip
put "70: "
put -10 * -7
skip

put "17: "
put (10+4/4*7) %17
skip
put "-6: "
put (4/2*(7-10)) %-6
skip
put "-3: "
put -(1+5 mod 3)
skip

%4.d these should result -70
put "-70: "
put -10*--7
skip

%4.e 4.g these should be valid
begin
    const aTen : int := 10
    const aHundred := 100
    put "101: "
    put aTen + aHundred
    skip
    var eTen : int := 10
    put "100: "
    put aTen * eTen
    skip
    var fTwelve := 12
    put "-2: "
    put aTen - fTwelve
    skip
    var yOneThousandOneTen := 101 * aTen
    const xHundred := 999+101 / aHundred - 900
    put "10: "
    put yOneThousandOneTen / xHundred
    skip
    put "0: "
    put aTen mod 1
    skip
end

put "20: "
put zTen() + 10
skip
put "0: "
put zTen() mod 10
skip