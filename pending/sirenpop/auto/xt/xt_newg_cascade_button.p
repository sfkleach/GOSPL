compile_mode :pop11 +strict;

section;

define global xt_newg_cascade_button();
    lvars ( name, parent, arglist, managed ) = xt_new_args();
    XmCreateCascadeButtonGadget(
        parent,
        name,
        XptArgList( arglist )
    );
    if managed then XtManageChild( dup() ) endif;
enddefine;

endsection
