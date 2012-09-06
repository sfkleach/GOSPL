compile_mode :pop11 +strict;

section;

define propsheet_xy( sheet ) -> ( x, y ); lvars x, y, sheet;
    lvars _ ;
    XptWidgetCoords( sheet.XtParent ) -> ( x, y, _, _ );
enddefine;

define updaterof propsheet_xy( x, y, sheet ); lvars x, y, sheet;
    x, y, false, false -> XptWidgetCoords( sheet.XtParent );
enddefine;

endsection;
