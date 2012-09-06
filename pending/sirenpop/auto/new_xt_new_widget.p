compile_mode :pop11 +strict;

section;

define global new_xt_new_widget( wc ); lvars wc;
    procedure( wc ); lvars wc;
        lvars ( name, parent, arglist, managed ) = xt_new_args();
        apply(
            name,
            wc,
            parent,
            XptVaArgList( arglist ),
            managed and XtVaCreateManagedWidget or XtVaCreateWidget
        )
    endprocedure(% wc %)
enddefine;

endsection
