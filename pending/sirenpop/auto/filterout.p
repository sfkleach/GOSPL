compile_mode :pop11 +strict;

section;

define filterout( L, p ); lvars L, procedure p;
    [%
        lvars i;
        for i in L do
            unless p( i ) do i endunless
        endfor;
    %]
enddefine;

endsection;
