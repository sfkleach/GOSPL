compile_mode :pop11 +strict;

section;

define split_with( line, separators ); lvars line, separators;
    lvars ch, k = 0;
    for ch in_string line do
        if locchar( ch, 1, separators ) then
            unless k == 0 do
                consstring( k );
                0 -> k;
            endunless
        else
            ch;
            k fi_+ 1 -> k;
        endif
    endfor;
    unless k == 0 do
        consstring( k );
    endunless
enddefine;

endsection;
