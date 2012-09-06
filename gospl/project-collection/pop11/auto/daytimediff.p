;;; Summary: differences in time in friendly format

/*  lib daytimediff                                      R.Evans March 1984

    daytimediff() returns the elapsed time since it was last called
    (in seconds, based on a 24 hr clock).
    The first call returns the current time.
    Compare with *TIMEDIFF
*/

section $-daytimediff => daytimediff;

vars last_daytime; false -> last_daytime;


/* return daytime in seconds */
define get_daytime;
    vars daytime;
    sysdaytime() -> daytime;
    strnumber(substring(12,2,daytime)) * 3600 +
    strnumber(substring(15,2,daytime)) * 60 +
    strnumber(substring(18,2,daytime));
enddefine;

define global daytimediff;
    vars temp;
    last_daytime -> temp;
    get_daytime() -> last_daytime;
    if temp then
        last_daytime - temp;
        /* 24 hr wrap round check */
        if dup() < 0 then nonop +(86400) endif;
    else
        last_daytime;
    endif;
enddefine;

section_cancel(current_section);

endsection;
