compile_mode :pop11 +strict;

section;

define force_drawings_to_share_data( d, m ); lvars d, m;
    XptValue( d, XtN draw ) -> XptValue( m, XtN draw )
enddefine;

endsection;
