compile_mode :pop11 +strict;

section;

define is_white_space( char );
    locchar( char, 1, '\s\t\n\r' )
enddefine;

endsection;
