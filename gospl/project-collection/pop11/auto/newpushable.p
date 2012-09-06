;;; Summary: wraps a repeater so it is updateable (can push items back on)

/**************************************************************************\
Contributor                 Steve Knight
Date                        19 Oct 91
Description
    Promotes a repeater to a pushable repeater.
\**************************************************************************/

compile_mode :pop11 +strict;

section;

;;; G is a generator (repeater)
;;; R is a ref to a false terminated list
define lconstant procedure canpush( G, R ); lvars G, R;
    if fast_cont( R ) then
        sys_grbg_destpair( fast_cont( R ) ) -> fast_cont( R )
    else
        fast_apply( G )
    endif;
enddefine;

define updaterof canpush( item, G, R ); lvars item, G, R;
    conspair( item, fast_cont( R ) ) -> fast_cont( R )
enddefine;

define global constant procedure newpushable( G ) -> result;
    lvars procedure G, result;
    canpush(% G, consref( false ) %) -> result;
    pdprops( G ) -> pdprops( result );
enddefine;

sysprotect( "newpushable" );

endsection;
