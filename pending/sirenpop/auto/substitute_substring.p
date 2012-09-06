compile_mode :pop11 +strict;

section;

define global substitute_substring( x, y, str ); lvars x, y, str;
    lvars L = datalength( x );
    consstring(#|
        lvars n = 1;
        repeat
            lvars k = issubstring( x, n, str );
            quitunless( k );
            lvars i;
            for i from n to k - 1 do
                subscrs( i, str )
            endfor;
            deststring( y ).erase;  ;;; Could be explode( y ) but I want the check.
            k + L -> n;
        endrepeat;
        lvars i;
        for i from n to datalength( str ) do
            subscrs( i, str )
        endfor
    |#)
enddefine;

endsection
