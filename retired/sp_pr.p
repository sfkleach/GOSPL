compile_mode :pop11 +strict;

section;

define sp_pr( x );
    cucharout( `\s` );
    chain( x, pr );
enddefine;

endsection;
