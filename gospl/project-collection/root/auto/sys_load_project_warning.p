compile_mode :pop11 +strict;

section;

define sys_load_project_warning( proj_name );
    sysprmessage(
        0,                              ;;; no other args
        proj_name, 'LOADING PROJECT',   ;;; header + message
        1                               ;;; detail level
    )
enddefine;

endsection;
