compile_mode :pop11 +strict;

section;

define first_resource( w, props );
    lvars L = w.props;
    not( L.null ) and L.fast_front
enddefine;

endsection;
