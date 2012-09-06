;;; Summary: efficient version of length( X ) >= N

compile_mode :pop11 +strict;

section;

define length_>=( L, n );
    if islist( L ) then
        if isinteger( n ) then
            repeat
                returnif( n fi_<= 0 )( true );
                returnif( null( L ) )( false );
                fast_back( L ) -> L;
                n fi_- 1 -> n;
            endrepeat
        elseif isintegral( n ) then
            ;;; In practice, lists can never attain a biginteger length ...
            ;;; ... unless it is a dynamic list or the biginteger is -ve.
            ;;; So, you just have to do this properly and repeat the
            ;;; code.
            repeat
                returnif( n <= 0 )( true );
                returnif( null( L ) )( false );
                fast_back( L ) -> L;
                n - 1 -> n;
            endrepeat
        else
            mishap( 'Integer (or biginteger) required', [ ^n ] )
        endif
    elseif isvectorclass( L ) then
        datalength( L ) >= n
    elseif isword( L ) then
        length_>=( L, n )
    else
        mishap( 'List or vectorclass needed', [ ^L ] )
    endif
enddefine;

endsection;
