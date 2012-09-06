compile_mode :pop11 +strict;

section;

uses postscript_line_consumer;

/* ==== VED_PRINT INTERFACE ============================================ */

;;; writes a range of a ved buffer to a file, converting it to PostScript
define lconstant PS_write_range( device, lo, hi ); lvars device, lo, hi;

    lvars file = device_open_name( device );

    ;;; write all the lines from lo to hi
    if lo <= vedline and vedline <= hi then vedtrimline() endif;
    min( vedusedsize( vedbuffer ), hi ) -> hi;

    if hi == 0 then
        ;;; buffer is empty
        if file then
            vedputmessage( file sys_>< '(EMPTY)' )
        endif;
        return;
    else
        if lo > hi then
            mishap(lo, hi, 2, 'IMPOSSIBLE RANGE TO WRITE')
        endif;
    endif;

    lvars procedure consume = postscript_line_consumer( device );

    while lo <= hi do
        ;;; write next line
        consume( subscrv( lo, vedbuffer ) );
        lo + 1 -> lo
    endwhile;

    consume( termin );      ;;; this doesn't close the device
enddefine;

lvars
    command,    ;;; print command to use: lpr(1) or lp(1)
    using_lpr,  ;;; <true> if -command- is lpr
    files,      ;;; list of files to print
    printer,    ;;; printer to use
    filters,    ;;; list of pre-filters
    copies,     ;;; number of copies to print
    flags,      ;;; other flags to pass
    devtype,    ;;; "ps" or false
;

;;; Choose which print command to use.
define lconstant setup();
    returnunless(isundef(command));
    if sys_search_unix_path('lpr', '/usr/ucb') ->> command then
        ;;; standard Berkeley LPR
        true -> using_lpr;
    elseif sys_search_unix_path('lp', systranslate('$PATH')) ->> command then
        ;;; standard System V LP
        false -> using_lpr;
    elseif sys_search_unix_path('lpr', systranslate('$PATH')) ->> command then
        ;;; Hmm ... has LPR, but may not be standard -- e.g. on HP-UX
        true -> using_lpr;
    else
        vederror('print: can\'t find print command (lpr/lp)');
    endif;
enddefine;

;;; Convert ved command flags into corresponding lpr/lp options.
define lconstant translate_flags();
    consstring(#|
        if strmember( `m`, flags ) then explode( '-m ' ) endif;
        if using_lpr then
            if strmember( `f`, flags ) then explode( '-h ' ) endif;
            if strmember( `h`, flags ) then explode( '-p ' ) endif;
            if strmember( `l`, flags ) then explode( '-l ' ) endif;
        else
            if strmember( `f`, flags ) or strmember( `l`, flags ) then
                vederror( 'print: lp(1) doesn\'t support flags -f & -l' );
            endif;
            if strmember( `h`, flags ) then [ ^^filters 'pr ' ] -> filters endif;
            ;;; always add '-s' to suppress messages
            explode( '-s ' );
        endif;
    |#) -> flags;
enddefine;

;;; Construct a shell command to do the printing
define lconstant gen_print_command( title ); lvars title;
    consstring(#|
        unless filters == [] then
            lvars filter;
            for filter in filters do
                explode( filter ), explode( '| ' );
            endfor;
        endunless;
        explode( command ), ` `;
        explode( flags );
        if copies > 1 then
            explode( if using_lpr then '-#' else '-n' endif );
            dest_characters( copies ), ` `;
        endif;
        unless printer = nullstring then
            explode( if using_lpr then '-P' else '-d' endif );
            explode( printer ), ` `;
        endunless;
        if title then
            if using_lpr then
                explode( '-J ' ), explode( title );
                explode( ' -T ' ), explode( title );
            else
                explode( '-t' ), explode( title );
            endif;
        endif;
    |#);
enddefine;

    ;;; split -vedargument- into flags, filters and files
define lconstant parseargument();
    lconstant SPECIALS = '-#.$~/:', FLAGS = 'fhlmd';
    lvars item, procedure items = incharitem( stringin( vedargument ) );

    ;;; modify the itemiser to treat SPECIAL characters as alphabetic
    appdata(
        SPECIALS,
        procedure( c ); lvars c;
            1 -> item_chartype( c, items )
        endprocedure
    );

    until ( items() ->> item ) == termin do
        if isinteger( item ) then
            item -> copies;
        elseif isstring( item ) then
            ;;; quoted file name
            [ ^^files ^item ] -> files;
        elseif isword( item ) and isstartstring( '-', item ) then
            ;;; parse flags
            lvars i, n = 0;
            for i from 2 to datalength(item) do
                lvars c = subscrw( i, item );
                if c == `p` then
                    if (items() ->> printer) == termin then
                        vederror('print: printer name expected after -p flag');
                    endif;
                elseif c == `d` then
                    if (items() ->> devtype) == termin then
                        vederror('print: device type name expected after -d flag');
                    endif;
                    unless devtype == "ps" then
                        vederror('print: ps expected after -d');
                    endunless;
                elseif c == `#` then
                    ;;; ignore
                elseif isnumbercode(c) then
                    ;;; number of copies
                    n * 10 + c - `0` -> n;
                elseif strmember( c, FLAGS ) then
                    flags <> consstring( c, 1 ) -> flags;
                else
                    vederror( 'print: unrecognized flag - ' <> consstring( c, 1 ) );
                endif;
            endfor;
            unless n == 0 then
                n -> copies
            endunless;
        elseif item == "(" then
            ;;; read a filter
            consstring(#|
                until ( items() ->> item ) == ")" do
                    if item == termin then
                        vederror( 'print: closing ) not found' );
                    else
                        dest_characters( item ),
                        ` `;
                    endif;
                enduntil;
            |#) -> item;
            [ ^^filters ^item ] -> filters;
        else
            [ ^^files ^( item sys_>< nullstring ) ] -> files;
        endif;
    enduntil;
    translate_flags();
enddefine;

    ;;; print a range of the current buffer
define lconstant vedprintmr( lo, hi ); lvars hi, lo;
    dlocal vednotabs = true;    ;;; to give correct spacing
    unless hi >= lo then
        vederror( 'print: nothing to print' )
    endunless;
    pipeout(
        consref( PS_write_range(% lo, hi %) ),
        '/bin/sh',
        [ 'sh' '-c' ^( gen_print_command( sys_fname_name( vedcurrent ) ) ) ],
        true
    );
enddefine;

define global vars ved_psprint();
    dlocal
        devtype = false,
        files   = [],
        printer = systranslate('popprinter') or nullstring,
        filters = [],
        copies  = 1,
        flags   = nullstring;

    setup();
    parseargument();
    "ps" -> devtype;

    vedputmessage( 'printing whole file ...' );
    vedprintmr( 1, vvedbuffersize );
    vedputmessage( 'print command queued' );
enddefine;

endsection;
