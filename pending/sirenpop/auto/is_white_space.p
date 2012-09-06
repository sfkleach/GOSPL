compile_mode :pop11 +strict;

section;

define is_white_space( ch ); lvars ch;
    if ch.isinteger then
        strmember( ch, '\s\n\r\t' )
    else
        false
    endif
enddefine;

endsection;
