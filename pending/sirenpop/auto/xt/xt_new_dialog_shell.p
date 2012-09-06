compile_mode :pop11 +strict;

section;

define global xt_new_dialog_shell();
    lvars ( name, parent, arglist, managed ) = xt_new_args();
    XmCreateDialogShell(
        parent,
        name,
        XptArgList( arglist )
    );
    if managed then XtManageChild( dup() ) endif;
enddefine;

endsection
