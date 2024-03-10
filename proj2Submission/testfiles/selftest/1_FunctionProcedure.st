%Test case related to Function and Procedure%

procedure universalproc()
    put "Test case is a lot"
end universalproc

%1.b.a, 1.a.a these should print error message
begin
    const a:=10
    var b:=10
    var c: array 1 .. 10 of bool

    function a(): int
    end a

    procedure b(c:int)
    end b

    function c(d:int) : real
    end c

    a
    b
    c
    d
end

%1.b.b 1.b.e 1.b.f, this should be error and function not declared
begin
    function d(e:array 1 .. 10 of string) : string
        result "Hello"
    end d

    function e(e: string) : string
        e("halo")
        result "Hello"
    end e

    procedure d(e:array 1 .. 10 of string)
    end d

    procedure e(e: string)
    end e

    var z:array 0..9 of string
    d(z) %should cause error function/procedure not exist
end

%1.b.c and 1.b.d, 1.a.c 1.a.d  this should be valid except the part where scramble argument call
begin
    function z(a: int, b: real, c: bool, d: string, e: array 2 .. 10 of int, f: array 3 .. 10 of real, g: array 5 .. 5 of bool): int
        result a
    end z

    function y(a: int, b: real, c: bool, d: string, e: array 2 .. 10 of int, f: array 3 .. 10 of real, g: array 5 .. 5 of bool): real
        result b
    end y

    function x(): string
        var c : string := "Ooo"
        result c
    end x

    function w(): bool
        const a : bool := false
        result a
    end w

    var m: array 0 .. 8 of int
    var l: array 0  .. 7 of real
    var k: array 0 .. 0 of bool
    z(1, 2.0, true, "hello""all",m,l,k)
    x()
    w()

    %scramble argument to make it invalid
    z(2.0, 2.0, true, "hello""all",m,l,k)
    z(1, l, true, "hello""all",m,l,k)
    z(1, 2.0, k, "hello""all",m,l,k)
    z(1, 2.0, true, false,m,l,k)
    z(1, 2.0, true, "hello""all",l,l,k)
    z(1, 2.0, true, "hello""all",m,k,k)
    z(1, 2.0, true, "hello""all",m,l,m)
end

%1.b.g 1.b.h 1.b.i 1.b.j, these should result error
begin
    function a():bool
    end a

    function b():bool
        return
    end b

    function z():bool
        result 1
    end z

    function y():int
        result 10.1
    end y

    function x():real
        result 1
    end x

    function w():string
        result asd
    end w

    function u():bool
        var z: array 1..1 of bool
        result z
    end u

    function v():int
        var z: array 1..1 of int
        result z
    end v

    function o():real
        var z: array 1..1 of real
        result z
    end o

    function p():string
        var asd: array 1..1 of string
        result asd
    end p

    procedure l()
        result 1
    end l

    procedure k()
        result 10.1
    end k

    procedure m()
        result "asd"
    end m

    procedure j()
        result false
    end j


    l()
    k()
    m()
    j()
    o()
    p()
    v()
    w()
    x()
    y()
    z()
end


%1.b.k 1.b.m, only als is valid
begin
    function asd (): bool
    end aaa
    
    procedure aaa()
    end asd

    function abc(): bool
    end abc

    procedure als()
    end als

    asd()
    aaa()
    abc()
    als()


end

%1.b.l, these should be valid
begin
    function universalproc(a: string): string
        put "HERRO""IM LOCAL"
        result a
    end universalproc
    function a(b:int):int
        put b
        result b
    end a
    begin
        function a():real
            put 10.1
            result 10.1
        end a

        a()
    end
    a(10)
    universalFunc("HIHIHI")
end

%1.a.b, 1.a.e this should result error except the last one
begin
    function a(j:real):real
        result j
    end a
    10 + a(10.0/0)
    10 + a(1/0.0)
    10 + a(1000.0) %valid

end

%1.a.f 1.b.n this should be error
begin
    %only this function declaration is valid
    function intFunc(): int
        result 100
    end intFunc

    function als:int
        put "No parentheses will be error"
        result intFunc
    end als

    procedure d
        put "No parentheses will be error"
    end d

    universalproc %this will be an error
    intFunc %this will also be an error
    als() %error message will be function not exist
    d() %error message will be procedure not exist
end

%1.a.f the first function call is invalid, but the second one valid
begin
    function intFunc(): int
        result 100
    end intFunc

    function anotherintFunc(n:int): int
        result n
    end anotherintFunc

    anotherintFunc(intFunc)
    anotherintFunc(intFunc())
end