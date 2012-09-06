compile_mode :pop11 +strict;

section;

define global xt_new_framed_row_column();
    lvars ( name, parent, arglist, managed ) = xt_new_args();
    lvars make = managed and XtVaCreateManagedWidget or XtVaCreateWidget;
    make(
        name,
        Motif RowColumnWidget,
        make(
            'frame',
            Motif FrameWidget,
            parent,
            XptVaArgList( [] )
        ),
        XptVaArgList( arglist )
    )
enddefine;

endsection
