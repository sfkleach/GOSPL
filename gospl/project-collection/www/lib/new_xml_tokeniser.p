compile_mode :pop11 +strict;

uses xml_stream

section;


;;; A tokeniser maintains quite a lot of state information.  In
;;; particular, it keeps a stack (list) of currently unmatched
;;; start-tags.  It also keeps track of line numbers so it can
;;; provide some basic error reporting.
;;;
;;; A tokeniser is fundamentally a tag-repeater. It has type
;;;     tokeniser : () -> token | termin
;;;
;;; Tokens are either
;;;     1.  start-tags,
;;;     2.  end-tags,
;;;     3.  standalone-tags,
;;;     4.  cdata (strings), or
;;;     5.  comments

;;; Tokenisers are constructed from
;;;     a.  an XML character repeater
;;;     b.  a list of options.


;;; -----------------------------------------------------------

define add_line_info( msg, cs );
    sprintf(
        '%p (Line number %p, at character %p)',
        [% msg, cs.xml_stream_line_col %]
    )
enddefine;


;;; -- XML Token Stream ---------------------------------------


defclass constant StartTag {
    startTagTypeName,
    startTagAttributes
};

defclass constant EndTag {
    endTagTypeName
};

defclass constant StandaloneTag {
    standaloneTagStartTag
};

defclass constant Comment {
    commentString
};


/* obsolete
defclass lconstant Tag {
    tagType,
    tagAttributes
};
*/

;;; This should really be enhanced to cope with the two other Unicode
;;; whitespace characters.
define lconstant read_white( ch, chars ) -> ch;
    while ch == `\s` or ch == `\t` or ch == `\n` or ch == `\r` do
        chars.xml_stream_next_char -> ch
    endwhile;
    /*
    if ch == termin then
        mishap( 0, add_line_info( 'Unexpected end of input', chars ), 'eof-tag:xml-syntax' )
    endif;
    */
enddefine;

define lconstant isnametokencode( ch );
    ch.isinteger and
    ( ch.isalphacode or ch.isnumbercode or locchar( ch, 1, '-_:.' ) )
enddefine;

