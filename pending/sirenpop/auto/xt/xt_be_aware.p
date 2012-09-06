compile_mode :pop11 +strict;

section;

define global xt_be_aware( shell_widget ); lvars shell_widget;
    XtRealizeWidget( shell_widget );
    true -> XptBusyCursorFeedback( shell_widget );
    shell_widget.xt_gc_protect;
    XtDestroyWidget -> XptShellDeleteResponse( shell_widget );
enddefine;

endsection
