compile_mode :pop11 +strict;

section;

define lconstant check_boolean( x ); lvars x;
    x == 1
enddefine;

define updaterof check_boolean( x ); lvars x;
    if isboolean( x ) then
        x and 1 or 0
    else
        mishap( 'BOOLEAN NEEDED', [ ^x ] )
    endif
enddefine;

p_typespec boolean : 1 # check_boolean;

endsection;
