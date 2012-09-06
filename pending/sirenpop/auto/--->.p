compile_mode :pop11 +strict;

section;

uses fmatches;
define syntax 8 --->;

    define lconstant oops();
        mishap( 'FAILED MATCH', [] )
    enddefine;

    pop_expr_inst( pop_expr_item );
    fmatches_listread();
    if pop11_try_nextreaditem( "where" ) then
        sysPROCEDURE( false, 0 );
            pop11_comp_prec_expr( pop_expr_prec, pop_expr_update );
        sysENDPROCEDURE().sysPUSHQ;
    endif;
    sysCALLQ( fmatches_domatch );

    lvars ok = sysNEW_LABEL();
    sysIFSO( ok );
    sysCALLQ( oops );
    sysLABEL( ok );
enddefine;

endsection;
