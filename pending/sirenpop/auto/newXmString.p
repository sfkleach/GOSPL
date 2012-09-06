compile_mode :pop11 +strict;

section;

;;; Converts any Pop11 item to a motif string.
define global newXmString( x ); lvars x;
    dlocal cucharout = identfn;
    XmStringCreateLtoR(
        consstring(#| pr( x ); 0 |#),
        XmSTRING_DEFAULT_CHARSET
    )
enddefine;

endsection;
