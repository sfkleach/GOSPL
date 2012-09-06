compile_mode :pop11 +strict;

section;

define sys_grbg_tree( L ); lvars L;
    lvars N = stacklength();
    L;
    until stacklength() == N do
        lvars L = ();
        if L.ispair then
            L.sys_grbg_destpair
        endif;
    enduntil;
enddefine;

endsection;
