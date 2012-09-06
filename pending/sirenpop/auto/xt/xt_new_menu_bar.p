compile_mode :pop11 +strict;

section;

define global xt_new_menu_bar();
    lvars ( name, parent, arglist, managed ) = xt_new_args();
    XmCreateMenuBar(
        parent,
        name,
        XptArgList( arglist )
    );
    if managed then XtManageChild( dup() ) endif;
enddefine;

endsection
