compile_mode :pop11 +strict;

section;


define hipXYWH( it ); lvars it;
    hipX( it ), hipY( it ), hipWidth( it ), hipHeight( it )
enddefine;


define updaterof hipXYWH( a, b, c, d, it ); lvars a, b, c, d, it;
    ( a, b, c, d ) -> ( hipX( it ), hipY( it ), hipWidth( it ), hipHeight( it ) )
enddefine;


endsection;
