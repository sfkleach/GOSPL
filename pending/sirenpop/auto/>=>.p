compile_mode :pop11 +strict;

section;

define global syntax 0.05 >=> ;
    if pop_expr_inst == sysPUSH and pop_expr_item.isword then
        sysPROCEDURE( ">=>", 1 );
        sysLVARS( pop_expr_item, 0 );
        sysPOP( pop_expr_item );
        pop11_comp_prec_expr( 231, false ).erase;
        sysENDPROCEDURE() -> pop_expr_item;
        sysPUSHQ -> pop_expr_inst;
    else
        mishap( 'ARGUMENT TO >=> NOT A WORD', [ ^pop_expr_item ] )
    endif
enddefine;

endsection;
