;;; Summary: an is-empty predicate that works on many datatypes

compile_mode :pop11 +strict;

section;

;;; isnull is intended to be an all purpose test for empty.
define isnull( x );
    if isvectorclass( x ) then
        datalength( x ) == 0
    elseif islist( x ) then
        null( x )
    elseif isproperty( x ) then
        datalength( x ) == 0
    else
        mishap( 'isnull does not cover this type (yet)', [ ^x ] )
    endif
enddefine;

endsection;
