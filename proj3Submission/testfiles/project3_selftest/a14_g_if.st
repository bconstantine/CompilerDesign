% try commenting one by one to see that each one of this will cause syntax error

if (true) then
    put "NonDeclaration followed by Declaration"
    var a := 10
end if

if (false) then
    skip
else
    put "NonDeclaration followed by Declaration"
    var a := 10
end if