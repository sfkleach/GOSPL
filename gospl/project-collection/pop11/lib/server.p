;;; Summary: A simple server shell.
;;; Version: 1.0

compile_mode :pop11 +strict;

section $-gospl$-server =>
    server              ;;; Hack for uses.  Yuck.
    server_key
    newserver
    isserver
    subscr_server
    start_server
    suspend_server
    stop_server
    take_break
    cusocket
    cugetchar
    cugetline
    cuputchar
    cuputline
    fsend fsendC fsendln fsendlnC
    send sendC sendln sendlnC
    to_consumer
    to_cuputchar
;

vars server = true;     ;;; uses hack.

uses unix_sockets;
uses universal_time;

;;; -- Utilities ----------------------------------------------

define newprop( perm );
    newanyproperty(
        [], 8, 1, false,
        false, false, "perm",
        false, false
    )
enddefine;

define procname( p );
    pdprops( p ) or p.isclosure and procname( p.pdpart )
enddefine;


;;; -- Server Class -------------------------------------------

defclass server {
    server_handler_table,
    server_control_sockets,
    server_response_table,
    server_wait_table,
    server_busy_table,
};

define newserver();
    ;;; From port number to response-handler.
    lvars handler_table = newprop( "tmparg" );

    ;;; From port number to socket.
    lvars control_sockets = newprop( "perm" );

    ;;; From server-socket to internal closures.
    lvars response_table = newprop( "tmparg" );

    ;;; From server-socket to true, false (default) or time (sys_real_time).
    lvars wait_table = newprop( "perm" );

    ;;; From internal closures to true or false (default).
    lvars busy_table = newprop( "perm" );

    consserver( handler_table, control_sockets, response_table, wait_table, busy_table )
enddefine;

define subscr_server( port_num, server );
    server_handler_table( server )( port_num )
enddefine;

define updaterof subscr_server( handler, port_num, server );
    handler -> server_handler_table( server )( port_num )
enddefine;

subscr_server -> server_key.class_apply;


;;; -- Manipulating the Server --------------------------------


;;; Configuration constants.
vars WaitTimeUSecs      = 100;
vars MaxKeepAlive       = 2;
vars KeepAliveTimeout   = 10;

;;; -- dlocals for careful-handlers.

vars procedure ( cuputchar, cugetchar, cugetline, cuputline );
vars cuserver;
vars cusocket;
vars cuprocess;
vars procedure cuprocedure;

synonym cudevget cusocket;
synonym cudevput cusocket;

;;; -- dlocals for invoke_server.

vars cuKeepAliveCount = 0;

define keep_alive_is_available();
    ;;; debug nprintf( 'Used %p, Max %p', [% cuKeepAliveCount, MaxKeepAlive %] );
    cuKeepAliveCount < MaxKeepAlive
enddefine;


;;; -- Utilities for printing to consumers.

define to_cuputchar( procedure p );
    procedure() with_nargs 1;
        dlocal cucharout = cuputchar;
        p()
    endprocedure
enddefine;

define send = pr.to_cuputchar enddefine;

define sendln = npr.to_cuputchar enddefine;

define fsend = printf.to_cuputchar enddefine;

define fsendln = nprintf.to_cuputchar enddefine;

define to_consumer( procedure p );
    procedure( consumer ) with_nargs 2;
        dlocal cucharout = consumer;
        p()
    endprocedure
enddefine;

define sendC = pr.to_consumer enddefine;

define sendlnC = npr.to_consumer enddefine;

define fsendC = printf.to_consumer enddefine;

define fsendlnC = nprintf.to_consumer enddefine;


;;; -- Server tables.

;;; ;;; From server-socket to internal closures.
;;; define response_table = newprop( "tmparg" ) enddefine;

;;; ;;; From server-socket to true/false or time (sys_real_time).
;;; define wait_table = newprop( "perm" ) enddefine;
;;;
;;; ;;; From closures of runproc to boolean.
;;; define busy_table = newprop( "perm" ) enddefine;

;;; From server-socket to name.
define sockprops = newprop( "tmparg" ) enddefine;

;;; -------------------------------------------------------------------------

define init_socket( name, sock, p );
    name -> sockprops( sock );
    p -> server_response_table( cuserver )( sock );
    true -> server_wait_table( cuserver )( sock );
