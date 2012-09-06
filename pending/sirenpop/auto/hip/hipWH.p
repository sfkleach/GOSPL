
compile_mode :pop11 +strict;

section;

define hipWH( it ); lvars it;
    hipWidth( it ), hipHeight( it )
enddefine;

define updaterof hipWH( a, b, it ); lvars a, b, it;
    ( a, b ) -> ( hipWidth( it ), hipHeight( it ) )
enddefine;


endsection;
