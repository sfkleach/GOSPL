compile_mode :pop11 +strict;

section;

define global ensure_number( x ) -> x; lvars x;
    unless isnumber( x ) do
        mishap( 'NUMBER NEEDED', [ ^x ] )
    endunless
enddefine;

endsection;
