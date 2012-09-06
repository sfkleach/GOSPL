/* Chris Slymon, June 1983

    ENTER slb
        swap current line with the line below */

section $-ved => ved_slb;

define global ved_slb();
    vars vvedlinedump flag vedcolumn;
    if vedline > vvedbuffersize then
        vederror('End of file')
    elseif vedline = vvedbuffersize and
        vedusedsize(vedbuffer(vedline - 1)) = 0 then
        vedlineabove();
    else
        vvedlinesize -> flag;
        vedlinedelete();
        vedchardown();
        if flag > 0 then
            ved_yankl()
        else
            vedlineabove();
        endif;
    endif;
enddefine;

endsection;
