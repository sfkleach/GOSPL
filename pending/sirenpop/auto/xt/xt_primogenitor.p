compile_mode :pop11 +strict;

section;

define global xt_primogenitor( w ) -> w; lvars w;
    lvars p;
    while XtParent( w ) ->> p do
        p -> w
    endwhile
enddefine;

endsection
