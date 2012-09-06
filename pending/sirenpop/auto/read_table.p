compile_mode :pop11 +strict;

section;

;;; read_table( FILE, [WIDTH], [SEPARATOR_CHAR, STRING_QUOTE] )

define global read_table( fname ); lvars fname;
    lconstant quote_char_class = 7;
    lconstant separator_char_class = 5;

    lvars
        width = false,
        qchar = `'`,
        tchar = `\t`;

    ;;; Process optional parameters.
    if fname.isboolean then
        fname -> qchar;
        () -> tchar;
        () -> fname;
    endif;
    if fname.isnumber then
        fi_check( fname, 0, false ) -> width;
        () -> fname;
    endif;
    unless fname.isstring do
        mishap( 'FILE NAME NEEDED', [ ^fname ] )
    endunless;

    dlocal popnewline = true;
    lvars procedure items =
        incharitem(
            fname.isstring and fname.discin or
            fname.isprocedure and fname or
            mishap( 'FILENAME OR CHARACTER REPEATER NEEDED', [ ^fname ] )
        );

    unless qchar then
        quote_char_class -> item_chartype( `"`, items );
        separator_char_class -> item_chartype( `'`, items );
    endunless;
    separator_char_class -> item_chartype( tchar, items );
    items.newpushable -> items;

    lvars logical_tab = consword(#| tchar |#);

    define lconstant item_rptr();
        dlocal popnewline = true;

        define lconstant check( n ); lvars n;
            if not( width ) or width ==# n then
                consvector( n )
            else
                mishap( 'INCORRECT NUMBER OF ENTRIES IN TABLE', [ ^n ] )
            endif
        enddefine;

        lvars n = 0;
        lvars item = undef;
        repeat
            items() -> item;
            quitif( item == termin or item == newline );
            if item == logical_tab then
                undefined
            else
                item;
                lvars next = items();
                if next == newline then
                    next -> items()
                elseunless next == logical_tab do
                    mishap( 'ERROR IN TABLE, EXPECTING FIELD SEPARATOR', [ ^next ] )
                endif
            endif;
            n + 1 -> n;
        endrepeat;
        if item == termin then
            if n == 0 then
                termin;
            else
                check( n );
                listtopd( [] ) -> items;    ;;; Good for a single <termin>.
            endif
        elseif n == 0 then
            chain( item_rptr )              ;;; Removes comments & blank lines.
        else
            check( n )
        endif
    enddefine;

    pdtolist( item_rptr )
enddefine;

endsection;
