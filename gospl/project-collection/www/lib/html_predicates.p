compile_mode :pop11 +strict;

section $-xml =>
    html_predicates
    is_html_typename
    is_empty_typename
    try_to_contain
    has_optional_end_tag
;


;;; -- HTML Predicates ----------------------------------------

;;; HTML is a mess.  Trying to do an acceptable job with it is
;;; just about impossible.

define is_html_typename =
    newproperty(
        maplist(
            [
                a abbr address applet area b base basefont bdo bgsound big blink blockquote body
                br button caption center cite code col colgroup dd dfn dir div dl dt em embed
                fieldset font form frame frameset head h1 h2 h3 h4 h5 h6 hr html i iframe ilayer img input
                isindex kbd keygen label layer legend li link map marquee menu meta nobr
                noembed noframes nolayer noscript object ol optgroup option p param pre q s
                samp script select server small spacer span strike strong style sub sup table
                tbody td textarea tfoot th thead title tr tt u ul var wbr
            ],
            procedure( x ); [^x ^x] endprocedure
        ).dup.length,
        false,
        "perm"
    )
enddefine;


lconstant emptynames =
    [
        base link meta hr input col frame param img iframe
        br spacer wbr basefont bgsound area
    ];

define is_empty_typename( type );
    fast_lmember( type.uppertolower, emptynames ) and true
enddefine;

/*
try_to_contain( parent, child )
    1.  OK                  "ok"
    2.  CLOSE PARENT        "close"
    3.  REPAIR WITH token   <token>
    4.  ERROR               "error"
*/

lconstant physical_markup =
    [ b bdo big blink font i marquee nobr s small span strike sub sup tt u ];

lconstant logical_markup =
    [ abbr cite code dfn em kbd q samp strong var ];

lconstant phrase_markup = physical_markup <> logical_markup;

lconstant body_stuff =
    [
        a applet basefont
        br button iframe img input
        label map object script select
        textarea
    ];

lconstant para_stuff = phrase_markup <> body_stuff;

lconstant body_blocks =
    [
        address blockquote center dir div dl
        fieldset form h1 h2 h3 h4 h5 h6 hr isindex menu
        noframes noscript ol p pre table ul
    ];

lconstant body_context = [ ^^body_blocks ^^para_stuff ];

/*
parent
    may contain
    repair action   CLOSE / TRY / FAIL
*/
define lconstant may_contain =
    newproperty(
        [
            [ p             [ CLOSE ^^para_stuff ] ]
            [ option        [ CLOSE ] ]
            [ dt            [ CLOSE ^^para_stuff ] ]
            [ dd            [ CLOSE ^^para_stuff ] ]
            [ head          [ FAIL base isindex link meta script style title ] ]
            [ html          [ FAIL head body frameset noframes ] ]
            [ li            [ CLOSE ^^body_context ] ]
            [ table         [ TRY tr caption col colgroup tbody tfoot thead ] ]
            [ tbody         [ FAIL tr] ]
            [ tfoot         [ FAIL tr] ]
            [ thead         [ FAIL tr ] ]
            [ tr            [ TRY td th ] ]
            [ td            [ CLOSE ^^body_context ] ]
            [ th            [ CLOSE ^^body_context ] ]
        ].dup.length,
        [ FAIL ^^body_context ],
        "perm"
    )
enddefine;

define try_to_contain( parent, child );
    parent.uppertolower -> parent;
    child.uppertolower -> child;
    if parent.is_html_typename and child.is_html_typename then
        lvars ( if_fail, options ) = parent.may_contain.destpair;
        if fast_lmember( child, options ) then
            "ok"
        elseif if_fail == "CLOSE" then
            "close"
        elseif if_fail == "TRY" then
            hd( options )
        else
            "error"
        endif
    else
        "ok"
    endif
enddefine;

define has_optional_end_tag( type );
    hd( may_contain( type ) ) == "CLOSE"
enddefine;

;;; Hack for uses.
vars html_predicates = true;

endsection;
