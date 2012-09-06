;;; Summary: converts any item into a procedure via its own class_apply.

compile_mode :pop11 +strict;

section;

define itemtopd( x );
    if x.isprocedure then
        x
    else
        class_apply( datakey( x ) )(% x %)
    endif
enddefine;

endsection;
