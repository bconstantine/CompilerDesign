var a:int := 10

procedure change()
    put "inside function, static a = 10, dynamic a = 1000: "
    put a
    skip
    a := 100
end change


begin
    var a := 1000
    change()
    put "inside function, static a = 1000, dynamic a = 100: "
    put a
    skip
end

put "inside function, static a = 100, dynamic a = 100: "
put a
skip