;;; Summary: like maplist but for repeaters

/**************************************************************************\
Contributor                 Steve Knight
Date                        19 Oct 91
Description
    Convert a repeater so that each element "i" of the original repeater
    becomes "f(i)".
\**************************************************************************/

compile_mode :pop11 +strict;

section;

define maprepeater( procedure R, procedure F );

    procedure( r, f );
        unless dup( fast_apply( r ) ) == termin do
            fast_apply( f )
        endunless
    endprocedure(% R, F %)

enddefine;

endsection;
