;;; Summary: explodes elements of repeater with a count

/**************************************************************************\
Contributor                 Steve Knight
Date                        17 Oct 91
Description
    Explodes a repeater + count of elements
\**************************************************************************/

compile_mode :pop11 +strict;

section;

define destrepeater( procedure r );
    #| until dup( r() ) == termin do enduntil -> _ |#
enddefine;

endsection;
