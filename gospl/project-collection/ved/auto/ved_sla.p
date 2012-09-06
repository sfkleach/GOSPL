/* Chris Slymon, June 1983

    ENTER sla
        swap current line with the line above */

section $-ved => ved_sla;

define global ved_sla();
    vars vvedlinedump flag vedcolumn;
    if vedline = 1 then vedtoperror()
    elseif vedline > vvedbuffersize + 1 then
        vederror('End of file')
    endif;
    vvedlinesize -> flag;
    vedlinedelete();
    vedcharup();
    if flag > 0 then
        ved_yankl()
    else
        vedlineabove();
    endif;
enddefine;

endsection;
