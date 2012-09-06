compile_mode :pop11 +strict;

section;

define global no_dupls( L ); lvars L;
    [%
        until null( L ) do
            lvars i = destpair( L ) -> L;
            unless lmember( i, L ) do i endunless
        enduntil;
    %]
enddefine;

endsection;
