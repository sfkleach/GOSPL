compile_mode :pop11 +strict;

section;

;;; Ensure that convenience functions associated with Form Widget are
;;; loaded.
erase( XptWidgetSet( "Motif" )( "FormWidget" ) );

define global xt_new_form();
    lvars ( name, parent, arglist, managed ) = xt_new_args();
    XmCreateForm( parent, name, arglist.XptArgList );
    if managed then
        XtManageChild( dup() )
    endif;
enddefine;

endsection