define lconstant read_name( ch, chars, case_flag ) -> ch;
    if isalphacode( ch ) then
        consword(#|
            ch;
            repeat
                chars.xml_stream_next_char -> ch;
            quitunless( ch.isnametokencode );
                ch
            endrepeat
        |#).case_flag
    else
        mishap( ch, 1, add_line_info( 'Incorrect character starting name', chars ), 'name:xml-syntax' )
    endif
enddefine;

;;; Returns ( name, ch )
define lconstant read_name_white( ch, chars, case_flag );
    read_white( read_name( ch, chars, case_flag ), chars )
enddefine;

;;; WRONG!  Attribute values are also subject to entity interpretation.
define lconstant read_string( ch, chars ) -> ch;
    consstring(#|
        if ch == `"` then
            chars.xml_stream_next_char -> ch;
            until ch == `"` do
                if ch == termin do
                    mishap( 0, 'Unexpected end of input while reading attribute', 'eof-attribute:xml-syntax' )
                endif;
                ch;
                chars.xml_stream_next_char -> ch;
            enduntil;
            chars.xml_stream_next_char -> ch;
        elseif ch.isnametokencode do
            repeat
                ch;
            quitunless( isnametokencode( chars.xml_stream_next_char ->> ch ) );
            endrepeat;
        else
            mishap( 0, 'Missing double-quote at start of attribute value', 'attribute:xml-syntax' )
        endif
    |#)
enddefine;

define lconstant read_string_white( ch, chars );
    read_white( read_string( ch, chars ), chars )
enddefine;

define read_tag( ch, chars, standalone_flag, case_flag ) -> ( tag, ch );
    lvars type, attributes;
    read_name_white( ch, chars, case_flag ) -> ch -> type;             ;;; returns type
    [%
        until ch == `/` or ch == ">" do
            read_name_white( ch, chars, case_flag ) -> ch,         ;;; returns name
            if ch == `=` then
                read_white( chars.xml_stream_next_char, chars ) -> ch;
                read_string_white( ch, chars ) -> ch;   ;;; returns value
            else
                nullstring                              ;;; default
            endif
        enduntil
    %] -> attributes;
    consStartTag( type, attributes ) -> tag;
    if ch == `/` then
        read_white( chars.xml_stream_next_char, chars ) -> ch;
        if ch /== ">" then
            mishap( 0, 'Missing ">" following "/"', 'tag:xml-syntax' )
        endif;
        if standalone_flag == "expand_standalone" then
            consEndTag( type ) -> xml_stream_next_char( chars );
        elseif standalone_flag == "keep_standalone" then
            consStandaloneTag( tag ) -> tag
        else ;;; standalone_flag == "mishap_standalone"
            mishap( type, 1, 'Standalone tags not allowed', 'tag-standalone:xml-syntax' )
        endif
    elseunless ch == ">" then
        mishap( ch, 1, 'Unclosed tag', 'tag:xml-syntax' )
    endif;
    chars.xml_stream_next_char -> ch;
enddefine;

;;; read_token returns
;;;     -   a string, representing CDATA
;;;     -   a StartTag
;;;     -   an EndTag
;;;     -   termin
;;;
;;; The character stream -chars- returns either a Unicode character,
;;; "<"/">" or termin.  It is not a procedure.
;;;
define read_token( ch, chars, cons_comment, standalone_flag, case_flag ) -> ch;
    if ch == termin then
        termin
    elseif ch == "<" then
        read_white( chars.xml_stream_next_char, chars ) -> ch;
        if ch == `/` then
            lblock
                lvars type;
                read_name_white( chars.xml_stream_next_char, chars, case_flag ) -> ch -> type;
                unless ch == ">" do
                    mishap(
                        consstring( ch, 1 ),
                        1,
                        add_line_info( 'End tag improperly closed', chars ),
                        'tag:xml-syntax'
                    )
                endunless;
                false -> ch;
                ;;; chars.xml_stream_next_char -> ch;   ;;; NO - don't read ahead!
                consEndTag( type )
            endlblock
        elseif ch == `!` then
            chars.xml_stream_next_char -> ch;
            if ch == `-` then
                unless chars.xml_stream_next_char == `-` do
                    mishap( 0, 'Malformed comment (only one hypen)', 'comment:xml-syntax' )
                endunless;
                lvars comment = $-xml$-xml_stream_skip_comment( chars, cons_comment );  ;;; returns comment token
                chars.xml_stream_next_char -> ch;
                unless ch == ">" do
                    mishap(
                        0,
                        'Incorrectly terminated comment',
                        'comment:xml-syntax'
                    )
                endunless;
                if comment then
                    comment
                else
                    read_white( chars.xml_stream_next_char, chars ) -> ch;
                    read_token( ch, chars, cons_comment, standalone_flag, case_flag ) -> ch;
                endif
            else
                ;;; Just a temporary measure (I hope).
                until ( chars.xml_stream_next_char ->> ch ) == termin or ch == "<" do enduntil;
                read_token( ch, chars, cons_comment, standalone_flag, case_flag ) -> ch;
            endif
        else
            read_tag( ch, chars, standalone_flag, case_flag ) -> ch;
        endif
    elseif ch == "<" then
        mishap( 0, add_line_info( 'Misplaced ">"', chars ), 'tag:xml-syntax' )
    elseif ch.isEndTag then
        ch;
        false -> ch;
        ;;; chars.xml_stream_next_char -> ch;   ;;; NO! No need to read ahead.
    else
        ;;; Probably should be a consdstring with string optimization.
        consstring(#|
            repeat
                ch;
                chars.xml_stream_next_char -> ch;
                quitif( ch == termin or ch == ">" or ch == "<" )
            endrepeat
        |#)
    endif
enddefine;


;;; -- more new stuff -----------------------------------------


define xml_check_*( w, d, list ) -> w;
    if w == "default" then
        d -> w
    endif;
    unless fast_lmember( w, list ) do
        mishap( w, 1, 'Invalid flag' )
    endunless;
enddefine;

lconstant tokeniser_flags =
    [
        [ expand_standalone mishap_standalone keep_standalone ]
        [ skip_comment keep_comment ]
        [ keepcase lowercase uppercase ]
    ];



/*
standalone tags are controlled by these flags
        "mishap_standalone"     <foo/> not permitted
        "keep_standalone"       standalone tags returned
        "expand_standalone"     expand into start/end tags (default)

comment strings are controlled by these flags
        "skip_comment"          comments are discarded (default)
        "keep_comment"          return explicit comment tokens

case for name is controlled by these flags
        "keepcase"              preserve original case (default)
        "lowercase"             always lowercase
        "uppercase"             always uppercase
*/
define new_xml_tokeniser( chars, flags );

    lvars ( standalone_flag, comment_flag, case_flag ) =
        $-xml$-xml_process_args_*( flags, tokeniser_flags );


    lvars char_stream =
        if chars.is_xml_stream then
            chars
        else
            new_xml_stream( chars, [] )
        endif;

    lvars ch = false;

    lvars cons_comment =
        if comment_flag == "keep_comment" then
            procedure(); consdstring(); consComment() endprocedure
        else ;;; "skip_comment"
            procedure(); erasenum(); false endprocedure
        endif;

    lvars case_cnv =
        if case_flag == "uppercase" then
            lowertoupper
        elseif case_flag == "lowercase" then
            uppertolower
        else ;;; "keepcase"
            identfn
        endif;

    procedure() -> token;
        repeat
            read_token(
                ch or char_stream.xml_stream_next_char,
                char_stream,
                cons_comment,
                standalone_flag,
                case_cnv
            ) -> ch -> token;
            quitif( token )
        endrepeat
    endprocedure

enddefine;

endsection;
