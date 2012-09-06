compile_mode :pop11 +strict;

uses tags;

section;

vars html_parse_warning = erasenum(%2%);

;;; Tokenise HTML
;;;  takes an input stream of characters
;;;  returns a stream of characters/elements

define lconstant make_tag( n );
    lconstant dummy = "DUMMY";
    returnif( n == 0 )(
        warning( 'INTERNAL ERROR - make_tag with 0 args', [] ),
        consTag( dummy, nullvector, false )
    );

    lvars ( name, rest ) = conslist( n - 1 );
    consword( name.lowertoupper ) -> name;
    {%
        until null( rest ) do
            lvars nm = rest.dest -> rest;
            if nm.isstring then
                consword( nm.lowertoupper ) -> nm;
                if rest.null.not and rest.hd == "=" and rest.tl.null.not then
                    lvars attr = rest.tl.dest -> rest;
                    nm, attr
                else
                    nm, nullstring
                endif
            elseif nm.islist then
                nm
            else
                warning( 'INTERNAL ERROR - peculiar tag component', [ ^nm ] );
            endif
        enduntil
    %} -> lvar attrs;
    consTag( name, attrs, false )
enddefine;

;;; define lconstant make_tag( n );
;;;     lconstant dummy = "DUMMY";
;;;     lvars L = conslist( n );
;;;     if null( L ) then
;;;         warning( 'INTERNAL ERROR - make_tag with 0 args', [] );
;;;         [ ^dummy ]
;;;     else
;;;         lvars ( name, rest ) = dest( L );
;;;         if name.isstring then
;;;             [%
;;;                 consword( name.lowertoupper );
;;;                 until null( rest ) do
;;;                     lvars nm = rest.dest -> rest;
;;;                     if nm.isstring then
;;;                         consword( nm.lowertoupper ) -> nm;
;;;                         if rest.null.not and rest.hd == "=" and rest.tl.null.not then
;;;                             lvars attr = rest.tl.dest -> rest;
;;;                             [ ^nm ^attr ]
;;;                         else
;;;                             nm
;;;                         endif
;;;                     elseif nm.islist then
;;;                         nm
;;;                     else
;;;                         warning( 'INTERNAL ERROR - peculiar tag component', [ ^nm ] );
;;;                     endif
;;;                 enduntil;
;;;             %]
;;;         elseif name == "/" then
;;;             if rest.null then
;;;                 warning( 'End tag without name', [] );
;;;                 [ / ^dummy ]
;;;             else
;;;                 [% "/", rest.hd.lowertoupper.consword %];
;;;                 unless rest.length == 1 then
;;;                     warning( 'End tag with too many components', [ ^rest ] );
;;;                 endunless;
;;;             endif
;;;         else
;;;             warning( 'INTERNAL ERROR - peculiar tag name', [ ^name ] );
;;;             [ ^dummy ]
;;;         endif
;;;     endif
;;; enddefine;

;;; The result of lex_html is a token-repeater that returns one of :-
;;;     (a) a character code
;;;     (b) words "<", ">" and "--"
;;;     (c) <termin>
;;;
define lex_html( raw_chars ); lvars procedure raw_chars;

    lvars line_num = 1;

    define lvars chars =
        procedure() -> ch;
            raw_chars() -> ch;
            if ch == `\n` then
                line_num + 1 -> line_num
            endif;
        endprocedure.newpushable
    enddefine;

