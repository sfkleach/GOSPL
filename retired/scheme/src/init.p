
;;; -- Initial declarations for scheme --------------------------------------

define internal_error();
    mishap( 'This error should NEVER happen, please report', [])
enddefine;

;;; -- Initialisation -------------------------------------------------------

;;; -- Altering itemiser
12 -> item_chartype(`\\`);

;;; -- Forward declarations
constant procedure
    read_scheme         ;;; read a sexp from character repeater
    eval_scheme         ;;; general code planter
    print_scheme        ;;; standrard sexp printer
    display_scheme;     ;;; alternative printer

;;; -- Specials
vars
    default_input_port  ;;; The scheme input port
    default_output_port ;;; The scheme output port
    plant_sexp_arg      ;;; The current s-exp being compiled
    ;

;;; -- Option Flags
vars src_scheme = true;             ;;; should source be retained
vars nil_as_bool_scheme = "warn";   ;;; (true|false|"warn")
vars call_mode_scheme = "proc";     ;;; ("proc"|"data"|"unchecked")
vars time_stats_scheme = false;     ;;; controls the printing of time info
vars opt_tail_call_scheme = true;   ;;; controls tail-call optimisation
vars prdeclare_scheme;              ;;; warns of forward declared variables
vars case_sensitivity_scheme
    = false;                        ;;; ("upper-case" | "lower-case" | false)

define newsrc( src ); lvars src;
    if src_scheme do src else false endif
enddefine;

vars prompt_scheme = '* ';