enddefine;

;;; Returns how many keep-alive connections are preserved.
;;; This is written in an arcane style in the interests of
;;; minimising generated garbage.  We use the stack as a
;;; temporary list of dying connections, bounded at the base by
;;; the sentinel value -popstackmark-, and we avoid calling
;;; -sys_real_time- if possible as it generates bignums.
;;;
define prune_keep_alive() -> n;
    0 -> n;             ;;; Prepare count of connections still granted life.
    lvars t = false;    ;;; Don't call sys_real_time yet!
    popstackmark;
    fast_appproperty(
        server_wait_table(cuserver),
        procedure( k, v );
            if v.isintegral then
                unless t do
                    sys_real_time() -> t;   ;;; Only call it once.
                endunless;
                if ( t - v ) > KeepAliveTimeout then
                    k                       ;;; Schedule for closure.
                else
                    ;;; debug nprintf( 'KEEP-ALIVE RUNNING for %p', [% k.sockprops %] );
                    n + 1 -> n;             ;;; Count as living.
                endif
            endif
        endprocedure
    );
    repeat
        lvars it = ();                  ;;; Picks up items from stack.
        quitif( it == popstackmark );   ;;; Is this the sentinel?
        false -> server_wait_table( cuserver )( it );
        ;;; debug nprintf( 'KEEP-ALIVE TIMEOUT for %p', [% it.sockprops %] );
        sysclose( it );
    endrepeat
enddefine;

define keep_alive();
    lvars n = prune_keep_alive();       ;;; Always OK to prune.
    if cusocket.isdevice then
        sysflush( cusocket );
        ;;; Check there aren't too many keep-alive connections.
        ;;; We do not want to clog up with the wretched things.
        if n < MaxKeepAlive then
            sys_real_time() -> server_wait_table(cuserver)( cusocket );
            suspend( 0, cuprocess );
        endif
    endif
enddefine;

define careful_discin( sock );
    lvars procedure d = sock.discin;
    lvars count = 0;
    procedure() with_props careful_repeater;
        while count <= 0 do
            lvars n = sys_input_waiting( sock );
            if n then
                n -> count;
                quitloop
            endif;
            if n == 0 then
                procedure();
                    dlocal cucharout = charout;
                    ;;; debug nprintf( 'SURPRISE: n = 0' );
                endprocedure()
            endif;
            true -> server_wait_table( cuserver )( sock );
            suspend( 0, cuprocess )
        endwhile;
        count - 1 -> count;
        d()
    endprocedure
enddefine;

define carefully( procedure p, comm_sock );

    define syntax LABEL;
        sysLABEL( readitem() )
    enddefine;

    procedure() with_props careful_handler;
        dlocal cusocket = comm_sock;
        dlocal cugetchar = careful_discin( comm_sock );
        dlocal cugetline = incharline( cugetchar );
        dlocal cuputchar = discout( comm_sock );
        dlocal cuputline = discoutline( comm_sock );

        ;;; In the case of an interrupt we want to clean up.
        ;;; This is accomplished by acting as if we have finished
        ;;; processing.
        define dlocal interrupt();
            goto finish;
        enddefine;

        p();
        LABEL finish;

        ;;; debug nprintf( 'CLOSING COMM SOCK %p', [% comm_sock.sockprops %] );
        sysclose( comm_sock );
    endprocedure
enddefine;

define new_request_handler( comm_sock, reqhandler );
    procedure( cuprocess ) with_props request_handler;
        dlocal cuprocess;
        runproc( 0, cuprocess );
    endprocedure(% consproc( 0, carefully( reqhandler, comm_sock ) ) %)
enddefine;

define accept_connection( control_sock, p );
    lvars comm_sock = sys_socket_accept( control_sock, false );
    init_socket( gensym( "comm" ), comm_sock, new_request_handler( comm_sock, p ) );
    true -> server_wait_table( cuserver )( control_sock );
    ;;; debug nprintf( 'Accepted connection from %p', [% sys_socket_peername( comm_sock ) %] );
enddefine;

