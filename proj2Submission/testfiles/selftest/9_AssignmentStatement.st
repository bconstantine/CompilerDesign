var a : int
var b : real
var c : string
var d : bool

const ca := 100
const cb := 100.0
const cc := "aa"
const cd := false


function intFunc():int
    result 100
end intFunc

function realFunc():real
    result 10.0
end realFunc

function boolFunc():bool
    result true
end boolFunc

function strFunc():string
    result "hello"
end strFunc

var e : array 1 .. 100 of int
var f : array 4 .. 100 of real
var g : array 100 .. 102 of bool
var h : array 104 .. 106 of string %invalid

% 9.c valid set value
a := 10
b := 10.0
c := "100"
d := true
e[1] := 20
f[12] := 10.0
g[100] := true

put a
put b
put c 
put d
put e[1] %valid index
put f[12] %valid index
put g[100] %valid index

put h[104] %invalid value 

%9.a This is valid
a := intFunc()
b := realFunc()
c := strFunc()
d := boolFunc()
put a
put b
put c
put d

%9.b 9.e. This is invalid
a := 10.0
b := 10
c := true
d := "hihi"
e[1] := 20.0
f[12] := 10
g[100] := true

%9.d this is invalid
intFunc := 100
realFunc := 100.0
boolFunc := true
e := 10
f := 100.0
g := true
ca := 10
cb := 10.0
cc := "string"
cd := false

%9.f. 9.g the first part should be valid, the next part should be invalid
e[100*1] := 10
f[10/2] := 12
g[a] := 10
e[intFunc()] := 1 

e[-2] := 100
e[100000] := 1001
e[10.0] := 1
f["hi"] := 10.0
g[true] := true
e[10/0] := 1
e[e] := 1