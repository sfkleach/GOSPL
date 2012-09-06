;;; -- Virtual Machine ------------------------------------------------------

vars parg;
define plant_error( mess ); lvars mess;
    mishap(
        'SYNTAX CHECK FAILED TO CATCH ILLGAL CONSTRUCT' >< mess,
        [^parg]
    )
enddefine;

;;; -- Initial environment --------------------------------------------------
constant initial_env = newproperty( [], 50, false, true );

;;; -- Context variables

define newdefaultContext();
    false
enddefine;

define nontailcall( cxt ); lvars cxt;
    false
enddefine;

define tailcall( cxt ); lvars cxt;
    true
enddefine;

define tailcallContext( cxt ); lvars cxt;
    cxt
enddefine;

;;; -- Handling contexts

constant isreserved =
    newproperty(
        maplist(
            [
                => and begin case cond define delay do else
                if lambda let let\* letrec or quasiquote
                quote set! unquote unquote\-splicing
            ],
            procedure(x); lvars x;
                [^true ^x]
            endprocedure
        ),
        25,
        false,
        true
    );

recordclass constant SchemeVar
    nameSchemeVar
    plantSchemeVar;

;;; pe = popexecute
define newSchemeVar( w, pe ); lvars w, pe;
    lvars name;
    if w do
        w <> "_SCHEME" -> name;
        if pe do
            sysVARS( name, 0 )
        else
            sysLVARS( name, 0 )
        endif;
    else
        sysNEW_LVAR() -> name;
    endif;
    consSchemeVar( name, false );
enddefine;

;;; Never add any reserved words into the environment
define addvar_*( w, env, pseudo ) -> env -> v;
    lvars w, env, pseudo, v;
    if w.isreserved do
        mishap('Reserved word used as variable', [^w])
    endif;
    newSchemeVar( if pseudo do false else w endif, popexecute ) -> v;
    if popexecute do
        v -> initial_env( w )
    else
        conspair(
            conspair( w, v ),
            env
        ) -> env;
    endif;
enddefine;

vars addvar = addvar_*(% false %);
vars addpseudovar = addvar_*(% true %);

define vars prdeclare_scheme( w ); lvars w;
    appdata(
        ';;; Scheme declaring ',
        cucharout
    );
    pr( w );
    cucharout( `\n` );
    lconstant unspecified = consUnspecified( "pragma\-declare" );    
    unspecified;
enddefine;

define getvar( w, env ); lvars v, env, w;
    while env.ispair do
        lvars v = fast_destpair( env ) -> env;
        if front( v ) == w do return( back( v ) ) endif;
    endwhile;
    if initial_env( w ) ->> v do
        v
    else
        prdeclare_scheme( w ) ->;
        newSchemeVar( w, true ) ->> initial_env( w );
    endif
enddefine;


;;; -- Code planting routines that help

define lconstant bad_nil_as_bool_option();
    mishap(
        'Illegal value for "nil_as_bool_scheme" option',
        [^nil_as_bool_scheme]
    );
enddefine;

define lconstant warn_nil_as_bool();
    warning('NIL used as #f', []);
enddefine;

define lconstant check_against_nil( x ); lvars x;
    if x == nil do
        warn_nil_as_bool();
        false
    else
        true
    endif;
enddefine;

define schemeTESTNOT( lab ); lvars lab;
    dlocal pop_new_lvar_list;             ;;; from version 12 onwards
    if nil_as_bool_scheme == true do
        sysIFNOT( lab )
    else
        lvars v = sysNEW_LVAR();
        sysPUSHS( undef );
        sysPOP( v );
        sysIFNOT( lab );
        sysPUSH( v );
        if nil_as_bool_scheme == false do
            sysPUSHQ( nil );
            sysCALLQ( nonop /== );
        elseif nil_as_bool_scheme == "warn" do
            sysCALLQ( check_against_nil );
        else
            bad_nil_as_bool_option()
        endif;
        sysIFNOT( lab )
    endif;
enddefine;

define schemeAND( lab ); lvars lab;
    dlocal pop_new_lvar_list;             ;;; from version 12 onwards
    if nil_as_bool_scheme == true do
        sysAND( lab )
    else
        lvars v = sysNEW_LVAR();
        sysPUSHS( undef );
        sysPOP( v );
        sysAND( lab );
        sysPUSH( v );
        if nil_as_bool_scheme == false do
            sysPUSHQ( nil );
            sysCALLQ( nonop /== );
        elseif nil_as_bool_scheme == "warn" do
            sysCALLQ( check_against_nil );
        else
            bad_nil_as_bool_option();
        endif;
        sysAND( lab );
    endif;
enddefine;

define schemeOR( lab ); lvars lab;
    dlocal pop_new_lvar_list;             ;;; from version 12 onwards

    define lconstant convert_to_false( x ); lvars x;
        x or x /== nil
    enddefine;

    define lconstant convert_to_false_&_warn( x ); lvars x;
        if x do
            if x == nil do
                warn_nil_as_bool();
                false;
            else
                x
            endif;
        else
            x
        endif
    enddefine;

    if nil_as_bool_scheme == true do
        sysOR( lab )
    else
        if nil_as_bool_scheme == false do
            sysCALLQ( convert_to_false );
        elseif nil_as_bool_scheme == "warn" do
            sysCALLQ( convert_to_false_&_warn );
        else
            bad_nil_as_bool_option();
        endif;
        sysOR( lab );
    endif
enddefine;

constant schemeCALL         = nameSchemeVar <> sysCALL;
constant schemePASSIGN      = nameSchemeVar <> sysPASSIGN;
constant schemePUSH         = nameSchemeVar <> sysPUSH;

define schemePOP( v ); lvars v;
    if plantSchemeVar( v ) do
        mishap( 'Cannot reassign protected identfier at top level', [^v] )
    endif;
    sysPOP( nameSchemeVar( v ) )
enddefine;

define schemeVAR( v ); lvars v;
    lvars n = nameSchemeVar( v );
    sysVARS( n, 0 );
enddefine;
