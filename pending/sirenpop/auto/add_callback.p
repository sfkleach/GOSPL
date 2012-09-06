compile_mode :pop11 +strict;

section;

define lconstant add_smart_callback( widget, resname, callbackproc, client_data ); lvars widget, callbackproc, client_data, resname;

    define lconstant invoke_callbackproc();
        lvars p = deref_ident( callbackproc );
        lvars nargs = pdnargs( p );
        if nargs <= 2 then erase() endif;
        if nargs <= 1 then erase() endif;
        if nargs <= 0 then erase() endif;
        chain( p )
    enddefine;

    XtAddCallback(
        widget,
        resname,
        invoke_callbackproc,
        client_data
    )
enddefine;

define global syntax add_callback;
    lvars callback_name = readitem();
    pop11_need_nextreaditem( "(" ).erase;
    pop11_comp_expr_to( "," ).erase;
    sysPUSHQ( XtNLookup( callback_name <> "Callback", "XmN" ) );
    if pop11_comp_expr_to( [ , ) ] ) == "," then
         pop11_comp_expr_to( ")" ).erase
    else
        sysPUSHQ( false )
    endif;
    sysCALLQ( add_smart_callback )
enddefine;

endsection
