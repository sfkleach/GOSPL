compile_mode :pop11 +strict;

section;

define syntax 11 ->@ ;
    if
        pop_expr_inst == sysPUSH or
        pop_expr_inst == sysPUSHQ or
        pop_expr_inst == sysPUSHS
    then
        ;;; Just avoid doing the PUSH.  A somewhat pointless optimisation
        ;;; as it is too weak to be helpful.
        pop11_FLUSHED -> pop_expr_inst;
    else
        pop_expr_inst( pop_expr_item );       ;;; flush buffer
        sysERASE -> pop_expr_inst;
        undef -> pop_expr_item;
    endif
enddefine;

endsection;
