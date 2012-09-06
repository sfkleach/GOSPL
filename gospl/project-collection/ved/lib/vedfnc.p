;;; Summary: alternative VED file name completion library

section;

define lconstant procedure previousitem( line, posn ); lvars line, posn;
    lvars ch =
        locchar_back( ` `, posn, line ) or
        locchar_back( 160, posn, line );    ;;; to work in immediate mode
    if ch then
        substring( ch+1, posn - ch, line )
    else
        substring( 1, posn, line )
    endif
enddefine;

define lconstant procedure finditem();
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

define lconstant procedure partcomplete( clist ); lvars clist;
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

lconstant buffername = '*COMPLETIONS*';

define lconstant procedure showcompletions( name, completions ); lvars name, completions;
    if vedvedname = buffername then
        ved_qved( buffername -> vedargument )
    else
        vededitor(
            vedhelpdefaults,
            buffername
        )
    endif;
    ved_clear();
    vedputmessage(
        length( completions ) sys_><
        ' File completions for ' sys_><
        name
    );
    applist(
        completions,
        procedure( c ); lvars c;
            vedinsertstring( name );
            vedinsertstring( c );
            vednextline();
        endprocedure
    );
    vedtopfile();
enddefine;

define lconstant procedure vedusecompletion();
    vedtrimline();
    lvars completion = vedthisline();
    ved_q();
    lvars len = finditem().length;
    lvars i;
    for i from len+1 to completion.length do
        vedcharinsert( completion( i ) );
    endfor;
enddefine;

define global vars procedure vedcompletions();
    if vedvedname = buffername then
        ;;; We are in the completions buffer -- so treat as completer
        vedusecompletion();
    else
        ;;; Try to complete
        lvars name = finditem();
        lvars completions = name.filecomplete;
        if completions.null then
            vedscreenbell()
        elseif completions.tl.null then
            vedinsertstring( completions.hd )
        else
            partcomplete( completions );
            showcompletions( name, completions );
        endif
    endif
enddefine;

endsection;
