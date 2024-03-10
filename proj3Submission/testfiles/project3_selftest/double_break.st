var a:= 10
loop
    loop
        put "executed"
        exit when a <= 10
    end loop
    put "Still executed"
    exit when a <= 10
end loop