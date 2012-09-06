compile_mode :pop11 +strict;

section;

define lconstant bitval_to_bool( bit );
    bit /== 0
enddefine;

define updaterof bitval_to_bool( bool );
    unless bool do
        0
    elseif bool == true then
        1
    else
        mishap( bool, 1, 'Boolean needed for flag field' )
    endunless
enddefine;

p_typespec flag : 1 # bitval_to_bool;

endsection;
