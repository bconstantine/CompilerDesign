{%
- 12 kind of sentence needs to be checked in all scope:
    - assignment
    - put
    - get
    - loop 
    - block
    - If
    - For
    - Return
    - Result
    - Expr
    - Result
    - Skip
%}
const n: int := 10
var sum := 0
%11.e 11.f testing various case, DeclarationSection followed by NonDeclarationSection, some might be valid some not
var a := 10
var b := 10.0
var c : array 1 .. 10 of int
function funcDeclare() : int
    result 10
end funcDeclare
procedure procDeclare()
end procDeclare

a := 10
put a
get a



loop 
end loop



begin
    a:= 10
end


if a = 10 then
    a + 10
else
    a + 100
end if



for index: 1 .. n 
  sum := sum + index
end for

skip

return % this should be error
result 100 %this should be error
100 < 200
exit %this one should be invalid
exit when (100 - 1 < 100) %this should be invalid