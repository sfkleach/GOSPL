compile_mode :pop11 +strict;

section;

define maybe_text_file( f );
    lvars dev = sysopen( f, 0, false, `A` );
    if dev then
        lvars n = sysread( dev, bigstring.dup.datalength );
        lvars ch, k;
        for ch with_index k in_string bigstring do
        &_while k <= n do
            nextif( 9 <= ch and ch <= 13 );
            returnif( ch < 32 or ch >= 127 )( false )
        endfor;
        true
    else
        false
    endif
enddefine;

endsection;
