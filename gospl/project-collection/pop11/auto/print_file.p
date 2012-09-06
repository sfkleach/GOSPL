;;; Summary: print a file to cucharout

/**************************************************************************\
Contributor                 Steve Knight, HP Labs.
Date                        14th Oct 1991
Description
    Prints a file to cucharout.
\**************************************************************************/

compile_mode :pop11 +strict;

section;

define print_file( f ); lvars f;
    apprepeater( discin( f ), cucharout )
enddefine;

endsection;
