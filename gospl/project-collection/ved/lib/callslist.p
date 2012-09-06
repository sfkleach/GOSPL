;;; Summary: builds a list of all procedure calls in Pop11 program in VED

/* CALLSLIST     Chris Thornton   Aug 84 */
/* builds a list of all procedure calls in POP program in VED buffer */

;;; Edited by Steve Knight, Sept 93.  Bring into line with modern
;;; coding style.

section;
compile_mode :pop11 +strict;

lvars items;

define lconstant search_S( str ); lvars str;
    ;;; search from here to the end of the file (ie. South)
    lvars line;
    for line from vedline to vvedbuffersize do
        lvars col;
        if
            issubstring(
                str,
                if line = vedline then vedcolumn else 1 endif,
                vedbuffer(line)
            ) ->> col
        then
            vedjumpto(line, col); return(true)
        endif
    endfor;
    return(false)
enddefine;


define lconstant allprocs() -> procs;
    lvars isop item Aline procs;
    [] -> procs;
    newassoc([]) -> items;
    vedtopfile();
    until not(search_S(consstring(`d,`e,`f,`i,`n,`e,` `,7))) do
       vedline -> Aline;
       false -> isop;
       repeat
          vedmoveitem() -> item;
          if strmember(`]`, vedthisline()) or
                strmember(`@`, vedthisline()) or
                strmember(`'`, vedthisline()) or
                item = "(" then
             quitloop
          elseif isnumber(item) then
             true -> isop; nextloop
          elseif identprops(item) == "syntax" then
             nextloop
          endif;
          /* if we've got to here, must be past all the junk */
          if isop then
             [% until item = ";" do item; vedmoveitem() -> item enduntil%] -> item;
             if length(item) == 3 then fast_back(item) -> item endif;
             fast_front(item) -> item;
          endif;
          if search_S('enddefine') then
             item :: procs -> procs;
             incharitem(vedrangerepeater(Aline, vedline)) -> items(item);
          endif;
          quitloop
       endrepeat;
       vednextline()
    enduntil
enddefine;


define lconstant allcalls( procs ); lvars procs;
    lvars item;

    define lconstant read_to_eol( proc ); lvars proc;
        until (items(proc)() ->> item) = ";" or item == termin do
            ;;; Nothing.
        enduntil
    enddefine;

    [%
        lvars proc;
        for proc in procs do
            [%
                proc;
                vedputmessage(
                    'CALLSLIST: setting calls-list for ' sys_>< proc
                );
                read_to_eol( proc );
                until ( items( proc )() ->> item ) == termin do
                    if item = "lvars" or item = "vars" then
                        read_to_eol( proc )
                    elseif lmember(item, procs) then
                        item
                    endif;
                 enduntil
            %]
        endfor
    %]
enddefine;

define callslist();
   dlocal pop_longstrings = true ;
   allcalls( allprocs() )
enddefine;

endsection;