;;;     define lvars uchars =
;;;         chars.updater
;;;     enddefine;
;;;
;;;     ;;; We've seen an `&` and we shall try to get
;;;     ;;; an escape sequence.  If it goes wrong we will
;;;     ;;; generate a warning and dump the chars we've seen.
;;;     define read_special_char();
;;;
;;;         define read_number();
;;;             lvars ok = false;   ;;; Assume something will go wrong!
;;;             lvars seen =
;;;                 consstring(#|
;;;                     repeat
;;;                         lvars ch = chars();
;;;                         if ch == termin then
;;;                             ;;; Ouch!  We don't like this.
;;;                             ch -> chars();
;;;                             quitloop
;;;                         endif;
;;;                         if ch == `;` then
;;;                             true -> ok;
;;;                             quitloop
;;;                         endif;
;;;                         quitunless( ch.isnumbercode );
;;;                         ch
;;;                     endrepeat;
;;;                 |#);
;;;             lvars n = strnumber( seen );
;;;             if ok and n.isinteger and 0 <= n and n < 256 then
;;;                 n
;;;             else
;;;                 ;;; Push the characters back onto chars.
;;;                 repeat seen.deststring times
;;;                     () -> chars()
;;;                 endrepeat
;;;             endif;
;;;         enddefine;
;;;
;;;         define try_read( n, s, ans );
;;;             if n > length( s ) then
;;;                 true
;;;             else
;;;                 lvars x = subscrs( n, s );
;;;                 lvars y = chars();
;;;                 if x == y and try_read( n+1, s, ans ) then
;;;                     ans
;;;                 else
;;;                     y -> chars();
;;;                     false
;;;                 endif
;;;             endif
;;;         enddefine;
;;;
;;;         lvars found =
;;;             try_read( 1, '#', true ) or
;;;             try_read( 1, 'lt', `<` ) or
;;;             try_read( 1, 'gt', `>` ) or
;;;             try_read( 1, 'amp', `&` ) or
;;;             try_read( 1, 'quot', `"` );
;;;
;;;         if found == true then
;;;             read_number()
;;;         elseif found then
;;;             found
;;;         else
;;;             html_parse_warning( 'Incorrect use of "&"', [ line ^line_num ] );
;;;             `&`
;;;         endif;
;;;     enddefine;

    procedure();
        lvars ch = chars();
        if ch == termin then
            termin
;;;         elseif ch == `&` then
;;;             read_special_char()
        elseif ch == `-` and ( chars() ->> chars() ) == `-` then
            chars() ->@;
            "--"
        elseif ch == `<` or ch == `>` then
            consword( ch, 1 )
        else
            ch
        endif
    endprocedure
enddefine;


define is_white_space( ch );
    ch.isinteger and
    locchar( ch, 1, '\s\t\n\r' ) and true
enddefine;

vars procedure html_unit;

;;; We've seen a `<` and we shall try to read an
;;; HTML element.  If it goes wrong we shall generate
;;; a warning and dump the chars we've seen.
define parse_tag( tokens );

    define read_quoted_string( qch );
        consstring(#|
            repeat
                lvars tok = tokens();
                if tok == termin then
                    ;;; Hit the end of file before the closing quote.
                    ;;; Whoops!  We recover by pretending we see the
                    ;;; closing quote.

                    html_parse_warning( 'No closing quote for attribute', [] );
                    termin -> tokens();
                    `"` -> tokens();
                endif;
                quitif( tok == qch );
                if tok.isword then
                    tok.explode
                else
                    tok
                endif
            endrepeat
        |#)
    enddefine;

    ;;; Technically,
    ;;;     Name ::= letter ( letter | digit | hypen | period )*
    ;;; but this is far too stringent.
    define read_name( tok );
        consstring(#|
            tok;
            repeat
                lvars tok = tokens();
                if tok.isword or tok.is_white_space or tok == `=` do
                    ;;; This includes <termin>!  If we unexpectedly
                    ;;; find the end-of-file we push it back and
                    ;;; pretend we didn't see it.  Let the next level
                    ;;; recover from it.
                    tok -> tokens();
                    quitloop;
                endif;
                tok;
            endrepeat;
        |#)
    enddefine;

    define item();
        ;;; Skip over any white space.
        repeat
            lvars tok = tokens();
            quitunless( tok.is_white_space );
        endrepeat;
        if tok.isword then
            tok
        elseif tok == termin then
            ;;; Whoops!  This is starting to go pear-shaped.  Try
            ;;; to recover by pretending we saw a `>`.
            html_parse_warning( 'End of tag is missing', [] );
            tok -> tokens();
            ">"
        ;;; elseif tok == `=` or tok == `/` then
        elseif tok == `=` then
            consword(#| tok |#)
        elseif tok == `"` or tok == `'`then
            read_quoted_string( tok )
        else
            read_name( tok )
        endif;
    enddefine;

    define get_next_item() -> it;
        item() -> it;
        if it = '--' then
            [ comment %
                repeat
                    lvars tok = tokens();
                &_until tok == "--" do
                    if tok.isword then
                        tok.explode
                    else
                        tok
                    endif
                endrepeat
            %]
        endif
    enddefine;

    lvars it = item();
    if it.isstring or it == "/" then
        make_tag(#|
            it;
            repeat
                lvars it = get_next_item();
                if it == "<" then
                    html_parse_warning( 'Unexpected "<"', [] );
                    nextloop;
                endif;
                quitif( it == ">" );
                it
            endrepeat
        |#)
    else
        if it == "<" then
            html_parse_warning( 'Unexpected "<"', [] );
            parse_tag( tokens );
        elseif it == ">" then
            html_parse_warning( 'Unmatched ">"', [] );
            chain( html_unit );
        elseif it == "--" then
            html_parse_warning( 'Unexpected "--"', [] );
            chain( html_unit );     ;;; probably wrong!
        else
            warning( 'INTERNAL ERROR', [ ^it ] );
            it.explode
        endif
    endif;
enddefine;

define html_unit( tokens );
    lvars t = tokens();
    if t == termin then
        t
    elseif t == "<" then
        parse_tag( tokens )
    elseif t == "--" then
        t.word_string
    else
        consstring(#|
            if t.isword then
                html_parse_warning( 'Unexpected symbol found', [ ^t ] );
                t.explode;
            else
                t
            endif;
            while isinteger( tokens() ->> t ) do
                t
            endwhile;
            t -> tokens()
        |#)
    endif;
enddefine;

define tag_html( tokens ); lvars tokens;
    html_unit(% newpushable( tokens ) %)
enddefine;

define lconstant stylistic =
    new_simple_property(
        maplist( [ I B U EM STRONG ], <$ x | [ ^x ^true ] $> ),
        "perm",
        false
    )
enddefine;

define isCloser( x );
    returnunless( x.isTag )( false );
    x.tagName -> lvar name;
    subscrw( 1, name ) == `/` and not( stylistic( 1 @allbutfirst name ) )
enddefine;

define lconstant fix( count, tag, stack ) -> stack;
    lvars v = initv( count );
    lvars i;
    for i from count by -1 to 1 do
        stack.destpair -> stack -> v( i )
    endfor;
    v -> tagCont( tag )
enddefine;

define lconstant fixPayload( item, stack ) -> stack;
    lvars tg = 1 @allbutfirst tagName( item );
    lvars x, count = 0;
    for x in stack do
        returnif( x.isTag and x.tagName == tg and not( x.isElement ) )(
            fix( count, x, stack ) -> stack
        );
        count + 1 -> count;
    endfor;
    item @conspair stack -> stack
enddefine;

define html_trees( tags );
    lvars stack = [];
    lvars item;
    for item from_repeater tags do
        if item.isCloser then
            fixPayload( item, stack ) -> stack;
        else
            item @conspair stack -> stack
        endif
    endfor;
    revdl( stack )
enddefine;

define html_parse( raw_chars );
    raw_chars.lex_html.tag_html
enddefine;

endsection;

/*

uses fmatches;
define prune( r ); lvars procedure r;
    procedure() -> x;
        repeat
            lvars y = r() ->> x;
            quitif(
                y == termin or
                y fmatches [ A == [ HREF ?x ] ] or
                y fmatches [ BASE == [ HREF = ] == ]
            )
        endrepeat;
    endprocedure
enddefine;

define tag_attr( tag, t, a );
    if tag.islist and not( tag.null ) and hd( tag ) == t then
        lvars i;
        for i in tl( tag ) do
            if i.islist and not( i.null ) and hd( i ) == a then
                return( i( 2 ) )
            endif
        endfor
    else
        false
    endif
enddefine;

define html_references( raw_chars, base_url );
    lvars i;
    for i from_repeater raw_chars.html_parse do
        lvars t;
        if tag_attr( i, "BASE", "HREF" ) ->> t then
            t -> base_url
        elseif tag_attr( i, "A", "HREF" ) ->> t then
            base_url and resolve_url( t, base_url ) or t
        endif
    endfor
enddefine;

*/
