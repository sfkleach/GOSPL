compile_mode :pop11 +strict;

section;

define global xt_new_top_level_shell() -> shell with_nargs 1; lvars shell;
    lvars arglist = xt_new_arglist();
    lvars display =
        if dup().isstring then
            XptDefaultDisplay
        else
            ()
        endif;
    lvars name = ();

    lvars class = name.copy;
    unless name.length == 0 do
        name( 1 ).lowertoupper -> class( 1 )
    endunless;

    XtVaAppCreateShell(
        name,
        class,
        Toolkit TopLevelShellWidget,
        display,
        XptVaArgList( arglist )
    ) -> shell;
enddefine;

endsection
