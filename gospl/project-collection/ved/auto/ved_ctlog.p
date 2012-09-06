;;; Summary: logging routines for VED users (orig. Comp & Thought students)

/* VED logging routine for Prolog CT students        R.Evans February 1984

   See HELP *CTLOG  See also ved_ctplay
*/

uses daytimediff;

section $-ctlog => ved_ctlog ved_ctnolog;

vars oldrawcharin;  rawcharin -> oldrawcharin;

vars vedlogfile;    false -> vedlogfile;

define log_time;
    vars d;
    daytimediff() -> d;
    while d > 254 do
        vedlogfile(255);
        d - 255 -> d;
    endwhile;
    vedlogfile(d);
enddefine;

/* rawcharin which checks logfile */
define vedlogcharin -> c;
    oldrawcharin() -> c;
    if vedlogfile then
        vedlogfile(c);
        log_time();
    endif;
enddefine;


define global ved_ctlog;
    vars user;
    if length(vedbufferlist) == 1 and hd(vedbufferlist)(1) = 'output' then
        ved_clear();
        if vedargument = vednullstring then
            locchar(` `,1,popusername) -> user;
            if user then
                substring(1,user-1,popusername)
            else
                popusername
            endif
        else
            vedargument
        endif -> user;
        unless locchar(`.`,1,user) then
            user >< '.log' -> user;
        endunless;
        discout('/mnt/joset/logfiles/'>< user) -> vedlogfile;
        vedlogcharin -> rawcharin;
        vedputmessage('logging');
        prolog_compile -> popcompiler;
        erase(daytimediff());
    else
        vederror('Too many ved files for ctlog');
    endif;
enddefine;

define global ved_ctnolog;
    if vedlogfile then
        vedlogfile(termin);
        false -> vedlogfile;
        oldrawcharin -> rawcharin;
        vedputmessage('end of logging');
    else
        vederror('not logging');
    endif;
enddefine;

endsection;
