compile_mode :pop11 +strict;

section;

define global ved_popmemlim();
    lvars n = strnumber( vedargument );
    if n then
        n -> popmemlim;
        vedputmessage( sprintf( 'POPMEMLIM = %p', [ ^popmemlim ] ) )
    else
        false -> popmemlim;
        vedputmessage( sprintf( 'POPMEMLIM SET TO MAXIMUM ( = %p )', [ ^popmemlim] ) )
    endif;
enddefine;

endsection
