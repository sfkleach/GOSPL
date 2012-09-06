;;; Explodes and destroys an expanded list.
section;
define global constant procedure sys_grbg_destlist( L ); lvars L;
    #|
    until L == [] do
        sys_grbg_destpair( L ) -> L
    enduntil
    |#
enddefine;
sysprotect( "sys_grbg_destlist" );
endsection;
