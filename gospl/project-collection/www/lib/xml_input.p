compile_mode :pop11 +strict;

uses xml_stream;
uses new_xml_tokeniser;
uses new_html_tokeniser;
uses new_xml_repeater;

section;

;;; standalone tags are controlled by these flags
;;;         "mishap_standalone"     <foo/> not permitted
;;;         "keep_standalone"       standalone tags returned
;;;         "expand_standalone"     expand into start/end tags (default)
;;;
;;; comment strings are controlled by these flags
;;;         "skip_comment"          comments are discarded (default)
;;;         "keep_comment"          return explicit comment tokens
;;;
;;; case for name is controlled by these flags
;;;         "keepcase"              preserve original case (default)
;;;         "lowercase"             always lowercase
;;;         "uppercase"             always uppercase
define in_xml_item( source );
    new_xml_repeater(
        new_xml_tokeniser(
            new_xml_stream( source, [] ),
            []
        )
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
define in_html_item( source );
    new_xml_repeater(
        new_html_tokeniser(
            new_xml_stream( source, [] ),
            [ mishap_standalone ]
        )
    )
enddefine;

define in_hybrid_item( source );
    new_xml_repeater(
        new_html_tokeniser(
            new_xml_stream( source, [] ),
            []
        )
    )
enddefine;

;;; -----------------------------------------------------------

define read_xml_item =
    in_xml_item <> apply
enddefine;

define read_html_item =
    in_html_item <> apply
enddefine;

define read_hybrid_item =
    in_hybrid_item <> apply
enddefine;

;;; -----------------------------------------------------------

define read_xml_item_list =
    in_xml_item <> pdtolist
enddefine;

define read_html_item_list =
    in_html_item <> pdtolist
enddefine;

define read_hybrid_item_list =
    in_hybrid_item <> pdtolist
enddefine;

endsection;
