compile_mode :pop11 +strict;

section;

define XY( it ); lvars it;
    hipX( it );
    hipY( it )
enddefine;

define updaterof XY( x, y, it ); lvars x, y, it;
    x -> hipX( it );
    y -> hipY( it );
enddefine;

endsection;
