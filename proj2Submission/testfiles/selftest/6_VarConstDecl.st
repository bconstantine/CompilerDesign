%variable and const Related

function resultIntFunction(a:int):int
    result 10
end resultIntFunction

%6.a these should all be valid
var inta : int := 100
var intb := 100
var intc : int
var reala : real := 100.0
var realb := 100.0
var realc : real
var stra : string := "aa"
var strb := "bb"
var strc : string
var boola : bool := true
var boolb := false
var boolc : bool

%6.b these should all be valid
const cinta : int := 100
const cintb := 200
const creala : real := 100.0
const crealb := 100.0
const cstra : string := "aaa"
const cstrb := "bbb"
const cboola : bool := true
const cboolb := false

%6.d these should all be invalid
var inta : int := 100
var intb := 100
var intc : int
var reala : real := 100.0
var realb := 100.0
var realc : real
var stra : string := "aa"
var strb := "bb"
var strc : string
var boola : bool := true
var boolb := false
var boolc : bool
const cinta : int := 100
const cintb := 200
const creala : real := 100.0
const crealb := 100.0
const cstra : string := "aaa"
const cstrb := "bbb"
const cboola : bool := true
const cboolb := false

%6.c 6.g these should all be valid, all the descending index is invalid, array of string is also invalid
var arrinta : array 1 .. 2 of int 
var arrintb : array 2 .. 1 of int %invalid
var arrreala : array 1 .. 2 of real
var arrrealb : array 2 .. 1 of real %invalid
var arrboola : array 1 .. 2 of bool
var arrboolb : array 2 .. 1 of bool %invalid
var arrstringa : array 1 .. 2 of string %invalid
var arrstringb : array 2 .. 1 of string %invalid

%6.e  The first part should all be valid, the next part should be invalid
var testA := 10 + 20
var testB :bool := 10 < 20
var testC :string := cstra
const testD :real := 10 * creala
const testE := 19 % cinta

var testF := testA + 10 % nonconstant
var testG : int := 100.0 %different types
var testF : int := resultIntFunction(10) %nonconstant
var testH : real := arrreala %array RHS
const testI := testA + 10 % nonconstant
const testJ : int := 100.0 %different types
const testK : int := resultIntFunction(10) %nonconstant
const testL : real := arrreala %array RHS
const testM : real := 100.0/0

