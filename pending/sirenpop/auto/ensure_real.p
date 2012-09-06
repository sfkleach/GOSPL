compile_mode :pop11 +strict;

section;

define global ensure_real( x ) -> x; lvars x;
    unless isreal( x ) do
        mishap( 'REAL NEEDED', [ ^x ] )
    endunless
enddefine;

endsection;
