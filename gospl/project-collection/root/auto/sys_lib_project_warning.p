compile_mode :pop11 +strict;

section;

define sys_lib_project_warning( proj_name );
    sysprmessage(
        0,                              ;;; no other args
        proj_name, 'LOADING LIB PROJECT',   ;;; header + message
        1                               ;;; detail level
    )
enddefine;

endsection;
