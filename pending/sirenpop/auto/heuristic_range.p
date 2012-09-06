compile_mode :pop11 +strict;

section;

define global heuristic_range( lo, hi ); lvars lo, hi;

    define lconstant order_of_mag( k ); lvars k;
        lconstant log10 = log( 10 );
        10 ** floor( log( k ) / log10 )
    enddefine;

    lvars r = hi - lo;
    if r = 0 then
        ( lo, hi )
    else
        lvars mag = order_of_mag( r );
        (
            floor( lo / mag ) * mag,
            ceiling( hi / mag ) * mag
        )
    endif
enddefine;

endsection;
