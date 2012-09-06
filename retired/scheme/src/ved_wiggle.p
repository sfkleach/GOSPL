;;; --- University of Sussex POPLOG file -----------------------------------
;;; File:           $usepop/master/C.all/lisp/src/ved_wiggle.p
;;; Purpose:        Make ")" automatically wiggle opening "(" for ".lsp" files
;;; Author:         John Williams, Dec  2 1985
;;; Documentation:
;;; Related Files:  LIB *VEDMATCHBRACKET *VED_WMP


section;

global vars vedwiggling = true;

define lconstant Vdwigglehere;
    vedwiggle(vedline, vedcolumn)
enddefine;

define lconstant Vdfiletype;
    sysfiletype(vedcurrent)
enddefine;

define lconstant Vdketpdr(bra, ket, filetypes);
    lvars bra filetypes ket;
    vedinsertvedchar();
    vedcharleft();
    if vedwiggling and not(vedonstatus) and member(Vdfiletype(), filetypes) do
        vedmatchbracket(ket, bra, vedcharleft, vedatstart, Vdwigglehere)
    endif;
    vedcharright();
enddefine;

define global procedure ved_wiggle;
    lvars bra filetype filetypes ket key keypdr;

    if vedargument == vednullstring then
        'set vedwiggling' -> vedcommand;
        chain(veddocommand)
    endif;

    unless deststring(vedargument) == 2 and (-> ket -> bra, ket /== bra) do
        vederror('Two "bracket" characters needed (e.g. [])')
    endunless;
    consstring(ket, 1) -> key;

    vednormaltable(ket) -> keypdr;
    if pdpart(keypdr) == Vdketpdr then
        if isinheap(keypdr) then keypdr else copy(keypdr) endif
    elseunless keypdr == vedinsertvedchar do
        vederror('Cannot make "' <> key <> '" a wiggly key')
    else
        Vdketpdr(% bra, ket, [] %)
    endif -> keypdr;

    Vdfiletype() -> filetype;
    frozval(3, keypdr) -> filetypes;
    if member(filetype, filetypes) then
        'The "' <> key <> '" key reset for';
        ncdelete(filetype, filetypes, sys_=)
    else
        'The "' <> key <> '" key set for';
        filetype :: filetypes
    endif -> filetypes -> bra;

    if null(filetypes) then
        vedinsertvedchar -> keypdr;
        bra <> ' all file types'
    else
        filetypes -> frozval(3, keypdr);
        bra <> ' .' <> filetype <> ' files'
    endif -> vedmessage;
    vedsetkey(key, keypdr);
enddefine;

;;; MODIFIED Mon Dec  1 10:32:18 GMT 1986, Steve Knight
;;; Wiggle on '.s' files & more often too
12 -> vedwiggletimes;
vedsetkey(')', Vdketpdr(% `(`, `)`, ['s' 'lsp'] %));
vedsetkey('\^[.', ved_wmp);

endsection;
