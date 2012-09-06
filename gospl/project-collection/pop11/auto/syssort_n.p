/**************************************************************************\
Contributor                 Steve Knight
Date                        20 Oct 91
Description
    Sorts a counted-group of items on top of the stack.
\**************************************************************************/
section;
define global vars procedure syssort_n( n, cmp ); lvars n, cmp;
    lvars L = conslist( n );
    sys_grbg_destlist( syssort( L, false, cmp ) );
enddefine;
sysprotect( "syssort_n" );
endsection;
