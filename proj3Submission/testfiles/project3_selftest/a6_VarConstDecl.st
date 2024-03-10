%variable and const Related


var inta : int := 100
var intb := 100
var intc : int
var boola : bool := true
var boolb := false
var boolc : bool

const cinta : int := 100
const cintb := 200
const cboola : bool := true
const cboolb := false
const cstra : string := "Herro"
const cstrb : string := "Herro2"

var testA := 10 + 20
var testB :bool := 10 < 20
const testC :bool := 10 > 20
const testD := 19 mod (2*5)

loop
    var inta : int := 200
    var intb := 200
    var intc : int
    var boola : bool := false
    var boolb := true
    var boolc : bool

    const cinta : int := 200
    const cintb := 300
    const cboola : bool := false
    const cboolb := true
    const cstra : string := "Herro2"
    const cstrb : string := "Herro"

    var testA := 10 + 20 + 100
    var testB :bool := 10 > 20
    const testC :bool := 10 < 20
    const testD := 19 mod (2*5)+ 100

    put "200: "
    put inta
    skip
    put "200: "
    put intb
    skip
    put "havent initialized: "
    put intc
    skip
    put "false: "
    put boola
    skip
    put "true: "
    put boolb
    skip
    put "havent initialized: "
    put boolc
    skip

    put "200: "
    put cinta
    skip
    put "300: "
    put cintb
    skip
    put "false: "
    put cboola
    skip
    put "true: "
    put cboolb
    skip
    put "Herro2: "
    put cstra
    skip
    put "Herro: "
    put cstrb
    skip

    put "130: "
    put testA
    skip
    put "false: "
    put testB
    skip
    put "true: "
    put testC
    skip
    put "109: "
    put testD
    skip

    exit
end loop

put "100: "
put inta
skip
put "100: "
put intb
skip
put "havent initialized: "
put intc
skip
put "true: "
put boola
skip
put "false: "
put boolb
skip
put "havent initialized: "
put boolc
skip

put "100: "
put cinta
skip
put "200: "
put cintb
skip
put "true: "
put cboola
skip
put "false: "
put cboolb
skip
put "Herro: "
put cstra
skip
put "Herro2: "
put cstrb
skip

put "30: "
put testA
skip
put "true: "
put testB
skip
put "false: "
put testC
skip
put "9: "
put testD
skip


exit when true
put "This should not be printed"
skip

