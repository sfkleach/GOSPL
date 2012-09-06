;;; Summary: library for working with universal time.
;;; Version: 1.1
;;; Modified: 1.0 -> 1.1, Removed use of experimental "module" feature (defensive).

compile_mode :pop11 +strict;

section $-universal_time =>
    universal_time                  ;;; hack
    day_of_week
    get_universal_time
    get_decoded_time
    name_of_day
    name_of_month
    decode_universal_time
    encode_universal_time
    number_of_month
    length_of_month
    number_of_day
    seconds_per_minute
    minutes_per_hour
    seconds_per_hour
    seconds_per_day
    seconds_per_week
    real_time_to_universal_time
    universal_time_to_real_time
    is_leap_year
;

;;; Ensure this works with uses.
global vars universal_time = true;

lconstant seconds_in_day = 86400;

lconstant seconds_from_1900_1970 =
    70 * 365 * seconds_in_day +
    17 * seconds_in_day;            ;;; 17 leap years.

define global get_universal_time();
    sys_real_time() + seconds_from_1900_1970
enddefine;

define global real_time_to_universal_time( t ); lvars t;
    t + seconds_from_1900_1970
enddefine;

define global universal_time_to_real_time( t ); lvars t;
    t - seconds_from_1900_1970
enddefine;

lconstant gmt_time_zone = 0;

constant
    seconds_per_minute  = 60,
    minutes_per_hour    = 60,
    seconds_per_hour    = minutes_per_hour * seconds_per_minute,
    seconds_per_day     = seconds_per_hour * 24,
    seconds_per_week    = seconds_per_day * 7,
    hours_per_day       = 24,
    days_per_week       = 7,
    days_per_year       = 365,
    days_per_leap_year  = days_per_year + 1,
    days_per_4_nl_years = days_per_year * 4,
    days_per_4_years    = days_per_leap_year + 3 * days_per_year,
    days_per_100_years  = days_per_4_nl_years + 24 * days_per_4_years,
    days_per_400_years  = days_per_100_years * 4 + 1,
    days_in_months      = {31 28 31 30 31 30 31 31 30 31 30 31},
    leap_days_in_months = {31 29 31 30 31 30 31 31 30 31 30 31},
    day_names           = { Monday Tuesday Wednesday Thursday Friday Saturday Sunday },
    month_names         = { January February March April May June July August September October November December }
    ;

define global is_leap_year( y ); lvars y;
    ( y mod 4 == 0 and y mod 100 /== 0 ) or ( y mod 400 == 0 )
enddefine;

define lconstant Check_time_int( str, lo, hi, i ); lvars i, lo, hi, str;
    unless isintegral( i ) and i >= lo then
        mishap(
            i, 1,
            (
                if lo == 0 then
                    'Non-negative'
                else
                    'Positive'
                endif
            ) <> ' integer needed for ' <> str <> ' value'
        );
    endunless;
    if hi and i > hi then
        mishap( i, 1, str <> ' value out of range' );
    endif
enddefine;

define global day_of_week( u_time, tz ); lvars u_time, tz;
    unless tz do
        gmt_time_zone -> tz
    endunless;
    Check_time_int( 'time zone', 0, 23, tz );
    u_time - tz * seconds_per_hour -> u_time;
    Check_time_int( 'universal time', 0, false, u_time );
    u_time div seconds_per_day mod days_per_week + 1
enddefine;

