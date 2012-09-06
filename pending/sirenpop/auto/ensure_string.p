compile_mode :pop11 +strict;

section;

define global ensure_string( x ) -> x; lvars x;
    check_string( x )
enddefine;

endsection;
