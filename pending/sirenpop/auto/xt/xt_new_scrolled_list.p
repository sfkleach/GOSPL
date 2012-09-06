compile_mode :pop11 +strict;

section;

define global xt_new_scrolled_list();
    lvars ( name, parent, arglist, managed ) = xt_new_args();
    XmCreateScrolledList( parent, name, XptArgList( arglist ) );
    if managed then
        XtManageChild( dup() )
    endif;
enddefine;

endsection
