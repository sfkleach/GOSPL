compile_mode :pop11 +strict;

section;

define global to_float( n ); lvars n;
    number_coerce( n, 0.0s0 )
enddefine;

endsection;
