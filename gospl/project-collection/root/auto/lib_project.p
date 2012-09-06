compile_mode :pop11 +strict;

section;

define syntax lib_project;
    dlocal popnewline = true;
    lvars file = rdstringto( [ ^newline ; ] );
    ";" :: proglist -> proglist;
    sysPUSHQ( file );
    sysCALL( "lib_project_warning" );
    sysPUSHQ( file );
    sysCALL( "sys_uses_project" );
enddefine;


endsection;
