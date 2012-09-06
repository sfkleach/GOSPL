compile_mode :pop11 +strict;

section;

;;; This is a really yucky hack - but quite efficient!  Bear in mind
;;; that it is vital to keep out of the way of the main loop, and
;;; the idea behind this becomes more obvious.
;;;
;;; query is a magic communiation flag.  When it is set, termin is
;;; treated as a magic message, requesting an operation on the
;;; internal state.
;;;
lvars query = false;

define buffer_result();
    dlocal query = "result";
    b( termin )
enddefine;

define buffer_final_result();
    dlocal query = "final_result";
    b( termin )
enddefine;

define buffer_index( i, b );
    dlocal query == "index";
    b( i, termin )
enddefine;


lconstant size = 4, size1 = size + 1;

define lconstant copy_across( idx_in, dump, result );
    if dump.ispair then
        lvars ( d, rest ) = dump.destpair;
        lvars idx_next = copy_across( idx_in, rest, result );
        move_bytes( 1, d, idx_next, result, size );
        idx_next + size;
    else
        idx_in
    endif
enddefine;


how many termins

termin is special / not special
    on termin reset state / leave it alone
    on termin return a result / do nothing
    how many do we permit 0/1/many?

;;; on_termin is a flag which determines the behaviour of the
;;; buffer when termin is received.
;;;
;;;     error       complain if termin is added to the buffer
;;;     accept      add termin to the buffer
;;;     result      return result so far
;;;     stop        return result, trash state and forbid further activity
;;;     restart     return result and reset buffer
;;;
define new_char_buffer( on_termin );

    unless
        on_termin == "continue" or
        on_termin == "stop" or
        on_termin == "restart"
    do
        mishap( on_termin, 1, 'Invalid switch for new_char_buffer' )
    endunless;

    ;;; ATTENTION: the signal for the buffer being closed is that
    ;;; _both_ buffer and dump are <false>.  The rationale behind
    ;;; this bizarre trick is purely one of efficiency - it avoids
    ;;; an extra variable and avoids having to test for a dead
    ;;; buffer in the performance critical region.

    lvars buffer = false;
    lvars index = 0;
    lvars dump = [];
    lvars ndump = 0;

    procedure( ch );
        if ch == termin then
            if not( buffer ) and not( dump ) then
                mishap( 0, 'Buffer already closed' )
            endif;
            lvars result = inits( ndump * size + index );
            lvars idx = copy_across( 1, dump, result );
            move_bytes( 1, buffer, idx, result, index );
            if on_termin /== "continue" then
                false -> buffer;
                0 -> index;
                0 -> ndump;
                if on_termin == "stop" then
                    false
                else
                    []
                endif -> dump
            endif;
            return( result )
        elseif buffer then
            ;;; Performance critical section.  Must make this
            ;;; nice and fast.  Note that buffer is false for all
            ;;; dead buffers.
            if index fi_>= size then
                buffer @conspair dump -> dump;
                ndump + 1 -> ndump;
                inits( size ) -> buffer;
                0 -> index;
            endif;
            index fi_+ 1 -> index;
            ch -> fast_subscrs( index, buffer );
        else
            ;;; Can only be here if buffer is <false>.  The variable
            ;;; dump doubles up as "dead" flag.
            unless dump do
                mishap( ch, 1, 'Trying to apply dead buffer' )
            endunless;
            inits( size ) -> buffer;
            1 -> index;
            ch -> fast_subscrs( 1, buffer );
        endif
    endprocedure
enddefine;

endsection;
