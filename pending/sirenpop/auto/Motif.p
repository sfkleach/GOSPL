compile_mode :pop11 +strict;

section;

define global syntax Motif;
    lvars name = readitem();
    sysPUSHQ( name );
    sysPUSHQ( "Motif" );
    sysCALL( "XptWidgetSet" );
    sysCALLS( undef );
enddefine;

endsection
