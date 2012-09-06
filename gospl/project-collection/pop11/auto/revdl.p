;;; Explodes a list onto the stack in reverse order. 

compile_mode :pop11 +strict;

section;

define revdl( L );
    unless null( L ) do
        lvars it = fast_destpair( L ) -> L;
        revdl( L );
        it
    endunless
enddefine;

endsection;
