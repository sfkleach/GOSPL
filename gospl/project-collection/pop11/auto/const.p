;;; Summary: useful combinator, const( x )( y ) => x

compile_mode :pop11 +strict;

section;

define const( x ); lvars x;
    procedure( y ); lvars y;
        x
    endprocedure
enddefine;

endsection;
