compile_mode :pop11 +strict;

section;

define global xt_new_arglist() -> args; lvars args;
    [] -> args;
    repeat
        lvars item = ( /* top of stack */ );
        if item.isvector then
            if item.datalength >= 1 and subscrv( 1, item ).isword then
                if item.datalength == 2 then
                    conspair( item, args ) -> args
                else
                    [%
                        lvars i;
                        for i from 1 by 2 to item.datalength do
                            {% item( i ), item( i + 1 ) %}
                        endfor
                    % ^^args ] -> args
                endif
            else
                explode( item )
            endif
        else
            item;
            quitloop
        endif;
    endrepeat;
enddefine;

endsection
