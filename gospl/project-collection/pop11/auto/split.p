compile_mode :pop11 +strict;

section;

define split( s );
    split_with( s, '\s\t\n\r' )
enddefine;

endsection;
