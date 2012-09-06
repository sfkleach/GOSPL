compile_mode :pop11 +strict;

section;

define locitem( x, v ); lvars x, v;
    if v.isvectorclass then
        lvars i, k = 0;
        for i in_vectorclass v do
            k fi_+ 1 -> k;
            if i = x then
                return( k )
            endif;
        endfor;
    elseif v.islist then
        lvars i, k = 0;
        for i in v do
            k fi_+ 1 -> k;
            if i = x then
                return( k )
            endif;
        endfor
    else
        mishap( 'LIST OR VECTOR NEEDED', [ ^x ^v ] )
    endif;
    false
enddefine;

endsection;
