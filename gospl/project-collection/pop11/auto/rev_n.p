;;; Summary: reverses order of top N items of the stack

/**************************************************************************\
Contributor                 Steve Knight
Date                        17 Oct 91
Description
    Reverse the top N items of the stack.  Used to avoid turning over store
    unnecessarily & to enable the reversal of arbitrary data objects.  e.g.
    reversing a string is "consstring(#| s.deststring.rev_n |#)"
\**************************************************************************/

section;
define global vars procedure rev_n( n ); lvars n;
    if fi_check( n, 0, false ) == 0 then
        n
    else
        lvars p = conspair( [] );   ;;; get initial pair.
        lvars q = p;
        fast_repeat n fi_- 1 times
            conspair( [] ) ->> fast_back( q ) -> q;
        endrepeat;
        sys_grbg_destlist( p );
    endif;
enddefine;
sysprotect( "rev_n" );
endsection;
