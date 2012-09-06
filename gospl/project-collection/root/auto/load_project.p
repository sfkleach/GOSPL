;;; Summary: syntax for loading a project from a directory.

compile_mode :pop11 +strict;

section;

define syntax load_project;
    dlocal popnewline = true;
    lvars s = rdstringto( [ ^newline ; ] );
    ";" :: proglist -> proglist;
    sysPUSHQ( s );
    sysCALL( "load_project_warning" );
    sysPUSHQ( s );
    sysCALL( "sys_load_project" );
enddefine;

endsection;
