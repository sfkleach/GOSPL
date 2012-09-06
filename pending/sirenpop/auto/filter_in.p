compile_mode :pop11 +strict;

section;

define global filter_in( L, p ); lvars L, procedure p;
    if islist( L ) then
        [%
            lvars i;
            for i in L do
                if p( i ) then
                    i
                endif
            endfor
        %]
    elseif isvectorclass( L ) then
        lvars k = datakey( L );
        lvars procedure subscr = class_subscr( k );
        class_cons( k )(#|
            lvars n;
            for n from 1 to datalength( L ) do
                lvars i = subscr( n, L );
                if p( i ) then
                    i
                endif
            endfor;
        |#)
    else
        mishap( 'SEQUENCE NEEDED', [ ^L ] )
    endif;
enddefine;

endsection;
