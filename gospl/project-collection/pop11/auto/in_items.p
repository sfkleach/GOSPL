;;; Summary: for-extension for iterating over the stack

/**************************************************************************\
Contributor                 Steve Knight, HP Labs.
Date                        14th Oct 1991
Description
    A for-extension for iterating over all the items put on the stack.
\**************************************************************************/

compile_mode :pop11 +strict;

section;

define :for_extension global in_items( varlist, isfast ); lvars varlist, isfast;
    lvars v, e, expr_vars;
    [%
        for v in varlist do
            sysLVARS( v, 0 );
            ;;; for each variable in varlist, compile an expression.  Expressions
            ;;; are separated by (optional) semi-colons.
            sysPUSH( "popstackmark" );
            pop11_comp_expr();
            pop11_try_nextitem( "," ).erase;
            sysCALL( "sysconslist" );
            lvars e = sysNEW_LVAR();
            sysPOP( e );
            e
        endfor;
    %] -> expr_vars;

    ;;; get the "do" syntax word
    pop11_need_nextitem( "do" ) ->;

    ;;; get the loop labels.
    lvars start = sysNEW_LABEL().dup.pop11_loop_start;
    lvars finish = sysNEW_LABEL().dup.pop11_loop_end;

    sysLABEL( start );
    ;;; quit as soon as any of the lists reaches []
    for v, e in varlist, expr_vars do
        sysPUSH( e );
        sysPUSH( "nil" );
        sysCALL( "==" );
        sysIFSO( finish );
        sysPUSH( e );
        sysCALL( "sys_grbg_destpair" );
        sysPOP( e );
        sysPOP( v );
    endfor;

    ;;; execute the loop body
    pop11_comp_stmnt_seq_to( "endfor" ) ->;
    ;;; return to the start
    sysGOTO( start );
    ;;; plant the finish label
    sysLABEL( finish );
enddefine;

endsection;
