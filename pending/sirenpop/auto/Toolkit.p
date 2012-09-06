compile_mode :pop11 +strict;

section;

define global syntax Toolkit;
    lvars name = readitem();
    sysPUSHQ( name );
    sysPUSHQ( "Toolkit" );
    sysCALL( "XptWidgetSet" );
    sysCALLS( undef );
enddefine;

endsection
