compile_mode :pop11 +strict;

section;

define global chop_string( str ); lvars str;

    define lconstant gather( n ); lvars n;
        if n > 0 then
            consstring( n )
        endif;
    enddefine;

    lvars count = 0;
    lvars i;
    for i in_string str do
        if i == ` ` then
            gather( count );
            0 -> count;
        else
            i;
            count + 1 -> count;
        endif;
    endfor;
    gather( count );
enddefine;

endsection
