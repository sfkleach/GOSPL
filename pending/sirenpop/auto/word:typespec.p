compile_mode :pop11 +strict;

section;

lconstant check_word = identfn(% () %);

procedure( x ) -> x; lvars x;
    unless x.isword do
        mishap( 'WORD NEEDED', [ ^x ] )
    endunless
endprocedure -> check_word.updater;

p_typespec word : full # check_word;

endsection;
