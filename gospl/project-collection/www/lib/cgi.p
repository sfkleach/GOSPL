compile_mode :pop11 +strict;

section;

define global syntax $ ;
    sysPUSHQ( readitem() sys_>< nullstring );
    sysCALL -> pop_expr_inst;
    "systranslate" -> pop_expr_item;
enddefine;

define global split_fields( str, sep );
    lvars a = 1;
    repeat
        lvars b = issubstring( sep, a, str );
        if b then
            substring( a, b - a, str );
            b + length( sep ) -> a;
        else
            substring( a, length( str ) - a + 1, str );
            quitloop
        endif
    endrepeat
enddefine;

define global incharline( r ); lvars procedure r;
    lconstant terminator = identfn(% termin %);
    procedure();
        lvars count = 0;
        repeat
            lvars c = r();
            if c == `\n` do
                consstring(count);
                quitloop
            elseif c == termin do
                if count == 0 then
                    termin
                else
                    ;;; Poplog guarantees that all end-of-files are
                    ;;; preceded by end-of-lines.  However, I do not wish
                    ;;; to rely on this undocumented fact & have put this
                    ;;; line in as protection.
                    consstring( count );
                    terminator -> r;
                endif;
                quitloop
            else
                c;
                count fi_+ 1 -> count;
            endif;
        endrepeat;
    endprocedure
enddefine;

global vars cgi_names = [];

define global cgi_arg_list =
    newproperty( [], 32, [], "perm" )
enddefine;

define global cgi_content_type =
    newproperty( [], 8, false, "perm" )
enddefine;

define global cgi_file_name =
    newproperty( [], 8, false, "perm" )
enddefine;

define global cgi_arg( n );
    lvars x = cgi_arg_list( n );
    x.ispair and x.hd
enddefine;

define updaterof cgi_arg( v, n );
    [ ^v ] -> cgi_arg_list( n )
enddefine;

syssynonym( "cgi_args", "cgi_arg" );

define lconstant crash( msg );
    if msg.isinteger then
        conslist( msg ) -> msg
    endif;
    pr( 'Content-type: text/plain\r\n\r\n' );
    if msg.isstring then msg.npr else applist( msg, npr ) endif;
    fast_sysexit();
enddefine;

define lconstant cgi_oops();
    pr( 'Content-type: text/html\r\n\r\n' );
enddefine;

define crashif( flag, msg );
    if flag then
        crash( msg )
    endif
enddefine;