define take_break();
    lvars be = server_busy_table( cuserver ).length == 0;
    lvars we = server_wait_table( cuserver ).length == 0;
    unless we do
        lvars d = sys_input_waiting( server_wait_table( cuserver ).property_keys_list );
        unless d == false or d = [] do
            true -> server_busy_table( cuserver )( cuprocedure );
            suspend( 0, cuprocess );
            return;
        endunless;
    endunless;
    unless be do
        true -> server_busy_table( cuserver )( cuprocedure );
        suspend( 0, cuprocess );
        return;
    endunless;
enddefine;

define long_call( p );

    define call_it( p );
        p()
    enddefine;

    define alarm();
        if call_it.iscaller then
            true -> server_busy_table( cuserver )( cuprocedure );
            suspend( 0, cuprocess );
        endif
    enddefine;

    1e6 -> sys_timer( alarm );
    call_it( p );
    false -> sys_timer( alarm );
enddefine;

define invoke( cuprocedure );
    dlocal cuprocedure;
    cuprocedure();
enddefine;

define scoreboard();
    nprintf( 'Process %p', [ ^poppid ] );
    lvars sock, _;
    for sock, _ in_property server_wait_table( cuserver ) do
        nprintf( 'WAIT %p -> %p', [% sockprops( sock ), procname( server_response_table( cuserver )( sock ) ) %] );
        if sock.isclosed then
            nprintf( 'CLOSED: %p', [% sockprops( sock ) %] )
        endif
    endfor;
    for sock, _ in_property server_busy_table( cuserver ) do
        nprintf( 'BUSY %p', [% procname( sock ) %] );
    endfor;
    nl( 1 );
enddefine;

define main_server_loop();
    lconstant usec_per_minute = seconds_per_minute * 1e6;
    dlocal cuKeepAliveCount;
    repeat
        prune_keep_alive() -> cuKeepAliveCount;
        lvars be = server_busy_table(cuserver).length == 0;
        lvars we = server_wait_table(cuserver).length == 0;

        ;;; debug scoreboard();

        lvars ( ready, _, _ ) =
            if be then
                if we then
                    return
                elseif cuKeepAliveCount == 0 then
                    sys_device_wait( server_wait_table(cuserver).property_keys_list, [], [], 5e6 )
                else
                    ;;; Add a little bit to the time-out.  We want to avoid
                    ;;; racing so we kill off the keep-alives first time.
                    sys_device_wait( server_wait_table(cuserver).property_keys_list, [], [], KeepAliveTimeout * 11e5 )
                endif;
            elseif we then
                false, false, false
            else
                sys_device_wait( server_wait_table(cuserver).property_keys_list, [], [], false )
            endif;

        if ready == false or ready == [] then
            unless be do
                lvars action = server_busy_table(cuserver).property_keys_n.oneof_n;
                false -> server_busy_table(cuserver)( action );
                invoke( action )
            endunless
        else
            if ready.islist then
                ready.destlist.oneof_n -> ready
            endif;
            false -> server_wait_table(cuserver)( ready );
            invoke( server_response_table(cuserver)( ready ) )
        endif
    endrepeat
enddefine;

constant procedure suspend_server;

define open_ports();
    fast_appproperty(
        cuserver.server_handler_table,
        procedure( port_num, handler );
            lvars control_sock = sys_socket( `i`, `S`, false );
            control_sock -> server_control_sockets( cuserver )( port_num );
            init_socket( "ctrl", control_sock, accept_connection(% control_sock, handler %) );
            [ * ^port_num ] -> sys_socket_name( control_sock, 5 );
            ;;; debug nprintf( 'Opening port %p',  [ ^port_num ] )
        endprocedure
    );
enddefine;

define close_ports();
    fast_appproperty(
        server_control_sockets( cuserver ),
        procedure( port_num, control_sock );
            nprintf( 'CLOSING %p', [% control_sock.sockprops %] );
            sysclose( control_sock );
        endprocedure
    );
    clearproperty( server_control_sockets( server ) )
enddefine;

constant procedure stop_server;

define start_server( cuserver );
    dlocal cuserver;

    ;;; Ensure tidy-up code gets run.
    define dlocal interrupt();
        stop_server()
    enddefine;

    open_ports();
    main_server_loop();
    close_ports();
enddefine;

define suspend_server();
    exitfrom( start_server )
enddefine;

define stop_server();
    exitto( start_server )
enddefine;


endsection;
