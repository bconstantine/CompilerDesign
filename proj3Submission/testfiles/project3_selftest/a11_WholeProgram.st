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
function funcDeclare() : int
    result 10
end funcDeclare
procedure procDeclare()
end procDeclare

a := 10
put "10: "
put a
skip

loop 
    exit
end loop



begin
    a:= 100
end

put "100: "
put a
skip


if a = 10 then
    put "Should not enter here"
    skip
else
    put "Should enter here"
    skip
end if



for index: 1 .. n 
  sum := sum + index
end for

put "55: "
put sum
skip

exit when sum not= 55 %this should be invalid
put "This should still be printed"
skip
exit %this one should be invalid
put "This should not be printed"