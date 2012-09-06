;;; Summary: incremental search in VED, similar to emacs ^S

compile_mode :pop11 +strict;

section;

define ved_incsearch();
vars vedediting vedargument;
    ;;; does an emacs-like incremental search
vars ch templine tempcolumn count oldvederror;
    unless vedediting then
        vederror('INTERACTIVE COMMAND RUN IN NON-EDITING MODE')
    endunless;
    vedputmessage('Start typing search string');
    vederror -> oldvederror;

        define vederror(str);
            unless str = 'NOT FOUND' then
                chainfrom(str,ved_incsearch,oldvederror)
            endunless;
            vedputmessage(vedargument><'/ NOT FOUND - either <del> or <esc>');
            vedscreenbell();
            0 -> count;
            exitto(ved_incsearch)
        enddefine;

    vedscreenbell();
    '/' -> vedargument;
    repeat
        repeat
            vedinascii() -> ch;
            unless ch == 13 then
                if ch > 31 then
                    cons_with consstring
                        {% explode(vedargument),
                            if ch == 127 then
                                if length(vedargument) > 1 then
                                    erase()
                                endif
                            else
                                ch
                            endif %}
                        -> vedargument
                else
                    if ch == 27 and not(sys_inputon_terminal(popdevraw)) then
                        vedputmessage('NORMAL EDITING')
                    else
                        vedinput(ch);
                    endif;
                    quitloop(2)
                endif
            endunless;
            syssleep(25);
            quitunless(sys_inputon_terminal(popdevraw));
        endrepeat;
        true -> vedediting;
        vedline -> templine, vedcolumn -> tempcolumn;
        unless ch == 13 then 1 -> count endunless;
        ved_search();
        if count == 0 then nextloop endif;
        if vedline == templine and vedcolumn == tempcolumn then
            vedputmessage('ONLY ONE MATCH');
            sys_purge_terminal(popdevraw);
            quitloop
        else
            unless ch == 13 then
                false -> vedediting;
                vedline -> templine, vedcolumn -> tempcolumn;
                ved_search();
                until vedline == templine and vedcolumn == tempcolumn do
                    ved_search();
                    1 + count -> count;
                    if count > 9 then
                        'MANY' -> count;
                        vedjumpto(templine,tempcolumn);
                        quitloop
                    endif
                enduntil;
                true -> vedediting;
            endunless;
            if count == 1 then
                vedputmessage('ONLY ONE MATCH');
                sys_purge_terminal(popdevraw);
                quitloop
            else
                vedputmessage('THERE ARE '><count><' MATCHES FOR '
                    ><vedargument><'/')
            endif;
            vedwiggle(vedline,vedcolumn);
        endif
    endrepeat;
    vedscreenbell()
enddefine;

vedsetkey( '\^[.', ved_incsearch );

endsection;
