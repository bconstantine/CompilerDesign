{%
 % Example with Functions
 %}

% global variables
const a: int := 5
var c: int

% function declaration
function add (a: int, b: int) : int
  result a+b
end add

% main block
c := add(a, 10)
if (c > 10) then
  put -c
else 
  put c
end if
put "Hello World\n"
