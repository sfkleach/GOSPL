compile_mode :pop11 +strict;

section;

define sqr_root( x ); lvars x;
    sqrt( max( x, 0.0 ) )
enddefine;

endsection;
