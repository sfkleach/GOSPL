;;; Summary: example of abbreviation facility

/* LIB VEDENDABBS                                   Chris Slymon, October 1983

Procedures for use with LIB VEDABBS, demonstrating the use of procedures as
abbreviation "expansions". */

define vedmatchendstartingat( column) -> _item;
    vars vedline vedcolumn vvedlinesize;
    until vedline = 1 do
        vedcharup();
        unless vvedlinesize = 0 then
            vedtextleft();
            if vedcolumn = column
                    and member(vednextitem() ->> _item,vedopeners) then
                return
            endif;
        endunless;
    enduntil;
    false  -> _item;
enddefine;

define vede_abbfn();
    vars ending;
    vedmatchendstartingat(vedcolumn - 1) -> ending;
    if ending then
        vedinsertstring('nd' >< ending);
    endif;
enddefine;

define veder_abbfn();
    vars ending;
    vedmatchendstartingat(max(vedcolumn - 2 - vedindentstep, 1)) -> ending;
    if ending then
        vedchardelete();
        vedinsertstring('nd' >< ending >< ';');
    endif;
enddefine;

define vedeb_abbfn();
    vars ending;
    vedmatchendstartingat(max(vedcolumn - 2 - vedindentstep, 1)) -> ending;
    if ending then
        vedchardelete();
        vedchardelete();
        max(vedcolumn - vedindentstep, 1) -> vedcolumn;
        vedinsertstring('end' >< ending);
    endif;
enddefine;
