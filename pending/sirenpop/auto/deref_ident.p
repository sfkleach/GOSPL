compile_mode :pop11 +strict;

section;

define global deref_ident( id ) -> id; lvars id;
    while id.isident do
        id.idval -> id
    endwhile
enddefine;

endsection
