;;; Summary: VED based alarm clock!

/*     A clock for ved           R.Evans July 1983

    This library provides two ved commands ENTER CLOCK and ENTER SECS.
    ENTER CLOCK switches the clock on and off alternately, while ENTER SECS
    switches between displaying or not displaying seconds.

    ENTER ALARM allows you to set a time for an alarm to go off. eg
        <enter> alarm 12:02
    NB: alarm string must match time string exactly for alarm to ring.

    The clock appears on the status line on the right hand side

    Note: if you go out of VED the clock is stopped - you may get a
          double prompt from POP11 (ignore it)

    do
        uses ved_clock
        $-clock$-startclock -> vedinitfile;

    in your VEDINIT.P to get clock on whenever you are in ved
*/

section $-clock => ved_clock,ved_secs, ved_alarm;

/* borrowed from system source */
define Vedinputwaiting();
    if ispair(ved_char_in_stream) then true
    else sys_inputon_terminal(popdevraw)
    endif;
enddefine;

constant clockinterval;

1 -> clockinterval;    ;;; value of pop_timeout_secs

vars clockon clocklength timethen oldoffset oldlength;

false -> clockon;             ;;; clock off initially
5 -> clocklength;             ;;; length of clock string to use

/* alarm handling */
vars alarmstring; false -> alarmstring;

define global ved_alarm;
    if vedargument = vednullstring then
        vederror(if alarmstring then
                    'ALARM is: ' >< alarmstring
                 else
                    'no alarm set'
                 endif);
    else
        vedargument -> alarmstring;
    endif;
enddefine;

define alarm;
    repeat 3 times;
        vedputmessage('ALARM');
        vedscreenbell();
        syssleep(10);
        vedputmessage('');
    endrepeat;
    vedsetcursor();
    sysflush(popdevraw);
enddefine;

vars procedure (startclock, stopclock);

/* check the time - update if it's changed */
define CLOCKCHECK;
    vars timenow;

    unless clockon then return endunless;

    unless vedediting then
        stopclock();
        return
    endunless;

    /* don't update if there is input to be processed */
    if Vedinputwaiting() then return endif;

    substring(12,clocklength,sysdaytime()) -> timenow;

    unless clocklength == oldlength
       and vedscreenoffset == oldoffset
       and timenow = timethen
    then

        timenow -> timethen;
        clocklength -> oldlength;
        vedscreenoffset -> oldoffset;

        ;;; send new clock string

        vedscreenescape(vvedscreenpoint);
        vedoutascii(vedscreenoffset+32);
        vedoutascii(101);

        if clocklength == 5 then
            vedscreencursor,vedscreencursor,vedscreencursor;
        endif;
        ;;; vedscreencommandmark;
        vedscreencursor;

        explode(timenow);

        ;;; vedscreenlinemark;
        vedscreencursor;
        vedscreencursor;
        consstring(11) -> timenow;

        appdata(timenow,vedscreenoutput);

        1000 -> vedscreenline;
        vedsetcursor();
        sysflush(popdevraw);
    endunless;

    if alarmstring and alarmstring = timenow then
        alarm();
        false -> alarmstring;
    endif;

enddefine;


/* this procedure gets put in vedprocesstrap - check clock every time
   a character is processed */
define CLOCK(vedprocesstrap);
    CLOCKCHECK();
    vedprocesstrap(); /* run old vedprocesstrap */
enddefine;



define stopclock;
    if clockon then
        if pdpart(vedprocesstrap) == CLOCK then
            frozval(1,vedprocesstrap) -> vedprocesstrap;
        endif;
        identfn -> pop_timeout;
        false -> pop_timeout_secs;
        false -> clockon;
    endif;
enddefine;

/* setting vedprocesstrap isn't enough - set pop_timeout too to cope with
   long waits at the keyboard */
define startclock;
    unless clockon then
        CLOCK(%vedprocesstrap%) -> vedprocesstrap;
        CLOCKCHECK -> pop_timeout;
        clockinterval -> pop_timeout_secs;
        true -> clockon;
    endunless;
    /* this will force clock to refresh next time */
    false ->> oldlength -> oldoffset;
enddefine;

define global ved_clock;
    if clockon then
        stopclock();
        'CLOCK OFF';
    else
        startclock();
        'CLOCK ON';
    endif;
enddefine;



/* SECS just alters parameters detailed above */
define global ved_secs;
    if clocklength == 5 then
        'SECS ON';  8;
    else
        'SECS OFF'; 5;
    endif;
        -> clocklength;
enddefine;


endsection;
