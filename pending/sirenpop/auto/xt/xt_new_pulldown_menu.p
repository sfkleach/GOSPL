compile_mode :pop11 +strict;

section;

define global xt_new_pulldown_menu();
    lvars ( name, parent, arglist, managed ) = xt_new_args();
    XmCreatePulldownMenu(
        parent,
        name,
        XptArgList( arglist )
    );
    if managed then XtManageChild( dup() ) endif;
enddefine;

endsection
