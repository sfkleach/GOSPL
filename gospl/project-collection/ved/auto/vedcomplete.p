section $-VedComplete => vedcomplete;

define lconstant max_of( n ) -> ans; lvars n, ans;
    false -> ans;
    repeat n times
        lvars item = ();
        if item.isnumber then
            if ans.isnumber then
                max( ans, item )
            else
                item
            endif -> ans
        endif
    endrepeat
enddefine;

define procedure previousitem( line, posn ); lvars line, posn;
    lvars ch =
        max_of(#|
            locchar_back( ` `, posn, line ),
            locchar_back( `\t`, posn, line ),
            locchar_back( 160, posn, line ),    ;;; To work in immediate mode.
            locchar_back( `'`, posn, line )     ;;; To work with strings.
        |#);
    if ch then
        substring( ch+1, posn - ch, line )
    else
        substring( 1, posn, line )
    endif
enddefine;

define procedure finditem();
    lvars line = vedthisline();
    while vedcurrentchar() == ` ` do
        if vedcolumn == 1 then
            vederror( 'No file to extend' )
        endif;
        vedcolumn - 1 -> vedcolumn
    endwhile;
    until vedcurrentchar() == ` ` do
        vedcolumn + 1 -> vedcolumn
    enduntil;
    lvars finish = vedcolumn;
    previousitem( line, vedcolumn - 1 );
enddefine;

define procedure partcomplete( clist ); lvars clist;
    lvars head = clist.dest -> clist;
    lvars n = ( head.length, applist( clist, length <> min ) );
    lvars k;
    for k from 1 to n do
        lvars c, ch = subscrs( k, head );
        for c in clist do
            unless subscrs( k, c ) == ch do
                quitloop( 2 )
            endunless
        endfor;
    endfor;
    lvars i;
    for i from 1 to k-1 do
        vedcharinsert( subscrs( i, head ) )
    endfor;
enddefine;

define global vars procedure vedcomplete();
    lvars clist = finditem().filecomplete;
    if clist = [] then
        vedscreenbell()
    else
        if clist.tl = [] then
            vedinsertstring( clist.hd );
        else
            partcomplete( clist );
            vedscreenbell()
        endif
    endif
enddefine;

endsection;
