;;; -- Scheme subsystem -----------------------------------------------------
;;;
;;; Author  Steve Knight
;;; Date    Tue Nov 18, 1986
;;; Version 0
vars version_scheme = 'Scheme Version 0';
;;; Aim     To implement scheme as an intrinsic Poplog language
;;;
;;; LEXIS:
;;;     Suppose the lexis sorts out the renaming problem by suffixing a
;;;     distinguishing mark.  This enables the normal codeplanting routines
;;;     to be used with impunity.
;;;
;;; Naming convention:
;;;     All exported variables from the Scheme subsystem are to be
;;;     suffixed with _scheme.  Suffix rather than prefix for the short
;;;     filenames permitted by UNIX V.
;;;
;;; -------------------------------------------------------------------------



;;; -- Scheme Types ---------------------------------------------------------


;;; -- Promises

recordclass constant Promise contPromise;

define constant procedure newPromise( proc ) -> result; lvars proc, result;
    consPromise(
        procedure( proc ) -> r;
            lvars procedure proc, r = proc();
            identfn(% r %) -> contPromise( result )
        endprocedure(% proc %)
    ) -> result;
enddefine;


;;; -- Unspecified values

recordclass constant Unspecified conUnspecified;


;;; -- Ports

recordclass constant InputPort
    deviceInputPort
    charInputPort;

define newInputPort( x ); lvars x;
    if x.isdevice do
        consInputPort( x, x.discin.newPushable )
    elseif x.isprocedure do
        consInputPort(
            if x.isclosure and frozval( 1, x ).isdevice do
                frozval( 1, x )
            else
                false
            endif,
            x.newPushable
        )
    elseif x.isstring do
        newInputPort( sysopen( x, 0, false ) );
    else
        mishap( 'Cannot create port', [^x] )
    endif
enddefine;

recordclass constant OutputPort
    deviceOutputPort
    charOutputPort;

define constant newOutputPort( x ); lvars x;
    if x.isdevice do
        consOutputPort( x, discout( x ) )
    elseif x.isprocedure do
        consOutputPort(
            if x.isclosure and frozval( 1, x ).isdevice do
                frozval( 1, x )
            else
                false
            endif,
            x
        )
    elseif x.isstring do
        newOutputPort( sysopen( x, 1, false ) );
    else
        mishap( 'Cannot create port', [^x] )
    endif
enddefine;

define constant withinInputPort( proc, port ); lvars proc, port;
    dlocal cucharin = charInputPort( port );
    proc();
enddefine;

define constant withinOutputPort( proc, port ); lvars proc, port;
    dlocal cucharout = charOutputPort( port );
    proc();
enddefine;

define constant closeInputPort( port ); lvars port, d;
    if (deviceInputPort( port ) ->> d).isdevice do
        sysclose( d )
    else
        warning( 'Not a true device', [^port] )
    endif;
enddefine;

define constant closeOutputPort( port ); lvars port, d;
    if (deviceOutputPort( port ) ->> d).isdevice do
        sysclose( d )
    else
        warning( 'Not a true device', [^port] )
    endif;
enddefine;

define readyInputPort( port ); lvars port, d;
    unless charInputPort( port ).emptyPushable do
        true
    elseif systrmdev( deviceInputPort( port ) ->> d ) do
        sys_inputon_terminal( d )
    else
        true
    endunless;
enddefine;

;;; -- Top level loop -------------------------------------------------------
;;; This is the scheme compiler.  Given a character repeater it does its
;;; duty & executes the incoming stream.

constant iscommand = newproperty( [], 10, false, true );

define constant summon_ved( proc ); lvars proc;
    define lconstant read_line(); lvars c;
        cons_with consstring {%
            while (cucharin() ->> c).is_white_space do endwhile;
            c;
            until (cucharin() ->> c) == `\n` do
                c
            enduntil;
        %}
    enddefine;
    dlocal vedargument = read_line();
    while proc.isword do
        valof( proc ) -> proc
    endwhile;
    proc();
enddefine;

summon_ved(% "ved_ved" %)       -> iscommand( "ved" );
summon_ved(% "ved_help" %)      -> iscommand( "help" );
summon_ved(% "ved_showlib" %)   -> iscommand( "showlib" );
summon_ved(% "ved_teach" %)     -> iscommand( "teach" );
summon_ved(% "ved_ref" %)       -> iscommand( "ref" );

procedure;
    "pop11" -> subsystem;
    switch_subsystem_to( "pop11 ");
endprocedure -> iscommand( "pop11" );

procedure;
    dlocal vedargument = '';
    ved_im();
endprocedure -> iscommand( "im" );

define get_sexp() -> s; lvars s, c;
    while ((read_scheme() ->> s).iscommand ->> c) do
        c()
    endwhile;
enddefine;

define toplevel_print( x ); lvars x;
    unless x.isUnspecified do
        appdata( '>=> ', cucharout);
        print_scheme( x );
        cucharout( `\n` );
    endunless;
enddefine;

define print_time_stats(t1, t2, t3, gc1, gc2, gc3);
    lvars t1, t2, t3, gc1, gc2, gc3;
    lvars gc_comp       = gc2 - gc1;
    lvars gc_print      = gc3 - gc2;
    lvars t_subtotal    = t2 - t1;
    lvars t_comp        = t2 - t1 - gc_comp;
    lvars t_print       = t3 - t2;
    lvars t_total       = t3 - t1;
    printf('Time for GC     = %p secs\n', [% gc_comp/100.0 %]);
    printf('Time to compute = %p secs\n', [% t_comp/100.0 %]);
    printf('Sub total       = %p secs\n', [% t_subtotal/100.0 %]);
    printf('Print time      = %p secs\n', [% t_print/100.0 %]);
    printf('Total time      = %p secs\n', [% t_total/100.0 %]);
enddefine;

vars default_input_port, default_output_port;
define read_eval_print( default_input_port, default_output_port );
    dlocal default_input_port, default_output_port;
    dlocal cucharin = charInputPort( default_input_port );
    dlocal cucharout = charOutputPort( default_output_port );                  
    repeat
        lvars s = get_sexp();
        quitif( s == termin );
        lvars t1 = systime();
        lvars gc1 = popgctime;
        lvars result = s.eval_scheme;
        lvars t2 = systime();
        lvars gc2 = popgctime;
        result.toplevel_print;
        lvars t3 = systime();
        lvars gc3 = popgctime;
        if time_stats_scheme do
            print_time_stats( t1, t2, t3, gc1, gc2, gc3 );
        endif;
    endrepeat;
enddefine;

define compile_scheme( cucharin ); lvars cucharin;
    dlocal popprompt = prompt_scheme;
    dlocal popradians = true;
    consproc(
        newInputPort( cucharin ),
        newOutputPort( cucharout ),
        2,
        read_eval_print
    )( 0 )
enddefine;
