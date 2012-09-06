;;; Summary: dl (list explode) with a count check

compile_mode :pop11 +strict;

section;

define exact_dl( L, n );
    unless L.destlist == n do
        mishap( L, n, 2, 'Wrong length list' )
    endunless
enddefine;

endsection;
