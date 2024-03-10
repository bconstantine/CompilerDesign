%Test case about get statements

var a: real
var b: bool
var c: int
var d: string
var e:array 1..100 of int
const f: int := 10
const g: int := 1000

procedure emptyProc()
end emptyProc

function emptyFunc():int
    result 100
end emptyFunc

%8.a, will cause error
get noVarExist

%8.b 8.f, this won't cause an error
begin
    get a
    get b
    get c
    get d
    put a
    put b
    put c
    put d
end

%8.c 8.e 8.g some will cause error or not
get e[10+1] %valid
get e[c] %can't check due to index is array
get e[10/0] %invalid index, get fails
get e[101] %invalid index
get e[f] %valid
get e[g] %invalid, index out of bound
get e %fail, gets array variable
get e %fail, gets array variable
get e[e] %fail, array index is another array
get e[true] %fail, array index is bool
get e[b] %fail, array index is bool
get e[2.0] %fail, array index is real
get e[a] %fail, array index is real
get e["string"] %fail, array index is string
get e[d] %fail, array index is string
get emptyProc %fail, a procedure
get emptyFunc %fail, a function