compile_mode :pop11 +strict;

section;

define xt_new_popup_shell();
    lvars ( name, parent, arglist, managed ) = xt_new_args();
    XtCreatePopupShell(
        name,
        Motif DialogShellWidget,
        parent,
        XptArgList( arglist )
    );
    if managed then XtManageChild( dup() ) endif;
enddefine;

endsection
