compile_mode :pop11 +strict;

section;

define filterin( L, p ); lvars L, procedure p;
    [%
        lvars i;
        for i in L do
            if p( i ) do i endif
        endfor;
    %]
enddefine;

endsection;
