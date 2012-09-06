compile_mode :pop11 +strict;

section;

define syntax uses_project_collection;
    dlocal popnewline = true;
    lvars s = rdstringto( [ ^newline ; ] );
    ";" :: proglist -> proglist;
    sysPUSHQ( s );
    sysCALL( "sys_uses_project_collection" );
enddefine;

endsection;
