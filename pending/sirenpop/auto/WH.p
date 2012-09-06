compile_mode :pop11 +strict;

section;

define WH( it ); lvars it;
    hipWidth( it );
    hipHeight( it )
enddefine;

define updaterof WH( x, y, it ); lvars x, y, it;
    x -> hipWidth( it );
    y -> hipHeight( it );
enddefine;

endsection;
