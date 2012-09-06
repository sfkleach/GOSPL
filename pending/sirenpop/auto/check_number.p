compile_mode :pop11 +strict;

section;

define global check_number( n ) -> n; lvars n;
    unless isnumber( n ) do
        mishap( 'NUMBER NEEDED', [^n] )
    endunless
enddefine;

endsection;
