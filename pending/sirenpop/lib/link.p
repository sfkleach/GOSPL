compile_mode :pop11 +strict;

section;

vars link = true;   ;;; So it works with uses YUKK!

constant link_undef = consundef( "UNDEFINED_LINK" );

define leftlink =
    newanyproperty(
        [], 8, 1, false,
        false, false, "tmparg",
        link_undef, false
    )
enddefine;

define rightlink =
    copy( leftlink )
enddefine;

define make_link( a, b ); lvars a, b;
    a -> leftlink( b );
    b -> rightlink( a )
enddefine;

define break_link( a, b ); lvars a, b;
    if a == leftlink( b ) and b == rightlink( a ) then
        link_undef -> leftlink( b );
        link_undef -> rightlink( a );
    else
        mishap( 'TRYING TO BREAK LINK BETWEEN UNLINKED PAIR', [ ^a ^b ] )
    endif
enddefine;

endsection;
