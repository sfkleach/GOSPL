compile_mode :pop11 +strict;

uses new_xml_tokeniser;
uses html_predicates;

section $-xml =>
    new_html_tokeniser
;


define lconstant mishap_cannot_contain( ftype, ty, char_stream );
    mishap(
        ty, 1,
        add_line_info(
            sprintf( '%p may not contain %p', [% ftype, ty %] ),
            char_stream
        ),
        'tag-nest:xml-syntax'
    )
enddefine;

;;; empty_flag may be
;;;     "keep_empty"
;;;     "standalone_empty"
;;;     "expand_empty"      (default)
;;;
;;; standalone_flag may be
;;;     "mishap_standalone"
;;;     "keep_standalone"
;;;     "expand_standalone" (default)
;;;
;;; comment_flag may be
;;;     "skip_comment"      (default)
;;;     "keep_comment"
;;;
;;; case_flag may be
;;;     "lowercase"         (default)
;;;     "uppercase"
;;;     "keepcase"
;;;
;;; repair_flag may be
;;;     "try_repair"
;;;     "mishap_repair"     (default)

lconstant htokeniser_flags =
    [
        [ expand_empty standalone_empty keep_empty ]
        [ expand_standalone keep_standalone mishap_standalone ]
        [ skip_comment keep_comment ]
        [ lowercase uppercase keepcase ]
        [ mishap_repair try_repair ]
    ];

define new_html_tokeniser( chars, flags );

    lvars ( empty_flag, standalone_flag, comment_flag, case_flag, repair_flag ) =
        xml_process_args_*(
            flags,
            htokeniser_flags
        );

    lvars char_stream =
        if chars.is_xml_stream then
            chars
        else
            new_xml_stream( chars, [] )
        endif;

    lvars xmltoks =
        new_xml_tokeniser(
            char_stream,
            [ ^standalone_flag ^comment_flag ^case_flag ]
        ).pdtolist;

    lvars open = [];

    procedure();
        lvars items, ftype;
        ;;; [ open = ^open ] =>
        if null( xmltoks ) then
            termin
        else
            lvars oldxmltoks = xmltoks;
            lvars tok = xmltoks.dest -> xmltoks;
            if tok.isStartTag then
                lvars ty = tok.startTagTypeName;
                if ty.is_empty_typename then
                    if empty_flag == "expand_empty" then
                        conspair( consEndTag( ty ), xmltoks ) -> xmltoks;
                        conspair( ty, open ) -> open;
                        tok
                    elseif empty_flag == "standalone_empty" then
                        consStandaloneTag( tok )
                    else ;;; empty_flag == "keep_empty"
                        tok
                    endif
                elseif open == [] then
                    conspair( ty, open ) -> open;
                    tok
                else
                    lvars ftype = front( open );
                    lvars r = try_to_contain( ftype, ty );
                    if r == "ok" then
                        conspair( ty, open ) -> open;
                        tok
                    elseif r == "close" then
                        oldxmltoks -> xmltoks;
                        consEndTag( open.destpair -> open );
                    elseif r == "error" then
                        mishap_cannot_contain( ftype, ty, char_stream )
                    else    ;;; repair
                        if repair_flag == "try_repair" then
                            warning( ftype, ty, , r, 3, 'Trying to repair defective HTML' );
                            ;;; We will inject the default start tag <foo>
                            ;;; where foo is the first item in the must-contains
                            ;;; list.  This item MUST be optionally closeable
                            ;;; otherwise we have simply deferred the error
                            ;;; and obscured the cause!
                            conspair( tok, xmltoks ) -> xmltoks;
                            conspair( r, open ) -> open;
                            consStartTag( r, [] )
                        else
                            mishap_cannot_contain( ftype, ty, char_stream )
                        endif
                    endif
                endif
            elseif tok.isEndTag then
                lvars ty = tok.endTagTypeName;
                if open == [] or front( open ) == ty then
                    back( open ) -> open;
                    tok
                elseif front( open ).has_optional_end_tag then
                    oldxmltoks -> xmltoks;
                    consEndTag( open.destpair -> open );
                else
                    mishap(
                        tok, 1,
                        add_line_info(
                            'Unexpected end tag',
                            char_stream
                        ),
                        'tag-enf:xml-syntax'
                    )
                endif
            else
                tok
            endif
        endif;
    endprocedure

enddefine;

endsection;
