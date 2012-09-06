compile_mode :pop11 +strict;

section;

define hipXY( it ); lvars it;
    hipX( it ), hipY( it )
enddefine;

define updaterof hipXY( a, b, it ); lvars a, b, it;
    ( a, b ) -> ( hipX( it ), hipY( it ) )
enddefine;


endsection;
