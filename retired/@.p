compile_mode :pop11 +strict;

section;

define syntax 8.5  @;
    pop_expr_inst( pop_expr_item );
    pop11_FLUSHED -> pop_expr_inst;
    lvars operator = readitem();
    if operator == termin then
        mishap( 'Unexpected end of input after "@" operator', [] )
    else
        pop11_comp_prec_expr( 171, false ).erase;
        sysCALL( operator )
    endif
enddefine;

endsection;
