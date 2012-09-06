compile_mode :pop11 +strict;

section;

lconstant check_procedure = identfn(% () %);

procedure( x ) -> x; lvars x;
    unless x.isprocedure do
        mishap( 'PROCEDURE NEEDED', [ ^x ] )
    endunless
endprocedure -> check_procedure.updater;

p_typespec procedure : full # check_procedure;

endsection;
