compile_mode :pop11 +strict;

section;

define read_resource( file, cvt ) -> ( procedure props, procedure data );

    lvars procedure cvtproc = cvt or identfn;

    ;;; Find where the first non-space character starts after -a- and
    ;;; stops before -b- in L.  Return indexes suitable for substring.
    define trim( a, b, L );
        lvars y;
        lvars x = false;
        lvars i;
        for i from a to b do
            unless is_white_space( subscrs( i, L ) ) do
                i -> x;
                for i from b by -1 to x do
                    unless is_white_space( subscrs( i, L ) ) do
                        return( x, i - x + 1 )
                    endunless
                endfor;
                mishap( 'Internal error', [] )
            endunless
        endfor;
        return( b + 1, 0 )
    enddefine;

    define convert( m, n, str );
        consword( cvtproc( substring( trim( m, n, str ), str ) ) )
    enddefine;

    newanyproperty(
        [], 8, 1, false,
        false, false, "perm",
        [], false
    ) -> props;

    if file.isdevice then
        file.discin.incharline
    elseif file.isprocedure then
        file
    else
        file.discinline
    endif -> data;

    lvars L;
    for L from_repeater data do
        quitif( L.datalength == 0 );
        lvars n = locchar( `:`, 1, L );
        unless n do
            newpushable( data ) -> data;
            L -> data();
            quitloop;
        endunless;
        lvars w = convert( 1, n-1, L );
        [% props( w ).dl, substring( trim( n+1, L.datalength, L ), L ) %] -> props( w );
    endfor;
enddefine;

endsection;
