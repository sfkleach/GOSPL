compile_mode :pop11 +strict;

section;

define global xt_preprocess_f();
    lvars str = sprintf( /* top of stack */ );
    lvars managed_flag_on_stack = dup().isboolean;
    { labelString ^str };
    if managed_flag_on_stack then
        swap()
    endif;
enddefine;

endsection
