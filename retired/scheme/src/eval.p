;;; -- EVAL -----------------------------------------------------------------
;;; This routine causes an s-expression to be evaluated within the top-level
;;; environment.  Naturally, compilation is driven by tables.
;;;

vars procedure ( valid_sexp, plant_sexp );

define eval_scheme( s ); lvars s;
    procedure;
        valid_sexp( s );
        plant_sexp( s, newdefaultContext(), nil );
        sysEXECUTE();
    endprocedure.sysCOMPILE;
enddefine;

;;; -- consistency check on special table

fast_appproperty(
    special_table,
    procedure( x, s ); lvars x, s;
        unless s.validSpecial and s.plantSpecial do
            internal_error()
        endunless;
    endprocedure
);
