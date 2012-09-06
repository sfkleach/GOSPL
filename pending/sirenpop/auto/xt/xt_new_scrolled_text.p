compile_mode :pop11 +strict;

section;

;;; Force the procedures associated with the TextWidget to be loaded.
lconstant dummy = XptWidgetSet( "Motif" )( "TextWidget" );

define global xt_new_scrolled_text();
    lvars ( name, parent, arglist, managed ) = xt_new_args();
    XmCreateScrolledText(
        parent,
        name,
        XptArgList( arglist )
    );
    if managed then XtManageChild( dup() ) endif;
enddefine;

endsection;
