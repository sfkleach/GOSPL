;;; Summary: iterate over a repeater

/**************************************************************************\
Contributor                 Steve Knight, HP Labs.
Date                        14th Oct 1991
Description
    Iterate across all the items of a repeater applying a procedure.
    Exhausts the repeater in the process.
\**************************************************************************/

compile_mode :pop11 +strict;

section;

define apprepeater( r, procedure p );
    lvars item;
    until ( r() ->> item ) == termin do
        p( item )
    enduntil
enddefine;

endsection;
