compile_mode :pop11 +strict;

section;

define global filter_out( L, p ); lvars L, procedure p;
    if islist( L ) then
        [%
            lvars i;
            for i in L do
                unless p( i ) then
                    i
                endunless
            endfor
        %]
    elseif isvectorclass( L ) then
        lvars k = datakey( L );
        lvars procedure subscr = class_subscr( k );
        class_cons( k )(#|
            lvars n;
            for n from 1 to datalength( L ) do
                lvars i = subscr( n, L );
                unless p( i ) then
                    i
                endunless
            endfor;
        |#)
    else
        mishap( 'SEQUENCE NEEDED', [ ^L ] )
    endif;
enddefine;

endsection;
