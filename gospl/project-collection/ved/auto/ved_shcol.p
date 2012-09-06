section $-ved => ved_shcol;

vars procedure oldvedprocesstrap;

define vedcol();
vars vedline vedtemp;
    if vedonstatus then
        return
    elseif vedusedsize(vedmessage) == 0 then
        ;;; no message to print
        ;;; ensure status line redrawn if line has changed
        vednamestring, true;
    else
        vedmessage, true;
    endif;
    vedline -> vedtemp;
    vedcolumn -> vedline;
    vedsetstatus(true);
    vedtemp -> vedline;
    vedsetcursor();
    oldvedprocesstrap()
enddefine;


define ved_shcol();
    if vedprocesstrap == vedcol then
        oldvedprocesstrap -> vedprocesstrap
    else
        vedprocesstrap -> oldvedprocesstrap;
        vedcol -> vedprocesstrap
    endif
enddefine;

endsection;
