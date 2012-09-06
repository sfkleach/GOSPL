compile_mode :pop11 +strict;

section;

lconstant check_integral = identfn(% () %);

procedure( x ) -> x; lvars x;
    unless x.isintegral do
        mishap( 'INTEGRAL VALUE NEEDED', [^x] )
    endunless
endprocedure -> check_integral.updater;

p_typespec integral : full # check_integral;

endsection;
