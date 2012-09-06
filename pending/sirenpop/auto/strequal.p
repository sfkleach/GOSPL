compile_mode :pop11 +strict;

section;

define lconstant cmp( item, str ); lvars item, str;
    dlvars len = datalength( str );
    dlvars n = 0;

    define dlocal cucharout( ch ); lvars ch;
        n + 1 -> n;
        if n > len or ch /== subscrs( n, str ) then
            exitfrom( false, cmp )
        endif;
    enddefine;

    pr( item );
    true;
enddefine;

define global strequal( x, y ); lvars x, y;
    x == y or
    if x.isstring then
        if y.isstring then
            x = y
        else
            cmp( y, x )
        endif;
    elseif y.isstring then
        cmp( x, y )
    else
        cmp( x, y.into_string )
    endif;
enddefine;

endsection
