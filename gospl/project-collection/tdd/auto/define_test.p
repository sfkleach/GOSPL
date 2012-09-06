compile_mode :pop11 +strict;

section;

define :define_form test;
    dlocal pop_syntax_only = pop_debugging;
    lvars name = itemread();
    unless name.isstring do
        mishap( 'Name is not a string', [ ^name ] );
    endunless;
    sysPROCEDURE();
    sysPUSHQ( sysENDPROCEDURE() );
    sysPUSHQ( name );
    sysPUSHQ( popfilename );
    sysCALLQ( pop_test_table );
    sysUCALLS( "'define:test'" );
enddefine;


endsection;
