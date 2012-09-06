;;; Summary: adds an item onto the end of a list

compile_mode :pop11 +strict;

section;

define cons_last( x, L );
    [ ^^L ^x ]
enddefine;

endsection;
