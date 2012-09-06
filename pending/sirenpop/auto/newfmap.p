compile_mode :pop11 +strict;

section;

define newfmap( n ); lvars n;

    define lconstant fmap( it, data ); lvars it, data;
        lvars k = 1;
        lvars len = datalength( data );
        until k fi_>= len do
            returnif( fast_subscrv( k, data ) == it )( fast_subscrv( k fi_+ 1, data ) );
            k fi_+ 2 -> k;
        enduntil;
        false
    enddefine;

    consvector( n ) -> n;
    fmap(% n %)
enddefine;

endsection;
