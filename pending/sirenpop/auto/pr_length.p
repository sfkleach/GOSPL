compile_mode :pop11 +strict;

section;

define global pr_length( it ) -> count; lvars it;
    dlvars count = 0;

    define dlocal cucharout( ch ); lvars ch;
        count + 1 -> count;
    enddefine;

    pr( it );
enddefine;

endsection;
