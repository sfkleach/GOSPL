compile_mode :pop11 +strict;
section;

define global substitute_==( a, b, seq ); lvars a, b, seq;

    define lconstant rep( x ); lvars x;
        x == a and b or x
    enddefine;

    if seq.isvectorclass then
        class_cons( seq.datakey )(#| appdata( seq, rep ) |#)
    elseif seq.islist then
        [% applist( seq, rep ) %]
    else
        mishap( 'SEQUENCE NEEDED', [^seq] )
    endif
enddefine;

endsection;
