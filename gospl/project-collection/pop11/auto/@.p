;;; Summary: invaluable infix call syntax - write f(x,y) as x @f y

compile_mode :pop11 +strict;

section;

;;; EXCERPT FROM REF * POPCOMPILE ....

/*
        The ____prec argument is a  value specifying the limit for  operator
        precedences in this  expression; for efficiency  reasons, it  is
        supplied not in the normal identprops format, but in the form in
        which precedences are actually represented internally. If ______idprec
        is a normal identprops  precedence, then the corresponding  ____prec
        value is the positive integer given by

                ____prec = intof(abs(______idprec) * 20)
                            + (if ______idprec > 0 then 1 else 0 endif)

        (E.g. an ______idprec of 4  will give a ____prec  of 81, whereas -4  would
        give 80.) Since an identprops precedence can range between -12.7
        and 12.7,  the normal  range for  ____prec  is 2  - 255;  any  value
        greater than 255 is  guaranteed to include  all operators in  an
        expression.
*/

;;; 10 needs pop11_comp_prec_expr( 201, false )
;;; 8.5 needs pop11_comp_prec_expr( 171, false )

define syntax 8.5 @;
    pop_expr_inst( pop_expr_item );
    pop11_FLUSHED -> pop_expr_inst;
    lvars operator = readitem();
    if operator == termin then
        mishap( 'Unexpected end of input after "@" operator', [] )
    elseif operator == "(" then
        dlocal pop_new_lvar_list;
        lvars x = sysNEW_LVAR();
        pop11_comp_expr_to( ")" ) -> _;
        sysPOP( x );
        pop11_comp_prec_expr( 171, false ).erase;
        sysCALL( x );
    else
        pop11_comp_prec_expr( 171, false ).erase;
        sysCALL( operator )
    endif
enddefine;

endsection;
