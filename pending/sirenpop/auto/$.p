compile_mode :pop11 +strict;

section;

define global syntax $ ;
    sysPUSHQ( readitem().to_string );
    sysCALL -> pop_expr_inst;
    "systranslate" -> pop_expr_item;
enddefine;

endsection
