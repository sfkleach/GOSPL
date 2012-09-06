compile_mode :pop11 +strict;

section;

define global hip_children( x ); lvars x;
    [% hip_app_children( x, identfn ) %]
enddefine;

endsection;
