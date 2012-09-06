compile_mode :pop11 +strict;

section;

define global ensure_integer( x ) -> x; lvars x;
    unless isinteger( x ) do
        mishap( 'INTEGER NEEDED', [ ^x ] )
    endunless;
enddefine;

endsection;
