;;; Summary: finds the nearest integer to -infinity

compile_mode :pop11 +strict;

section;

define floor( x ); lvars x;
    lvars n = intof( x );
    if x = n or x > 0 then
        n
    else
        n - 1
    endif
enddefine;

endsection;
