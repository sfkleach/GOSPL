compile_mode :pop11 +strict;

section;

define global syntax exit_action;

    define lvars actioncode() with_props 0; ;;; multiplicity of zero
    enddefine;

    define updaterof actioncode();          ;;; plant action
        pop11_comp_expr_seq();
    enddefine;

    sysLOCAL( actioncode )
enddefine;

endsection;
