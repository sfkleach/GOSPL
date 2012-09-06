compile_mode :pop11 +strict;

section;

define slice( a, b, x );
    if isinteger( a ) and isinteger( b ) then
        if isstring( x ) then
            lvars L = false;
            if a fi_< 0 then
                datalength( x ) -> L;
                L + 1 - a -> a;
            endif;
            if b fi_< 0 then
                L or datalength( x ) -> L;
                L + a - b -> b;
            endif;
            substring( a, b, x )
        elseif isvectorclass( x ) then
            lvars L = datalength( x );
            lvars k = datakey( x );
            lvars procedure ss = class_fast_subcr( k );

        elseif islist( x ) then
        endif
    else
        mishap( 'Integer indexes needed', [ ^a ^b ] )
    endif
enddefine;

endsection;
