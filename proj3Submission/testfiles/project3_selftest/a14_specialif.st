if(false)then
    put "This should not be printed"
    skip
else if(false) then
    put "This should not be printed"
    skip
    end if
end if

if(false)then
    put "This should not be printed"
    skip
else if(true) then
    put "This should be printed"
    skip
    end if
end if

if(10*9 < 10+2) then
    put "should not enter here"
    skip
else if(10*9 < 10+2) then
    put "should not enter here also"
    skip
else
    put "should enter here1"
    skip
end if
end if

if(true) then
    put "should enter2"
    skip
else if(10*9 < 10+2) then
    put "should not enter here also"
    skip
else
    put "should not enter here"
    skip
end if
end if

if(10*9 < 10+2) then
    put "should not enter here"
    skip
else if(true) then
    put "should enter here3"
    skip
else
    put "should not enter here"
    skip
end if
end if
exit