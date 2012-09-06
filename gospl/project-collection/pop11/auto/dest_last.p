compile_mode :pop11 +strict;

section;

define dest_last( L ) -> ( it, L );
    lvars N = destlist( L );
    if N == 0 then
        mishap( 0, 'Unexpected empty list' )
    else
        ;;; stacklength() >= 1 and N >= 1 and isinteger( N )
	() -> it;
        conslist( N fi_- 1 ) -> L;
    endif
enddefine;

endsection;
