compile_mode :pop11 +strict;

section;

define global kmember( x, L ); lvars x, L;
    lvars i, k = 0;
    for i in L do
        k fi_+ 1 -> k;
        if x == i then
            return( k )
        endif
    endfor;
    return( false )
enddefine;

endsection;
