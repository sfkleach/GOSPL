;;; Summary: permits a crude but effective form of in-lining.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Title       :   In-line procedure definitions
;;; Author      :   Steve Knight
;;; Date        :   Wed Jan 24, 1990
;;; Revised     :   19 Sept 93 by Steve Knight
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

compile_mode :pop11 +strict;

section;

lconstant procedure (
    sys_sysCALLQ    = sysCALLQ,
    sys_sysCALL     = sysCALL,
    sys_sysUCALL    = sysUCALL,
    sys_sysUCALLQ   = sysUCALLQ
);

global constant procedure in_line =
    newproperty( [], 20, false, false );

lconstant redefining =
    [sysCALLQ sysCALL sysUCALL sysUCALLQ];
applist( redefining, sysunprotect );

define global sysCALLQ( p ); lvars p, q;
    if in_line( p ) ->> q then
        chain( q )
    else
        chain( p, sys_sysCALLQ )
    endif;
enddefine;

define updaterof sysCALLQ() with_nargs 1;
    sysUCALLQ()
enddefine;

define global sysUCALLQ( p ); lvars p, q;
    if (in_line( p ) ->> q) and (updater( q ) ->> q) then
        chain( q )
    else
        chain( p, sys_sysUCALLQ )
    endif;
enddefine;

;;; With sysCALL, we want to capture the relatively common case of
;;; constant identifiers which have been assigned-to.  Note that the test
;;;     isconstant( id )
;;; means that id has been assigned-to (see REF IDENT/isconstant).
define global sysCALL( w ); lvars w;
    lvars id = sys_current_ident( w );
    if
        isident( id ) == "perm" and
        isconstant( id ) == true
    then
        chain( idval( id ), sysCALLQ )
    else
        chain( w, sys_sysCALL )
    endif
enddefine;

define updaterof sysCALL() with_nargs 1;
    sysUCALL()
enddefine;

define global sysUCALL( w ); lvars w;
    lvars id = sys_current_ident( w );
    if
        isident( id ) == "perm" and
        isconstant( id ) == true
    then
        chain( idval( id ), sysUCALLQ )
    else
        chain( w, sys_sysUCALL )
    endif
enddefine;

applist( redefining, sysprotect );

endsection;
