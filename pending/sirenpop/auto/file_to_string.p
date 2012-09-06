compile_mode :pop11 +strict;

section;

define file_to_string( fname ) -> answer; lvars fname, answer;
    false -> answer;
    lvars dev = sysopen( fname, 0, false, `A` );
    if dev then
        lvars n =  sysfilesize( dev );
        inits( n ) -> answer;
        lvars m = sysread( dev, 1, answer, n );
        unless n ==# m then
            mishap( 'FAILED TO READ WHOLE FILE', [ ^fname ] )
        endunless;
    else
        mishap( 'CANNOT ACCESS FILE', [ ^fname ] )
    endif;
enddefine;

endsection;
