compile_mode :pop11 +strict;
section;

define filter( seq, predicate );
    lvars x, predicate, seq;
    if seq.isvectorclass then
        class_cons( seq.datakey )(#|
            for x in_vectorclass seq do
                if predicate( x ) then
                    x
                endif
            endfor
        |#)
    else
        [% for x in seq do if predicate( x ) then x endif endfor %]
    endif
enddefine;

endsection;