define global decode_universal_time( u_time, tz ); lvars u_time, tz;
    lvars year, month, date, hour, minute, sec, month_days, tmp ;

    unless tz do
        gmt_time_zone -> tz
    endunless;

    Check_time_int( 'time zone', 0, 23, tz );
    u_time - tz * seconds_per_hour -> u_time;

    Check_time_int( 'universal time', 0, false, u_time );

    u_time // seconds_per_minute  -> u_time -> sec;
    u_time // minutes_per_hour    -> u_time -> minute;
    u_time // hours_per_day       -> u_time -> hour;

    ( u_time // days_per_400_years ) * 400 -> year -> u_time;
    ((u_time // days_per_100_years) ->> tmp) * 100 + year -> year -> u_time;

    ;;; leap year is year 1 (ie sec) of 4 year group.
    if tmp /== 1 then
        if u_time > days_per_4_nl_years then
            u_time - days_per_4_nl_years -> u_time;
            year + 4 /* skip the first 4 year group */ -> year;
        endif;
    endif;
    (u_time // days_per_4_years) * 4 + year -> year -> u_time;
    year + 1900 -> year;

    if u_time < days_per_leap_year then
        leap_days_in_months
    elseif u_time == days_per_leap_year then
        u_time // days_per_leap_year + year -> year -> u_time;
        days_in_months
    else
        u_time - days_per_leap_year -> u_time;
        u_time // days_per_year + 1 /* leap day */ + year -> year -> u_time;
        days_in_months
    endif -> month_days;

    1 /* january */ -> month;
    while (u_time - month_days(month) ->> tmp) >= 0 do
        month + 1 -> month;
        tmp -> u_time;
    endwhile;

    ;;; days are 1 (not 0) origin.
    u_time + 1 -> date;

    return( sec, minute, hour, date, month, year, tz )
enddefine;


define global get_decoded_time();
    decode_universal_time( get_universal_time(), gmt_time_zone )
enddefine;

define global encode_universal_time( sec, minute, hour, date, month, year, tz );
    lvars sec, minute, hour, date, month, year, tz;
    lvars u_time, this_year, i, month_days;

    unless tz do
        gmt_time_zone -> tz
    endunless;

    Check_time_int( 'year', 0, false, year );
    if year < 100 then                              ;;; use "obvious" year.
        erasenum(#| get_decoded_time().erase -> this_year |#);
        this_year div 100 * 100 + year -> year;
        if this_year - year > 50 then year + 100 -> year endif;
    endif;
    (year ->> this_year) - 1900 /* base year */ -> year;

    year // 400 * days_per_400_years -> u_time -> year;
    if year > 100 then u_time + 1 /* leap day per 400 years */ -> u_time endif;
    year // 100 * days_per_100_years + u_time -> u_time -> year;
    if year > 3 then        /* possibility of leap year */
        year - 4 -> year;   /* ignore non leap year at beginning of century */
        u_time + days_per_4_nl_years -> u_time;

        year // 4 * days_per_4_years + u_time -> u_time -> year;
        if year > 0 then u_time + 1 -> u_time endif; /* last was leap year */
    endif;
    year * days_per_year + u_time -> u_time;

    Check_time_int( 'month', 1, 12, month );
    if is_leap_year( this_year ) then
        leap_days_in_months
    else
        days_in_months
    endif -> month_days;
    for i from 1 /* january */ to month - 1 do
        u_time + month_days(i) -> u_time;
    endfor;

    Check_time_int( 'date', 1, month_days(month), date );
    u_time + (date - 1 /* convert date to 0 origin */) -> u_time;

    Check_time_int( 'hour', 0, 23, hour );
    u_time * hours_per_day + hour -> u_time;

    Check_time_int( 'minute', 0, 59, minute );
    u_time * minutes_per_hour + minute -> u_time;

    Check_time_int( 'sec', 0, 59, sec );
    u_time * seconds_per_minute + sec -> u_time;

    Check_time_int( 'time zone', 0, 23, tz );
    u_time + tz * seconds_per_hour;
enddefine;

define global name_of_day( n ); lvars n;
    day_names( n )
enddefine;

define global name_of_month( n ); lvars n;
    month_names( n )
enddefine;

define global number_of_month( m ); lvars m;
    lvars name, k;
    for name with_index k in_vector month_names do
        if isstartstring( m.uppertolower, name.uppertolower ) do
            return( k )
        endif
    endfor;
    false
enddefine;

define global length_of_month( it ); lvars it;

    define lconstant oops();
        mishap( 'MONTH NUMBER OR NAME NEEDED', [ ^it ] )
    enddefine;

    if it.isinteger and 1 <= it and it <= 12 then
        days_in_months( it )
    elseif it.isword or it.isword then
        lvars n = number_of_month( it );
        if n then
            length_of_month( n )
        else
            oops()
        endif
    else
        oops()
    endif;
enddefine;

define global number_of_day( m ); lvars m;
    lvars name, k;
    for name with_index k in_vector day_names do
        if isstartstring( m.uppertolower, name.uppertolower ) do
            return( k )
        endif
    endfor;
    false
enddefine;

endsection;
