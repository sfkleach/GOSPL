;;; Summary: abbreviation expansion facility

/* Chris Slymon                                                   June 1983 */

section $-ved => vedautoabb vedsetabb ved_shabb ved_xabb ved_nxabb ved_abb
                     ved_abb_expanders;

;;; the "word-break" character strings that will trigger abb expansion
global vars ved_abb_expanders;
[% ' ', ',', ';', '\r', '\t' %] -> ved_abb_expanders;

vars vedabbprops;

define vedlastword() -> vedtemp;
    vars vedline vedcolumn _string;
    vedsetlinesize();
    if vedcolumn == 1 or vedcolumn > vvedlinesize + 1
            or (vedthisline() -> _string; _string(vedcolumn - 1) = ` `) then
        false
    else
        vedcolumn -> vedtemp;
        vedcharleft();
        until vedatitemstart(vedcolumn,_string,vvedlinesize + 1) do
            vedcolumn - 1 -> vedcolumn;
        enduntil;
        substring(vedcolumn,vedtemp-vedcolumn,_string)
    endif; -> vedtemp;
enddefine;

define global vedwordbreak(proc);
    vars vedtemp last_word len;
    unless vedonstatus then
        if (vedlastword() ->> last_word) and
                (vedabbprops(consword(last_word)) ->> vedtemp) then
            if vedtemp.isprocedure then
                vedtemp()
            else
                length(last_word) -> len;
                if issubstring(last_word,1,vedtemp) = 1 then
                    substring(len fi_+ 1,
                        length(vedtemp) fi_- len,vedtemp) -> vedtemp;
                else
                    repeat len times
                        vedchardelete();
                    endrepeat;
                endif;
                vedinsertstring(vedtemp)
            endif
        endif;
    endunless;
    proc();
enddefine;

define global vedsetabb( word);
    vars temp;
    if isproperty( word) then
        word -> vedabbprops;
    elseif stacklength() = 0 then
        mishap('Bad argument for VEDSETABB',[ ^word]);
    else
        unless isstring(dup() -> temp) or isprocedure( temp)
                and isword( word) then
            mishap('Inappropriate arguments for VEDSETABB',[ ^temp ^word]);
        endunless;
        temp -> vedabbprops( word);
    endif;
enddefine;

define xabbchar( string);
    vars temp;
    unless pdpart( vedgetproctable(string) ->> temp) == vedwordbreak then
        vedsetkey(string,vedwordbreak(% temp %));
    endunless;
enddefine;

define global ved_xabb();
    applist( ved_abb_expanders, xabbchar);
enddefine;

define nxabbchar(string);
    vars temp;
    if isclosure( vedgetproctable(string) ->> temp) then
        vedsetkey(string , frozval( 1, temp));
    endif;
enddefine;

define global ved_nxabb();
    applist( ved_abb_expanders, nxabbchar);
enddefine;

define ved_shabb();
    vars temp;
    if vedargument = '' then
        appproperty( vedabbprops,
            procedure item value;
                pr( newline);
                pr( item); pr(tab); pr(value);
            endprocedure);
    elseif vedabbprops(consword(vedargument)) ->> temp then
        vedputmessage( '' >< temp); /* could be a procedure */
    else
        vedputmessage(vedargument >< ' is not an abbreviation');
    endif;
enddefine;

define global ved_abb();
    vars _space temp;
    if vedargument = '' then
        vederror('Usage: abb <string> <string>');
    elseif locchar( ` `, 1, vedargument) ->> _space then
        /* abb xx xxyyzz */
        substring(1,_space - 1,vedargument) -> temp;
        substring(_space+1,length(vedargument) - _space,vedargument) -> _space;
        _space -> vedabbprops(consword(temp));
    else
        /* abb xx */
        if vedargument = '*' then
            vedputmessage('All abbreviations cleared');
            appproperty( vedabbprops,
                procedure item value;
                    false -> vedabbprops( item);
                endprocedure);
        elseif vedabbprops( consword( vedargument)) then
            vedputmessage( vedargument >< ' cleared');
            false -> vedabbprops(consword(vedargument));
        endif;
    endif;
enddefine;

vars vedabbstring; inits(20) -> vedabbstring;

define vedreadstring(message,wobble) -> string;
    vars char num;
    if message then
        vedscreenbell();
        vedputmessage(message);
    endif;
    vedabbstring -> string;
    0 -> num;
    repeat
        quitif ((vedinascii() ->> char) = vedescape);
        if char == 127 then
            unless num = 0 then
                num fi_- 1 -> num;
            else
                vedscreenbell();
            endunless;
        else
            num fi_+ 1 -> num;
            char -> subscrs(num,string);
        endif;
        vedputmessage(substring(1,num,string));
        if wobble then
            vedsetcursor();
        endif;
    endrepeat;
    if num = 0 then
        false
    else
        substring(1,num,string)
    endif; -> string;
enddefine;

define vedautoabb();
    vars word abbv;
    unless vedlastword() ->> word then
        vederror('No word to abbreviate');
    endunless;
    if vedreadstring('Abbreviation for ' >< word, false) ->> abbv then
        vedsetabb( word, consword(abbv));
    endif;
enddefine;

endsection;

;;; set up some default abbreviations
uses vedabbprops;
vedsetabb( ved_pop_abbs);

;;; temporary assignment
vedsetkey('\^[a', vedautoabb);
