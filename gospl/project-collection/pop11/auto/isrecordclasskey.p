compile_mode :pop11 +strict;

section;

define global isrecordclasskey( k );
    returnunless( k.iskey )( false );
    k.class_field_spec.islist
enddefine;

endsection;
