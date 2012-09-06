compile_mode :pop11 +strict;

section;

lconstant procedure table =
    newproperty( [], 16, false, "perm" );

define global xt_gc_protect( w ); lvars w;
    true -> table( w );
    XtAddCallback(
        w,
        XmN destroyCallback,
        procedure( w, c, d ); lvars w, c, d;
            false -> table( w )
        endprocedure,
        false
    );
enddefine;

define global xt_gc_forget( w ); lvars w;
    false -> table( w )
enddefine;

endsection
