compile_mode :pop11 +strict;

section;

define hip_raise( obj ); lvars obj;
    true -> obj.hipIsFirst;
enddefine;

endsection;
