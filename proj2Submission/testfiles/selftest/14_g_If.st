% try commenting one by one to see that each one of this will cause syntax error

If (true) then
    put "NonDeclaration followed by Declaration"
    var a := 10
end if

If (false) then
    pass
else
    put "NonDeclaration followed by Declaration"
    var a := 10
end if