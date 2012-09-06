compile_mode :pop11 +strict;

section;

define ceiling( x ); lvars x;
    lvars n = intof( x );
    if x = n or x < 0 then
        n
    else
        n + 1
    endif;
enddefine;

endsection;
