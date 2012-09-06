compile_mode :pop11 +strict;

section;

lconstant size = 1024;

define lconstant copy_across( idx_in, dump, result );
    if dump.ispair then
        lvars ( d, rest ) = dump.destpair;
        lvars idx_out = copy_across( idx_in, rest, result );
        lvars i;
        for i from 1 to size do
            subscrs( i, d ) -> subscrs( idx_out + i, result )
        endfor;
        idx_out + size;
    else
        idx_in
    endif
enddefine;

define new_consumer_buffer();

    lvars buffer = false;
    lvars index = 0;
    lvars dump = [];
    lvars ndump = 0;

    procedure( ch );
        if ch == termin then
            lvars result = inits( ndump * size + index );
            lvars idx = copy_across( 0, dump, result );
            lvars i;
            for i from 1 to index do
                subscrs( i, buffer ) -> subscrs( idx + i, result )
            endfor;
            false -> buffer;
            0 -> index;
            [] -> dump;
            0 -> ndump;
            return( result )
        elseif buffer then
            if index < size then
                index + 1 -> index;
                ch -> subscrs( index, buffer );
            else
                buffer @conspair dump -> dump;
                ndump + 1 -> dump;
                false -> buffer;
                0 -> index;
            endif
        else
            inits( size ) -> buffer;
            1 -> index;
            ch -> subscrs( 1, buffer );
        endif
    endprocedure
enddefine;

endsection;
