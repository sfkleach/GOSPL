compile_mode :pop11 +strict;

section;

define global isvectorclasskey( k );
    returnunless( k.iskey )( false );
    lvars s = k.class_field_spec;
    s and not( s.islist )
enddefine;

endsection;
