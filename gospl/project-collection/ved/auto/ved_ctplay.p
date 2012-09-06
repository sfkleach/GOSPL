;;; Summary: playback of a log file created by ved_ctlog

/* Playback of a log file created by ved_ctlog      R.Evans February 1984

   See HELP *CTLOG   See also ved_ctlog
*/

uses daytimediff;

section $-ctlog => ved_ctplay ctplay_trap ved_ctnolog;

vars oldrawcharin; rawcharin -> oldrawcharin;

/* uses ct_timed (autoloadable) flag to enable timing information */

define end_play();
    oldrawcharin -> rawcharin;
    vederror('end of playback');
enddefine;

define show_time(rep);
    vars c d;
    0 -> d;
    while (rep() ->> c) == 255 do d + 255 -> d; endwhile;
    if c == termin then end_play() endif;
    (d + c) >< '' -> d;

    /* now display time */
    vedscreenescape(vvedscreenpoint);
    vedoutascii(vedscreenoffset+32);
    vedoutascii(103);
    repeat 6-length(d) times vedscreencursor endrepeat;
    explode(d);
    consstring(6);
    appdata(vedscreenoutput);
    1000 -> vedscreenline;
    vedsetcursor();
enddefine;

vars musttrap; false -> musttrap;
define global ctplay_trap(c);
    if sys_inputon_terminal(popdevraw) then
        erase(oldrawcharin());
        vedscreenbell();
        true -> musttrap;
    endif;
    if musttrap then
        (oldrawcharin() == ` `) -> musttrap;
    endif;
enddefine;

global vars ved_ctnolog;
unless ved_ctnolog.isprocedure then identfn -> ved_ctnolog endunless;

define vedctplaycharin(rep) -> c;
    rep() -> c;
    if c == termin then
        end_play()
    else
        if ct_timed then show_time(rep); endif;
        ctplay_trap(c);
    endif;
enddefine;

define popexit;
    if rawcharin.isclosure and pdpart(rawcharin) == vedctplaycharin then
        oldrawcharin -> rawcharin;
        pr('CTPLAY - user logged out!\n');
        setpop();
    endif;
enddefine;

define global ved_ctplay;
    vars vedargument;
    if vedargument = vednullstring then vederror('no username given') endif;
    if length(vedbufferlist) == 1 and hd(vedbufferlist)(1) = 'output' then
        ved_clear();
        unless issubstring('.',1,vedargument) then
            vedargument >< '.log' -> vedargument;
        endunless;
        false -> musttrap;
        vedctplaycharin(%
            discin('/mnt/joset/logfiles/'>< vedargument)%)
        -> rawcharin;
        prolog_compile -> popcompiler;
        vedputmessage('playing');
    else
        vederror('Too many ved files for ctplay');
    endif;
enddefine;


endsection;
