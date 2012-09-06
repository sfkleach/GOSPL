compile_mode :pop11 +strict;

section $-xml =>
    xml_stream
    is_xml_stream
    new_xml_stream
    xml_stream_line_col
    xml_stream_next_char
;

;;; -- Flag processing ----------------------------------------

define xml_process_args_*( flags, flag_lists );
    lvars args = {% applist( flag_lists, hd ) %};
    lvars flag;
    for flag in flags do
        lvars list, n = 0;
        for list in flag_lists do
            n + 1 -> n;
            if fast_lmember( flag, list ) then
                flag -> subscrv( n, args );
                nextloop(2)                         ;;; process next flag
            endif;
        endfor;
        mishap( flag, maplist( flag_lists, dl ), 2, 'Not a valid flag' )
    endfor;
    args.explode
enddefine;

;;; -- XML Character Stream -----------------------------------

;;; The first thing we need to do is character-level processing.
;;; As we do this, we might as well record line number and position
;;; within the line since we shall have to inspect each and every
;;; character anyway.


defclass lconstant CharStream {
    charStreamPushback,         ;;; false-terminated pair-chain
    charStreamChars,            ;;; plain character repeater
    charStreamLineNum,          ;;; line number
    charStreamPosn,             ;;; character position
    charStreamAcceptAmpErr      ;;; do we accept incorrect XML &xxx; entities
};

define constant is_xml_stream =
    isCharStream
enddefine;

lconstant stream_flags =
    [[ accept mishap ]];

;;; ampersand_err_flag is
;;;     "mishap"
;;;     "accept"    (default)
;;;
define constant new_xml_stream( procedure chars, flags );
    consCharStream(
        false,
        chars,
        1,
        0,
        xml_process_args_*( flags, stream_flags ) == "accept"
    )
enddefine;

;;; This will return either a
;;;     -   a UNICODE character (16-bit number)
;;;     -   "<" or ">"
;;;     -   termin.
;;;
define constant xml_stream_next_char( cs ) -> the_char;

    lvars ( pushback, chars, line, posn, _ ) = destCharStream( cs );

    define getchar();
        if pushback then
            pushback.destpair ->> pushback -> cs.charStreamPushback;
        else
            chars();      ;;; could use -fast_apply-
        endif;
    enddefine;

    define ampersand( cs );

        define fetch( string, ans );
            lvars x;
            for x in_string string do
                lvars ch = getchar();
                unless x == ch do
                    mishap( consstring( ch, 1 ), 1, 'Invalid character following "&"', 'entity:xml-syntax' )
                endunless
            endfor;
            ans.explode
        enddefine;

        lvars ch = getchar();
        if ch == `a` then
            getchar() -> ch;
            if ch == `m` then
                fetch( 'p;', '&' )
            elseif ch == `p` then
                fetch( 'os;', '\'' )
            else
                mishap( consstring( ch, 1 ), 1, 'Invalid character following "&a"', 'entity:xml-syntax' )
            endif
        elseif ch == `l` then
            fetch( 't;', '<' )
        elseif ch == `g` then
            fetch( 't;', '>' )
        elseif ch == `q` then
            fetch( 'uot;', '"' )
        elseif ch == `n` then
            fetch( 'bsp;', '&nbsp;' )
        elseif ch == `#` then
            lvars str =
                consstring(#|
                    while isnumbercode( getchar() ->> ch ) do
                        ch
                    endwhile
                |#);
            lvars n = strnumber( str );
            if n and ch == `;` then
                ;;; Need to do something fancy if we've got a UNICODE character.
                n
            else
                mishap( str, 1, 'Invalid characters following "&#"', 'entity:xml-syntax' )
            endif
        elseif cs.charStreamAcceptAmpErr then
            conspair( ch, cs.charStreamPushback ) -> cs.charStreamPushback;
            `&`
        else
            mishap( consstring( ch, 1 ), 1, 'Invalid character following "&"', 'entity:xml-syntax' )
        endif
    enddefine;

    lvars ch = getchar();
    posn + 1 -> posn;
    if ch == termin then
        termin
    elseif ch == `<` then
        "<"
    elseif ch == `>` then
        ">"
    elseif ch == `\n` then
        0 -> posn;
        line + 1 -> charStreamLineNum( cs );
        ch
    elseif ch == `&` then
        ampersand( cs )
    else
        ch
    endif -> the_char;
    posn -> charStreamPosn( cs );
enddefine;

define updaterof xml_stream_next_char( ch, cs );
    conspair( ch, cs.charStreamPushback ) -> cs.charStreamPushback
enddefine;

xml_stream_next_char -> class_apply( CharStream_key );

;;; Reads up to the next pair of dashes.
;;;
define xml_stream_skip_comment( char_stream, cons_comment ) -> comment;
    lvars ( pushback, procedure chars, lines, posn, _ ) = char_stream.destCharStream;
    lvars n = 0;
    cons_comment(#|
        repeat
            lvars ch =
                if pushback then
                    pushback.destpair ->> pushback -> char_stream.charStreamPushback;
                else
                    chars();      ;;; could use -fast_apply-
                endif;
            ch;
            posn + 1 -> posn;
            if ch == termin do
                mishap( 0, 'Unexpected end of input while processing comment', 'eof-comment:xml-syntax' )
            endif;
            if ch == `-` then
                n + 1 -> n;
                if n >= 2 then
                    quitloop
                endif
            else
                if ch == `\n` then
                    lines + 1 -> lines;
                    0 -> posn;
                endif;
                0 -> n
            endif;
        endrepeat -> ( _, _ );  ;;; erase the two trailing "-"
    |#) -> comment;
    lines -> charStreamLineNum( char_stream );
    posn -> charStreamPosn( char_stream );
enddefine;

define constant xml_stream_line_col( cs );
    lvars ( _, _, line, posn, _ ) = destCharStream( cs );
    ( line, posn )
enddefine;


;;; Hack for uses.
vars xml_stream = true;

endsection;
