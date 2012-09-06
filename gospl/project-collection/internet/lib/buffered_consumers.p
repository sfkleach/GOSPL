compile_mode :pop11 +strict;

section;

vars buffered_consumers = true;     ;;; uses hack.  Bletch.

defclass lconstant Buffer {
    BufferDestination,      ;;; the destination consumer
    BufferCompleteLines,    ;;; list of complete "lines", *latest first*
    BufferThisLine,         ;;; currently assembling line
    BufferThisCount         ;;; count of characters stuffed into same
};

lconstant bufferLimit = fi_check( 1 << 12, 1, false );

define lconstant make_block();
    ;;; tune this for best performance -- it's the size of the buffer's chunks.
    inits( bufferLimit )
enddefine;

;;;
;;; Make a new empty buffer pointing to the given ___________destination.
;;;
define lconstant procedure newBuffer( destn );
    consBuffer( destn, [], make_block(), 0 )
enddefine;

;;;
;;; Add a character to the buffer, pushing a complete line into the stack if
;;; necessary.
;;;
define lconstant procedure addCharacter( buffer, ch );
    lvars c = buffer.BufferThisCount, line = buffer.BufferThisLine;
    if c == bufferLimit then
        conspair( line, buffer.BufferCompleteLines ) -> buffer.BufferCompleteLines;
        make_block() ->> line -> buffer.BufferThisLine;
        0 -> c;
    endif;
    c fi_+ 1 ->> c -> buffer.BufferThisCount;
    ch -> fast_subscrs( c, line )
enddefine;

;;; Dump a buffer down to its final destination.
define lconstant procedure flushBuffer( buffer );
    lvars procedure consumer = buffer.BufferDestination;

    ;;; Send the complete lines.
    define squirt( L );
        unless null( L ) do
            lvars ( h, t ) = fast_destpair( L );
            squirt( t );
            appdata( h, consumer )
        endunless
    enddefine;

    squirt( buffer );

    lvars this = buffer.BufferThisLine;
    lvars i;
    fast_for i from 1 to buffer.BufferThisCount do cucharout( fast_subscrs( i, this ) ) endfor;
    [] -> buffer.BufferCompleteLines, 0 -> buffer.BufferThisCount;
enddefine;

;;; -------------------------------------------------------------------------

define lconstant buffered_consumer_buffer( out ) -> B;
    lvars B = frozval( 1, out );
    unless B.isBuffer do
        mishap( 'Not a buffered consumer', [ ^out ] )
    endunless
enddefine;

define flush_buffered_consumer( out );
    out.buffered_consumer_buffer.flushBuffer
enddefine;

define clear_buffered_consumer( out );
    lvars B = out.buffered_consumer_buffer;
    lvars ( d, _, t, _ ) = B.destBuffer;
    fill( d, [], t, 0, B ).erase
enddefine;

;;;
;;; Make a consumer that buffers up its output and, when finally
;;; applied to termin, squirts it all down the destination consumer.
;;;
define new_buffered_consumer( destn );

    procedure( ch, buffer ) with_props a_buffered_consumer;
        if ch == termin then
            buffer.flushBuffer
        else
            addCharacter( buffer, ch )
        endif
    endprocedure(% newBuffer( destn ) %)

enddefine;

endsection;
