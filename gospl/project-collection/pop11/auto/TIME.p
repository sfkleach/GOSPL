;;; Summary: facility for timing commands  -- used at PLUG92

compile_mode :pop11 +strict;

section;

global vars TIME_min_time = 500;
global vars TIME_min_iterations = 1;

;;; t is in centi-secs.  We want it micro-units.
define lconstant scale_time( t ); lvars t;

    lconstant scales = [
        {1 secs}
        {60 mins}
        {^(60*60) hours}
        {^(24*60*60) days}
        {^(7*24*60*60) weeks}
        {^(30*24*60*60) months}  ;;; well, sort of ...
        {^(365*24*60*60) years}  ;;; close enough
        {^(10*365*24*60*60) decades}
        {^(100*365*24*60*60) centuries}
        {^(1000*365*24*60*60) millenia}
    ];

    lvars ut = 1.0e4 * t;       ;;; get into millionths of seconds
    ;;; find right scale.
    lvars i, sofar = {1 secs};
    for i in scales do
        lvars ratio = i( 1 );
        if ut > ratio then
            i -> sofar
        else
            quitloop
        endif;
    endfor;
    return( sprintf( '%p micro-%p', [% ut/sofar(1), sofar(2) %] ) );
enddefine;

define lconstant calc_overhead( N ); lvars N;
    lvars start = systime();
    fast_repeat N times
    endrepeat;
    setstacklength( 0 );
    systime() - start;
enddefine;

define lconstant report( N, st, gt ); lvars N, st, gt;
    lvars d = calc_overhead( N );
    max( 0, st - d ) -> st;             ;;; adjust for loop overhead
    nprintf( '    Av. time    =  %p msecs', [% 10.0 * st / N %] );
    nprintf( '                =  %p', [% scale_time( st / N ) %] );
    nprintf( '    Av. GC time =  %p msecs', [% 10.0 * gt / N %] );
    nprintf( '              =  %p', [% scale_time( gt / N ) %] );
    nprintf( '    Number of iterations %p', [^N] );
enddefine;

define lconstant test( p, min_t, min_n ); lvars procedure p, min_t, min_n;

    lvars ( st, gt ) = p( min_n );
    max( gt, 0 ) -> gt;         ;;; defensive
    max( st - gt, 0 ) -> st;    ;;; eliminate GC time

    if ( st > min_t ) then
        ;;; That's enough tests.
        report( min_n, st, gt );
    elseif st <= 0 then
        ;;; Not easy to estimate tests -- make a big jump.
        test( p, min_t, 100 * min_n );
    else
        ;;; Estimate how many tests we should do.
        lvars n = round( ( min_t + st - 1.0 ) / st );      ;;; round up.
        test( p, min_t, n * min_n );
    endif
enddefine;

define lconstant timing_tests( min_n, p ); lvars procedure p, min_n;
    checkinteger( TIME_min_time, 0, false );
    checkinteger( min_n, 1, false );
    test( p, TIME_min_time, min_n );
enddefine;


define syntax TIME;
    dlocal popnewline = true;

    unless popexecute do
        mishap( 'TIME only works at top-level', [] )
    endunless;

    if pop11_try_nextreaditem( "*" ) then
        lvars n = readitem();
        n
    else
        TIME_min_iterations
    endif.sysPUSHQ;

    ;;; Create a procedure which applies the text N times and
    ;;; reports the time taken.
    sysPROCEDURE( "TIME", 1 );
    lvars n = sysNEW_LVAR();
    sysPOP( n );
    lvars ( st, gt ) = sysrepeat( 2, sysNEW_LVAR );
    sysPUSH( "popgctime" );
    sysPOP( gt );
    sysCALL( "systime" );
    sysPOP( st );
    sysLABEL( "entry" );
    sysPUSH( n ); sysPUSHQ( 0 ); sysCALL( "fi_>" );
    sysIFNOT( "exit" );
    sysPUSH( n ); sysPUSHQ( 1 ); sysCALL( "fi_-" ); sysPOP( n );
    pop11_comp_stmnt_seq_to( newline ).erase;
    ";" :: proglist -> proglist;
    sysPUSHQ( 0 );
    sysCALLQ( setstacklength );
    sysGOTO( "entry" );
    sysLABEL( "exit" );
    sysCALL( "systime" );
    sysPUSH( st );
    sysCALL( "-" );
    sysPUSH( "popgctime" );
    sysPUSH( gt );
    sysCALL( "-" );
    sysENDPROCEDURE().sysPUSHQ;
    sysCALLQ( timing_tests );
enddefine;


endsection;
