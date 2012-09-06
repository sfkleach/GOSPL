;;; Summary: explode with a count check

compile_mode :pop11 +strict;

section;

define exact_explode( x, n );
    unless #| explode( x ) |# == n do
        mishap( x, n, 2, 'Wrong number of items after explode' )
    endunless
enddefine;

endsection;
