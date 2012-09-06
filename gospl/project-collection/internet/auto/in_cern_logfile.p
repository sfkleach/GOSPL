compile_mode :pop11 +strict;
section;

define lconstant newmatchlogline();
    lblock
        lconstant int_or_dash = '@(@[0-9-@]@*@)';
        lconstant unit = '@(@[^\s\t@]@*@)';
        lvars ( err, procedure match ) =
            regexp_compile(
                applist(
                    nullstring,
                    [%
                        '@^';
                        unit;
                        '\s';
                        unit;
                        '\s';
                        '@(@[^[@]@*@)';
                        '\s';
                        '[@(@[^[]\s\t@]@*@)\s@[+-@]@[0-9@]@{4@}]';
                        '\s';
                        '"@(@.@*@)"';
                        repeat 2 times
                            '\s';
                            int_or_dash
                        endrepeat;
                        ;;; '@[\s\t@]@*';       ;;; invalidated by cookie logging
                        ;;; '@$'                ;;; ditto
                    %],
                    nonop <>
                )
            );

        if err then
            mishap( err, [] )
        else
            match
        endif;
    endlblock;
enddefine;

define lconstant subscr_logline( n, matchLL ); lvars n, matchLL;
    substring( regexp_subexp( n, matchLL ) )
enddefine;

define new_string_to_log_entry_decoder();
    lvars procedure mll = newmatchlogline();
    lvars result = subscr_logline(% mll %);
    procedure( str );
        lvars ( start_index, num_chars ) = mll( 1, str, false, false );
        start_index and result
    endprocedure
enddefine;


define lconstant cvt_lines( x ); lvars x;
    x.isprocedure and x or x.discinline
enddefine;

define app_cern_logfile( logfile, p ); lvars logfile, procedure p;
    lvars mll = newmatchlogline();
    lvars subscr = subscr_logline(% mll %);
    lvars line;
    for line from_repeater logfile.cvt_lines do
        lvars ( start, num ) = mll( 1, line, false, false );
        if start then
            p( subscr )
        else
            mishap( 'Unexpected line format in logfile', [ ^line ] )
        endif
    endfor;
enddefine;

define :for_extension in_cern_logfile( varlist, isfast ); lvars varlist, isfast;
    unless varlist.length == 1 do
        mishap( 'ONLY ONE VARIABLE ALLOWED IN LOGFILE LOOP', [ ^varlist ] )
    endunless;

    lvars nth = varlist.hd;

    dlocal pop_new_lvar_list;

    lvars reptr = sysNEW_LVAR();
    lvars mll = sysNEW_LVAR();
    lvars line = sysNEW_LVAR();
    lvars fname = undef;

    pop11_comp_expr_to( "do" ).erase;
    unless isfast do
        sysPUSHS( undef );
        sysPOP( sysNEW_LVAR() ->> fname );
    endunless;
    sysCALLQ( cvt_lines );
    sysPOP( reptr );

    sysPUSHQ( subscr_logline );
    sysCALLQ( newmatchlogline );
    sysPUSHS( undef );
    sysPOP( mll );
    sysPUSHQ( 1 );
    sysCALL( "consclosure" );
    sysPOP( nth );

    lvars start = sysNEW_LABEL().dup.pop11_loop_start;
    lvars finish = sysNEW_LABEL().dup.pop11_loop_end;
    lvars bong = sysNEW_LABEL();

    sysLABEL( start );
    sysCALL( reptr );
    sysPUSHS( undef );
    sysPOP( line );
    sysPUSH( "termin" );
    sysCALL( "==" );
    sysIFSO( finish );

    sysPUSHQ( 1 );
    sysPUSH( line );
    sysPUSH( "false" );
    sysPUSHS( undef );
    sysCALL( mll );
    sysERASE( undef );
    sysIFNOT( bong );

    pop11_comp_stmnt_seq_to( "endfor" ).erase;

    sysGOTO( start );
    sysLABEL( bong );
    unless isfast do
        ;;; This is positioned here in order to avoid pipeline
        ;;; breaks in the common case that the log-file is correctly
        ;;; formatted.
        sysPUSHQ( 'Incorrectly formatted line in log file' );
        sysPUSH( "popstackmark" );
        sysPUSH( line );
        sysPUSH( fname );
        sysCALL( "sysconslist" );
        sysCALL( "warning" );
        sysGOTO( start );
    endunless;
    sysGOTO( start );
    sysLABEL( finish );
enddefine;


;;; Canonise domain name.
define log_entry_domain( le ); lvars le;
    uppertolower( le( 1 ) )
enddefine;

define log_entry_remote_ident( le ); lvars le;
    le( 2 )
enddefine;

define log_entry_user( le ); lvars le;
    le( 3 )
enddefine;

uses universal_time;
define log_entry_time_data( le ); lvars le;

    define lconstant procedure atoi( i, j, str ); lvars i, j, str;
        lvars total = 0;
        lvars n;
        fast_for n from i to j do
            total * 10 + ( subscrs( n, str ) - `0` ) -> total
        endfor;
        total
    enddefine;

    lvars time = le( 4 );
    if time.datalength == 20 then
        lconstant month = inits( 3 );
        atoi( 19, 20, time );
        atoi( 16, 17, time );
        atoi( 13, 14, time );

        atoi( 1, 2, time );
        number_of_month( fill( time( 4 ), time( 5 ), time( 6 ), month ) );
        atoi( 8, 11, time );
    else
        warning( 'Incorrectly formatted time entry', [ ^time ] )
    endif
enddefine;

define log_entry_utime( le ); lvars le;
    encode_universal_time( log_entry_time_data( le ), false )
enddefine;

define log_entry_request_string( le ); lvars le;
    le( 5 )
enddefine;

define log_entry_request_data( le ) -> ( method, url, rest, protocol ); lvars le, method, url, rest, protocol;
    nullstring ->> method ->> url ->> rest -> protocol;

    lvars str = log_entry_request_string( le );

    lvars a = locchar( `\s`, 1, str );
    returnunless( a );

    lvars method = substring( 1, a-1, str );

    skipchar( `\s`, a, str ) -> a;
    returnunless( a );

    ;;; Find the first space reading from -a-.
    lvars b = locchar( `\s`, a, str );
    returnunless( b );

    substring( a, b - a, str ) -> url;

    ;;; Trim off any "?xxx" stuff from the URL.
    lvars m = locchar( `?`, 1, url );
    if m then
        substring( m+1, url.datalength - m, url ) -> rest;
        substring( 1, m-1, url ) -> url;
    endif;

    lvars c = skipchar( `\s`, b, str );
    returnunless( c );

    substring( c, str.datalength - c + 1, str ) -> protocol;
enddefine;

define log_entry_url( le ) -> url; lvars le, url;
    nullstring -> url;
    lvars str = log_entry_request_string( le );

    lvars a = locchar( `\s`, 1, str );
    returnunless( a );

    skipchar( `\s`, a, str ) -> a;
    returnunless( a );

    ;;; Find the first space reading from -a-.
    lvars b = locchar( `\s`, a, str );
    returnunless( b );

    substring( a, b - a, str ) -> url;

    ;;; Trim off any "?xxx" stuff from the URL.
    lvars m = locchar( `?`, 1, url );
    if m then
        substring( 1, m-1, url ) -> url;
    endif;
enddefine;

define lconstant numberify( s ); lvars s;
    strnumber( s ) or s
enddefine;

define log_entry_status_code( le ); lvars le;
    le( 6 ).numberify
enddefine;

define log_entry_proxy_bytes( le ); lvars le;
    le( 7 ).numberify
enddefine;

endsection;
