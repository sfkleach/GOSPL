compile_mode :pop11 +strict;

uses res_arg;

section;

lconstant
    START1 = `(`, START2 = `|`,
    STOP1 = `|`, STOP2 = `)`;

define lconstant html_body( res_arg, procedure data );
    dlocal res_arg;
    dlocal res_arg_list = frozval( 1, res_arg );

    lvars procedure output = cucharout;

    define dlocal cucharout( ch );
        if ch == `\Go` then
            appdata( '&deg;', output )
        elseif ch == `\G.` then
            appdata( '&middot;', output )
        elseif ch == `\G#` then
            appdata( '<LI>', output )
        else
            output( ch )
        endif
    enddefine;

    lvars Compiling = false, PushCount, Skip1 = false;

    lvars lastch = false;

    define act_char( ch1, ch2 );
        if Compiling then
            if ch1 == START1 and ch2 == START2 then
                mishap( 'Unexpected start-compiling bracket', [] );
            elseif ch1 == STOP1 and ch2 == STOP2 then
                true -> Skip1;
                lblock
                    false -> Compiling;
                    lvars s = consstring( PushCount, 0 -> PushCount );
                    appdata( {% stringin( s, false -> s ).compile %}, pr );
                endlblock
            else
                ch1, PushCount + 1 -> PushCount;
            endif
        else
            if ch1 == START1 and ch2 == START2 then
                true -> Skip1;
                true -> Compiling;
                0 -> PushCount;
            elseif ch1 == STOP1 and ch2 == STOP2 then
                mishap( 'Unexpected stop-compiling bracket', [] )
            else
                cucharout( ch1 )
            endif
        endif
    enddefine;

    define do_char( nextch );
        if lastch then
            if Skip1 then
                false -> Skip1
            else
                act_char( lastch, nextch )
            endif
        endif;
        nextch -> lastch;
    enddefine;

    lvars line;
    for line from_repeater data do
        appdata( line, do_char );
        do_char( `\n` );
    endfor;
    do_char( termin );
    if Compiling then
        mishap( 'Unexpected end of input, not finished compiling', [] )
    endif;
enddefine;

lconstant bodyAttributes =
    [
        background
        bgcolor
        text
        link
        alink
        vlink
    ];

define lconstant hyp_interpreter( prop, data );
    lvars title = prop( "title" );
    pr( 'Content-type: text/html\r\n\r\n' );
    npr( '<HTML>' );
    npr( '<HEAD>' );
    if title then
        nprintf( '<TITLE>%p</TITLE>', [ ^title ] )
    endif;
    lvars i;
    for i in frozval( 1, prop )( "head" ) do
        npr( i );
    endfor;
    nprintf( '</HEAD>' );
    pr( '<BODY' );
    lvars c;
    for c in bodyAttributes do
        lvars v = prop( c );
        if v then
            printf( ' %p="%p"', [% c.lowertoupper, v %] )
        endif
    endfor;
    npr( '>' );

    html_body( prop, data );

    npr( '</BODY>' );
    npr( '</HTML>' );
enddefine;

define lconstant content_type( prop );
    unless prop( "'dynamic-content-type'" ) do
        lvars ct = prop( "'content-type'" ) or 'text/plain';
        printf( 'Content-type: %p\r\n\r\n', [ ^ct ] );
    endunless
enddefine;

define lconstant default_interpreter( prop, data );
    content_type( prop );
    apprepeater( data, npr )
enddefine;

define lconstant pop_interpreter( prop, procedure data );
    lvars i     = 1;    ;;; defensive, i = 0 is fine.
    lvars n1    = -1;   ;;; defensive, n = 0 is fine.
    lvars line  = false;

    define getch();
        if line == termin then
            termin
        else
            i fi_+ 1 -> i;
            if i fi_< n1 then
                fast_subscrs( i, line )
            elseif i == n1 then
                `\n`
            else
                data() -> line;
                if line.isstring then
                    datalength( line ) + 1 -> n1;
                    0 -> i;
                endif;
                chain( getch )
            endif
        endif
    enddefine;

    content_type( prop );
    pop11_compile( getch )
enddefine;

define lconstant interpreter( type );
    if type == "hyp" then
        hyp_interpreter
    elseif type == "pop" then
        pop_interpreter
    else
        default_interpreter
    endif
enddefine;

define apply_style( data, prop_list );
    lvars prop = first_resource(% prop_list %);
    interpreter( consword( "type".prop or 'text' ) )( prop, data )
enddefine;

endsection;
