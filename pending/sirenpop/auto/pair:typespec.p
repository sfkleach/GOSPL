compile_mode :pop11 +strict;

section;

define lconstant check_pair =
    identfn(% () %)
enddefine;

define updaterof check_pair( x ) -> x; lvars x;
    unless x.ispair do
        mishap( 'PAIR NEEDED', [ ^x ] )
    endunless
enddefine;

p_typespec pair : full # check_pair;

endsection;
