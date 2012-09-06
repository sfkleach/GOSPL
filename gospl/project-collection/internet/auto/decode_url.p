compile_mode :pop11 +strict;

section;

lconstant ( _1, protocol ) = regexp_compile( '@^@(@[^:@]@*@):' );
lconstant ( _2, machine ) = regexp_compile( '//@(@[^:/@]@*@)' );
lconstant ( _3, port ) = regexp_compile( ':@(@[0-9@]@*@)' );

define decode_url( url ); lvars url;
    lvars start = 1;

    define use_re( re, default );
        returnif( start > length( url ) )( default );
        lvars ( s, n ) = re( start, url, false, false );
        if s then
            substring( regexp_subexp( 1, re ) );
            s + n -> start;
        else
            default
        endif
    enddefine;

    use_re( protocol, false );
    lvars mc = use_re( machine, '' );
    mc.length > 0 and mc;
    strnumber( use_re( port, '' ) );
    if start <= length( url ) then
        substring( start, length( url ) - start + 1, url )
    else
        false
    endif
enddefine;

endsection;
