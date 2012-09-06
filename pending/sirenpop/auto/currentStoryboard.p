compile_mode :pop11 +strict;

uses hipworks;

section;

define global syntax currentStoryboard;
    sysPUSHQ( "currentStoryboard" );
    "hip_system" -> pop_expr_item;
    sysCALL -> pop_expr_inst;
enddefine;

endsection;
