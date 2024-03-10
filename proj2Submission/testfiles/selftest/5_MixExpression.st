%mix expression check

%5.a, all of these operations should be valid
put not 10+12*7 >= 2*5  %false

put true and 10+12*7 < 2*5 %false

put true = (not false) %true

put true and 10+12*7 < 2*5 or (not false) %true