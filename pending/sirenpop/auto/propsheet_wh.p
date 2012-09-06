compile_mode :pop11 +strict;

section;

define propsheet_wh( sheet ) -> ( w, h ); lvars w, h, sheet;
    lvars _ ;
    XptWidgetCoords( sheet.XtParent ) -> ( _, _, w, h );
enddefine;

define updaterof propsheet_wh( w, h, sheet ); lvars w, h, sheet;
    false, false, w, h -> XptWidgetCoords( sheet.XtParent );
enddefine;

endsection;
