compile_mode :pop11 +strict;

define include_file( f );
    lvars dev = sysopen( f, 0, false );
    repeat
        lvars n = sysread( dev, sysstring.dup.length );
        quitif( n == 0 );
        lvars i;
        fast_for i from 1 to n do
            cucharout( fast_subscrs( i, sysstring ) )
        endfor
    endrepeat
enddefine;
