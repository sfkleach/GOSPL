compile_mode :pop11 +strict;

section;

define global to_string( s ); lvars s;
    if s.isstring then
        s
    else
        into_string( s )
    endif;
enddefine;

endsection
