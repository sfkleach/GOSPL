;;; Summary: measure heap space consumed -- used at PLUG92

compile_mode :pop11 +strict;

section;

;;; Repeatedly garbage collect until memory usage is stable.  It is possible
;;; for the garbage collector to get into an unstable loop -- compromise
;;; in this unusual situation by quitting after 16 garbage collections.
define lconstant full_gc();
    lvars mem = popmemused;
    repeat 16 times
        sysgarbage();
        quitif( mem == popmemused );
    endrepeat;
enddefine;

;;; Given the procedure to execute, report on how much space it consumes.
;;;
define lconstant space_tests( p ); lvars procedure p;
    setstacklength( 0 );
    full_gc();
    lvars mem = popmemused;
    p();
    full_gc();
    lvars used = popmemused - mem;
    lvars n = stacklength();
    setstacklength( 0 );
    printf( '    Heap   : %p longwords\n', [% used - n %] );
    printf( '    Stack  : %p longwords\n', [^n] );
enddefine;

define syntax SPACE;
    dlocal popnewline = true;

    unless popexecute do
        mishap( 'SPACE only works at top-level', [] )
    endunless;

    sysPROCEDURE( "SPACE", 0 );
    pop11_comp_stmnt_seq_to( newline ).erase;
    ";" :: proglist -> proglist;
    sysENDPROCEDURE().sysPUSHQ;
    sysCALLQ( space_tests );
enddefine;

endsection;