define lconstant bad_request();
    crash(#|
        'Sorry, we failed to receive your request correctly. ',
        'If you try again you may be lucky. '
    |#);
enddefine;


define lconstant cgi_escape( a, b ); lvars a, b;
    lconstant hx = '0123456789ABCDEF';
    lvars x = strmember( a, hx );
    lvars y = strmember( b, hx );
    unless x and y do
        crash(#|
            'Invalid escape sequence sent by server',
            sprintf( 'Found %%%c%c', [% a, b %] )
        |#)
    endunless;
    ( x - 1 ) << 4 + ( y - 1 )
enddefine;

define lconstant readN( nbytes ) -> s; lvars nbytes;
    inits( nbytes ) -> s;
    lvars bsub = 1;
    lvars left = nbytes;
    repeat
        lvars n = sysread( popdevin, bsub, s, left );
        bsub + n -> bsub;
        left - n -> left;
        quitif( left <= 0 );    ;;; defensive
    endrepeat;
enddefine;

constant cgi_undefined_value = '';

define lconstant cgi_parse( rptr ); lvars procedure rptr;
    {%
        lvars state = "key";
        lvars K = 0;
        repeat
            lvars ch = rptr();
        quitif( ch == termin );
            if ch == `%` then
                ;;; This is an escape sequence.
                lvars a = rptr();
                if a == termin then bad_request() endif;
                lvars b = rptr();
                if b == termin then bad_request() endif;
                cgi_escape( a, b );
                K fi_+ 1 -> K;
            elseif ch == `+` then
                K fi_+ 1 -> K;
                ` `
            elseif ch == `=` then
                consword( K );
                0 -> K;
                "value" -> state;
            elseif ch == `&` then
                if state == "key" then
                    consword( K );
                    cgi_undefined_value
                else
                    consstring( K );
                endif;
                0 -> K;
                "key" -> state;
            else
                K fi_+ 1 -> K;
                ch
            endif;
        endrepeat;
        if state == "value" then
            consstring( K );
        elseif state == "key" and K > 0 then
            consword( K );
            cgi_undefined_value
        endif;
    %}
enddefine;

define lconstant add_binding( name, value );
    if name.isstring then consword( name ) -> name endif;
    cgi_arg_list( name ) nc_<> [ ^value ] -> cgi_arg_list( name );
    name :: cgi_names -> cgi_names;
enddefine;

define lconstant cgi_tabulate( v ); lvars v;

    unless length( v ) mod 2 == 0 do
        crash( 'Incorrect format for arguments' );
    endunless;

    lvars i;
    fast_for i from 1 by 2 to length( v ) do
        lvars name = v( i );
        lvars val = v( i+1 );
        add_binding( name, val );
    endfor;

    ncrev( cgi_names ) -> cgi_names;
enddefine;

define lconstant listparts( lines, start, finish );
    ;;; We're going to throw away the first line because we know it's just
    ;;; a separator - but let's check anyway and raise an error if it isn't
    ;;; because that would mean that it's gone all pear-shaped.
    unless lines.hd = start do
        crash(#|
            'First line of multi-part form is not a part separator',
            sprintf( 'It was:       "%p"', [% lines.hd %] ),
            sprintf( 'But expected: "%p"', [ ^start ] )
        |#);
    endunless;

    [%
        ;;; Off we go, romping through the parts.
        lvars line;
        lvars part = [];
        for line in lines.tl do
            if line = start or line = finish then
                ncrev( part );
                [] -> part;
            else
                [ ^line ^^part ] -> part;
            endif
        endfor;
    %]
enddefine;

define lconstant iswhitespace( ch );
    strmember( ch, '\s\t\n\r' )
enddefine;

define lconstant trim_whitespace( str ) -> str;
    while str.datalength > 0 and iswhitespace( subscrs( 1, str ) ) do
        allbutfirst( 1, str ) -> str
    endwhile;
    while str.datalength > 0 and iswhitespace( subscrs( str.datalength, str ) ) do
        allbutlast( 1, str ) -> str
    endwhile;
enddefine;

define lconstant trim_dquotes( str ) -> ans;

    define lconstant check( ch );
        unless ch == `"` do
            crash( 'Invalid multi-part request' )
        endunless
    enddefine;

    lvars n = str.deststring;
    if n > 1 then
        check( /* dq */ );
        consstring( n - 2 ) -> ans;
        check( /* dq */ )
    else
        check( false );
    endif;
enddefine;

define lconstant trim( str );
    trim_dquotes( trim_whitespace( str ) )
enddefine;

define lconstant cgi_prepare_multipart( data );

    ;;; This is disgusting.  It relies on -popstackmark- acting as
    ;;; a dummy argument when no arguments are supplied.
    define chunk_check( x );
        unless x = '--\r\n' do
            crash( 'The trailing "--" is missing' )
        endunless
    enddefine;

    define do_chunk( chunk );
        dlocal pop_pr_quotes = true;

        define val( name, line ) -> v;
            lvars ( _, v ) = split_fields( line, '=' );
            v.trim_whitespace -> v
        enddefine;

        lvars body = false;
        lvars content_type = false;
        lvars name = false;
        lvars file_name = false;

        lvars ( l, linelist ) = [% split_fields( chunk, '\r\n' ) %].dest;
        crashif( l.length > 0, 'Multi-part post is still corrupt' );

        until linelist.null do
            lvars line = linelist.dest -> linelist;
            quitif( line = '' );
            lvars header = [% split_fields( line, ':' ) %];
            lvars type = header( 1 );
            if type = 'Content-Disposition' then
                lvars cdisp = tl( [% split_fields( line, ';' ) %] );
                trim( val( 'name', cdisp( 1 ) ) ) -> name;
                unless cdisp.tl.null do
                    trim( val( 'filename', cdisp( 2 ) ) ) -> file_name
                endunless
            elseif type = 'Content-Type' then
                header( 2 ).trim_whitespace -> content_type
            else
                crash( 'Unexpected type of header in multi-part post' )
            endif
        enduntil;

        lvars N = length( linelist );
        if N == 0 then
            crash( 'Multi-part post corrupt' )
        elseif N == 1 then
            ;;; It is important that this is a fresh bit of store.
            ;;; This is so we can attach properties to it.
            ''.copy
        elseif N == 2 then
            linelist.hd
        else
            ;;; Stitch back the bits.
            consstring(#|
                lvars i;
                for i in linelist do
                    i.explode, `\r`, `\n`
                endfor;
                erase();
            |#)
        endif -> body;

        if content_type then
            content_type -> cgi_content_type( body )
        endif;
        if file_name then
            file_name -> cgi_file_name( body )
        endif;
        add_binding( name, body );
    enddefine;

    lconstant boundaryHeader = '--';
    lconstant boundaryTrailer = '--';
    lvars n = locchar( `=`, 1, $CONTENT_TYPE );
    unless n do
        crash( 'This script can only be used to decode form results.' );
    endunless;
    lvars boundarySpec = allbutfirst( n, $CONTENT_TYPE );
    lvars formPartBoundary = boundaryHeader <> boundarySpec;
    ;;; lvars lastFormPartBoundary = formPartBoundary <> boundaryTrailer;

    lvars ( c, chunk_list ) = [% split_fields( data, formPartBoundary ).chunk_check %].dest;
    crashif( c.datalength > 0, 'Missing boundary in multi-part post' );

    lvars chunk;
    for chunk in chunk_list do
        do_chunk( chunk )
    endfor;
enddefine;

define cgi_prepare();
    lvars m = $REQUEST_METHOD;
    if m = 'POST' then
        lvars nbytes = strnumber( $CONTENT_LENGTH or nullstring );
        unless nbytes.isinteger do
            crash( 'This server is incorrectly configured.\n The $CONTENT_LENGTH environment variable is not set' );
        endunless;
        lvars bytes = readN( nbytes );
        if datalength( $QUERY_STRING or nullstring ) > 0 then
            $QUERY_STRING <> '&' <> bytes -> bytes
        endif;
        if $CONTENT_TYPE = 'application/x-www-form-urlencoded' then
            bytes
        elseif isstartstring( 'multipart/form-data;', $CONTENT_TYPE ) then
            chain( bytes, cgi_prepare_multipart )
        else
            crash( 'This script can only be used to decode form results.' );
        endif;
    elseif m = 'GET' then
        $QUERY_STRING or nullstring
    elseunless poparglist.null do
        lvars ( arg0, args ) = poparglist.dest;
        [ ^arg0 ] -> poparglist;
        consstring(#|
            lvars i, none = true;
            for i in args do
                i.deststring.erase;
                `&`;
                false -> none;
            endfor;
            unless none do
                erase()
            endunless;
        |#)
    else
        mishap( 'No arguments and invalid $REQUEST_METHOD', [% $REQUEST_METHOD %] );
    endif.stringin.cgi_parse.cgi_tabulate
enddefine;

define lconstant cgi_compile( file, compiler );
    lvars chars = discin( file );
    lvars line;
    for line from_repeater incharline( chars ) do
        quitif( isstartstring( 'exec', line ) );
    endfor;
    chain( chars, compiler );
enddefine;

define cgi_set_globals();
    fast_sysexit -> interrupt;
    false -> poplinewidth;
    false -> popmemlim;
    cucharout -> cucharerr;
    erase -> libwarning;
enddefine;

define global cgi_startup();
    lvars files;
    cgi_set_globals();
    cgi_prepare();
enddefine;

endsection;
