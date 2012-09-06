compile_mode :pop11 +strict;

section;

define global split_fields( str, sep );
    lvars a = 1;
    repeat
        lvars b = issubstring( sep, a, str );
        if b then
            substring( a, b - a, str );
            b + length( sep ) -> a;
        else
            substring( a, length( str ) - a + 1, str );
            quitloop
        endif
    endrepeat
enddefine;

endsection;
