
;;; -- Planting code --------------------------------------------------------

;;; -- Forward declarations
vars procedure plant_sexp;

;;; -- Table for driving compilation
;;;
;;; Data table for special forms
;;; plant_table : word -> plantForm | false
;;; type plantForm = sexp -> ()

define plant_table( x ); lvars x;
    plantSpecial( special_table ( x ) )
enddefine;

define updaterof plant_table( v, x ); lvars v, x;
    v -> plantSpecial( special_table( x ) )
enddefine;


;;;--  Procedure Calling is trickier than it looks !

define bad_call_mode();
    mishap('Unknown call mode', [^call_mode_scheme])
enddefine;

define is_checked_mode();
    if call_mode_scheme == "proc" or call_mode_scheme == "data" do
        true
    elseif call_mode_scheme == "unchecked" do
        false
    else
        bad_call_mode()
    endif
enddefine;

define oopsproc( x ); lvars x;
    mishap('Trying to apply a non-procedure', [^x])
enddefine;

define convert_to_proc_&_call( n, x ); lvars n, x;
    if isprocedure(x) do
        chain(n, x)
    else
        unless n == pdnargs(x) do  ;;; get nargs off stack
            mishap('Wrong number of args(1st) for object(2nd)', [^n ^x])
        endunless;
        chain(class_apply(x))
    endif
enddefine;

define check_is_proc( x ); lvars x;
    unless isprocedure(x) do oopsproc(x) endunless;
enddefine;

define convert_to_proc( n, x ); lvars n, x;
    if isprocedure(x) do
        n, x
    else
        unless n == pdnargs(x) do  ;;; get nargs off stack
            mishap('Wrong number of args(1st) for object(2nd)', [^n ^x])
        endunless;
        class_apply(x)
    endif
enddefine;

define check_is_proc_&_call( x ); lvars x;
    if isprocedure(x) do chain(x) else oopsproc(x) endif
enddefine;

define plant_tail_call( s, cxt, env ); lvars s, cxt, env;
    plant_sexp( s, nontailcall( cxt ), env );
    if call_mode_scheme == "proc" do
        sysPUSHS( undef );
        sysCALLQ( check_is_proc );
        sysCALLQ( chain );
    elseif call_mode_scheme == "data" do
        sysCALLQ( convert_to_proc );
        sysCALLQ( chain );
    elseif call_mode_scheme == "unchecked" do
        sysCALLQ( chain );
    else
        bad_call_mode()
    endif;
enddefine;

define plant_word_call( w, cxt, env ); lvars w, cxt, env;
    lvars v = getvar( w, env );         ;;; this is computed twice, hmmmmm
    if call_mode_scheme == "proc" do
        schemePUSH( v );
        sysCALLQ( check_is_proc_&_call );
    elseif call_mode_scheme == "data" do
        schemePUSH( v );
        sysCALLQ( convert_to_proc_&_call );
    elseif call_mode_scheme == "unchecked" do
        schemeCALL( v );
    else
        bad_call_mode()
    endif
enddefine;

define plant_sexp_call( s, cxt, env ); lvars s, cxt, env;
    plant_sexp( s, nontailcall( cxt ), env );
    if call_mode_scheme == "proc" do
        sysCALLQ( check_is_proc_&_call );
    elseif call_mode_scheme == "data" do
        sysCALLQ( convert_to_proc_&_call );
    elseif call_mode_scheme == "unchecked" do
        sysCALLS( undef );
    else
        bad_call_mode()
    endif
enddefine;

define plant_call( s, cxt, env ); lvars s, cxt, env;
    if tailcallContext( cxt ) and opt_tail_call_scheme do
        plant_tail_call( s, cxt, env )
    elseif s.isword do
        plant_word_call( s, cxt, env )
    elseif s.islist do
        plant_sexp_call( s, cxt, env )
    else
        plant_error( 'Expression with weird head' )
    endif;
enddefine;

define plant_normal_apply( h, t, cxt, env ); lvars h, t, cxt, env;
    lvars i, ntc_cxt = nontailcall( cxt );
    for i in t do
        plant_sexp( i, ntc_cxt, env )
    endfor;
    sysPUSHQ( length( t ) );
    plant_call( h, cxt, env );
enddefine;

define plant_apply( h, t, cxt, env ); lvars h, t, cxt, env;
    if h.isword do
        lvars v = getvar( h, env );
        lvars p = plantSchemeVar( v );
        if p.isprocedure do             ;;; p can just be TRUE for protection
            p( t, cxt, env )
        else
            plant_normal_apply( h, t, cxt, env )
        endif
    else
        plant_normal_apply( h, t, cxt, env )
    endif
enddefine;

;;; -- Planting Code for a general sexpression

define plant_word( w, cxt, env ); lvars w, cxt, env;
    schemePUSH( getvar( w, env ) )
enddefine;

vars parg;
define plant_sexp( parg, cxt, env ); dlocal parg; lvars cxt, env;
    lvars h, t, p;
    if parg.ispair do
        destpair( parg ) -> t -> h;
        if (plant_table( h ) ->> p) do
            p( t, cxt, env )
        else
            plant_apply( h, t, cxt, env );
        endif;
    elseif parg.isword do
        plant_word( parg, cxt, env );
    else
        sysPUSHQ( parg )
    endif;
enddefine;





;;; -- SPECIAL FORMS TABLE ENTRIES ------------------------------------------

;;; -- forward declarations

vars procedure (plant_lambda_base);

;;; -- Shared procedures


define print_string_scheme( x ); lvars x;
    dlocal cucharout = identfn;
    cons_with consstring {% print_scheme( x ) %}
enddefine;

define plant_and_/_or( t, cxt, env, proc, val );
    lvars t, cxt, env, proc, val;
    lvars len = length(t);
    if len == 0 do
        sysPUSHQ( val );        ;;; true/false
    elseif len == 1 do
        plant_sexp( t(1), cxt, env );   ;;; can be tail recursive !!
    else
        lvars lab = sysNEW_LABEL();
        lvars j, ntc_cxt = nontailcall( cxt );
        for j on t do
            lvars i = hd( j );
            plant_sexp( i, ntc_cxt, env );
            unless j.tl.null do
                proc( lab );        ;;; schemeAND/schemeOR
            endunless;
        endfor;
        sysLABEL( lab );
    endif;
enddefine;

;;; -- and

plant_and_/_or(% schemeAND, true %) -> plant_table( "and" );

;;; -- begin


define plant_body( t, cxt, env ); lvars t, cxt, env;
    lconstant unspecified_begin = consUnspecified( "sequence" );
    lvars i, count = length( t ), ntc_cxt = nontailcall( cxt );
    if count == 0 do
        sysPUSHQ( unspecified_begin );
    else
        for i in t do
            count - 1 -> count;
            lvars last_call = (count == 0);
            plant_sexp( i, if last_call do cxt else ntc_cxt endif, env );
            unless last_call do
                sysERASE( undef );
            endunless;
        endfor;
    endif
enddefine;

plant_body -> plant_table( "begin" );

;;; -- case

lconstant unspecified_case = consUnspecified( "case" );

define plant_case_clauses( t, cxt, env, v, exit );
    lvars t, cxt, env, v, exit;
    lvars datum_list, key;
    if t.ispair do
        destpair( t ) -> t -> datum_list;
        lvars goon = sysNEW_LABEL();
        unless datum_list == "else" do
            sysPUSH( v );
            sysPUSHQ( datum_list );
            sysCALLQ( lmember );
            sysIFNOT( goon );
            plant_body( t, cxt, env );
            sysGOTO( exit );
            sysLABEL( goon );
            plant_case_clauses( t, cxt, env, v, exit );
        else
            if t == nil do
                plant_body( t, cxt, env );
                sysLABEL( exit );
            else
                plant_error( 'ELSE used in non-final CASE clause' )
            endif;
        endunless;
    elseif t == nil do
        sysPUSHQ( unspecified_case );
    else
        plant_error( 'Dotted pair in CASE clause' )
    endif;
enddefine;

define plant_case( t, cxt, env ); lvars t, cxt, env;
    dlocal pop_new_lvar_list;
    lvars key = destpair( t ) -> t;
    lvars ntc_cxt = nontailcall( cxt );
    plant_sexp( key, ntc_cxt, env );
    lvars v = sysNEW_LVAR().dup.sysPOP;
    plant_case_clauses( t, cxt, v, sysNEW_LABEL() );
enddefine;

plant_case -> plant_table( "case" );

;;; -- cond
define lconstant dest_cond( t ) -> testpart -> thenpart -> arrow -> t;
    lvars t, testpart, thenpart, arrow;
    lvars clause = t.destpair -> t;
    clause( 2 ) == "=>" -> arrow;
    if arrow do
        clause.destpair.back
    else
        clause.destpair
    endif -> thenpart -> testpart
enddefine;

define lconstant plant_cond_*( t, cxt, env, exitlab);
    dlocal pop_new_lvar_list;
    lvars t, cxt, env, exitlab;
    lvars testpart, thenpart, arrow, v;
    dest_cond( t ) -> testpart -> thenpart -> arrow -> t;
    if testpart == "else" do
        plant_body( thenpart, cxt, env )
        ;;; Drops through into the right place
    else
        plant_sexp( testpart, nontailcall( cxt ), env );
        lvars lab = sysNEW_LABEL();
        if arrow do
            lvars v = sysNEW_LVAR();
            sysPUSHS( undef );
            sysPOP( v );
            schemeTESTNOT( lab );
            sysPUSH( v );
            sysPUSHQ( 1 );  ;;; do not forget the count!!
            plant_call(
                if listlength( thenpart ) == 1 do hd(thenpart)
                else [begin ^^thenpart]
                endif,
                cxt, env
            );
        else
            schemeTESTNOT( lab );
            plant_body( thenpart, cxt, env );
        endif;
        sysGOTO( exitlab );
        sysLABEL( lab );
        if t.null do
            lconstant unspecified = consUnspecified( "cond" );
            sysPUSHQ( unspecified );
        else
            plant_cond_*( t, cxt, env, exitlab )
        endif;
    endif;
enddefine;

define plant_cond( t, cxt, env ); lvars t, cxt, env;
    lvars l = sysNEW_LABEL();
    plant_cond_*( t, cxt, env, l );
    sysLABEL( l );        
enddefine;

plant_cond -> plant_table( "cond" );


;;; -- define

define dest_define( t ) -> t -> w; lvars t, w;
    lvars w = t.destpair -> t;
    if w.isword do
        front( t ) -> t;
    elseif w.ispair do
        lvars args;
        destpair(w) -> args -> w;
        [ lambda ^args ^^t ] -> t;
    else
        plant_error( 'Weird arg for DEFINE' )
    endif;
enddefine;

define plant_define( t, cxt, env );
    lvars t, cxt = nontailcall( cxt ), env;                
    lvars w = dest_define( t ) -> t;
    lvars v = addvar( w, env ) -> env;
    if t.ispair and hd( t ) == "lambda" do
        schemePASSIGN( plant_lambda_base( back( t ), cxt, env ), v );
    else
        plant_sexp( t, cxt, env );
        schemePOP( v );
    endif;
    lconstant unspecified = consUnspecified( "define" );
    sysPUSHQ( unspecified );
enddefine;
plant_define -> plant_table( "define" );


;;; -- delay

define plant_delay( t, cxt, env ); lvars t, cxt, env;
    sysPROCEDURE( newsrc( "delay" :: t ), 1 );
    plant_sexp( t.front, nontailcall( cxt ) );
    sysENDPROCEDURE().sysPUSHQ;
    sysCALLQ( newPromise );
enddefine;
plant_delay -> plant_table( "delay" );

;;; -- do

define plant_do( t, cxt, env ); lvars t, cxt, env;
    lvars cxt = nontailcall( cxt );
    lvars varlist, testlist, commlist;
    dl( t ) -> commlist -> testlist -> varlist;
    lvars i;
    for i in varlist do
        plant_sexp( i(2), cxt, env )
    endfor;
    sysPROCEDURE( newsrc( "do" :: t ), listlength( varlist ) );                  
    lvars i;
    for i in varlist do
        schemePOP(addvar( i(1), env ) -> env)
    endfor;
    plant_sexp( hd( testlist ), cxt, env );                  
    lvars stop = sysNEW_LABEL();
    schemeTESTNOT( stop );
    for i in commlist do                     
        plant_sexp( i, cxt, env )
    endfor;
    for i in varlist do
        plant_sexp( i(3), cxt, env )
    endfor;
    sysPUSHQ( 0 );
    sysCALLQ( caller );
    sysCALLQ( chain );
    sysLABEL( stop );
    plant_body( tl( testlist ), cxt, env );
    sysENDPROCEDURE().sysCALLQ;
enddefine;

plant_do -> plant_table( "do" );

;;; -- if

lconstant unspecified_if = consUnspecified( "if" );

define lconstant dest_if( t ); lvars t;
    lvars l = length(t);
    if l == 3 do 3.t else unspecified_if endif;
    2.t;
    1.t;
enddefine;

define plant_if( t, cxt, env ); lvars t, cxt, env;
    lvars testpart, thenpart, elsepart;
    dest_if( t ) -> testpart -> thenpart -> elsepart;
    plant_sexp( testpart, nontailcall( cxt ), env );
    lvars notok = sysNEW_LABEL();
    schemeTESTNOT( notok );
    plant_sexp( thenpart, cxt, env );
    lvars exit  = sysNEW_LABEL();
    sysGOTO( exit );
    sysLABEL( notok );
    plant_sexp( elsepart, cxt, env );
    sysLABEL( exit );
enddefine;

plant_if -> plant_table("if" );


;;; -- lambda

define plant_arity_error_check();
    define lconstant procedure arity_error();
        mishap( caller( 1 ).print_string_scheme , 1, 'Arity error')
    enddefine;
    sysIFSO( "ok" );
    sysCALLQ( arity_error );
    sysLABEL( "ok" );
enddefine;

define dest_args( args, cxt )
        -> isdotted -> dotlast -> argscount -> restargs;
    lvars args, cxt, isdotted, dotlast = args, argscount = 0, restargs;
    [% while ispair(dotlast) do
        argscount + 1 -> argscount;
        dotlast.destpair -> dotlast;
    endwhile %] -> restargs;
    lvars isdotted = (dotlast /== nil);
enddefine;


define plant_lambda_base( t, cxt, env ); lvars t, cxt, env;
    lvars args, body;
    destpair(t) -> body -> args;
    lvars len_t = listlength( body );
    lvars isdotted, dotlast, argscount, restargs;
    dest_args( args, cxt ) -> isdotted -> dotlast -> argscount -> restargs;
    lvars arity = argscount + if isdotted do 1 else 0 endif;

    sysPROCEDURE( newsrc( "lambda" ::  t ), arity ),

    if isdotted do
        unless argscount == 0 do
            sysPUSHQ( argscount );
            sysCALLQ( nonop - );
            if is_checked_mode() do
                sysPUSHS( undef );
                sysPUSHQ( 0 );
                sysCALLQ( nonop >= );
                plant_arity_error_check();
            endif
        endunless;
        sysCALLQ( conslist );
        schemePOP( addvar( dotlast, env ) -> env );
    else
        if is_checked_mode() do
            sysPUSHQ( arity );
            sysCALLQ( nonop == );
            plant_arity_error_check();
        else
            sysERASE( undef )
        endif
    endif;
    lvars i;
    for i in restargs.rev do
        schemePOP( addvar( i, env ) -> env )
    endfor;
    plant_body( body, tailcall( cxt ), env );
    sysENDPROCEDURE()
enddefine;

define plant_lambda( t, cxt, env ); lvars t, cxt, env;
    plant_lambda_base( t, cxt, env ).sysPUSHQ
enddefine;

plant_lambda -> plant_table( "lambda");


;;; -- let
define plant_let_base( t, cxt, env );
    lvars t, cxt, env;
    lvars ntc_cxt = nontailcall( cxt );
    lvars pe = popexecute;
    if pe do sysPROCEDURE( "let", 0 ) endif;
    lvars i;
    for i in front( t ) do
        plant_sexp( i(2), ntc_cxt, env )
    endfor;
    lvars i;
    for i in front( t ).rev do
        schemePOP( addpseudovar( i(1), env ) -> env )
    endfor;
    plant_body( back( t ), cxt, env );
    if pe do sysENDPROCEDURE().sysCALLQ endif;
enddefine;

define plant_named_let_base( name, t, cxt, env ); lvars name, t, cxt, env;
    lvars name, t, cxt, env;
    lvars ntc_cxt = nontailcall( cxt );
    lvars i;
    for i in front( t ) do
        plant_sexp( i(2), ntc_cxt, env )
    endfor;
    sysPROCEDURE( name, listlength(front(t))+1 );
    schemePOP( addvar( name, env ) -> env );
    lvars i;
    for i in front( t ).rev do
        schemePOP( addpseudovar( i(1), env ) -> env )
    endfor;
    plant_body( back( t ), cxt, env );
    sysENDPROCEDURE().sysPUSHQ;
    sysPUSHS( undef );      ;;; gets a pointer to itself as last parameter
    sysCALLS( undef );
enddefine;

define plant_let( t, cxt, env ); lvars t, cxt, env;
    dlocal pop_new_lvar_list;
    if front( t ).isword do
        plant_named_let_base( destpair( t ), cxt, env )
    else
        plant_let_base( t, cxt, env )
    endif
enddefine;

plant_let -> plant_table( "let" );

;;; -- let*
define plant_let_*_base( t, cxt, env ); lvars t, cxt, env;
    lvars ntc_cxt = nontailcall( cxt );
    lvars bindings, body;
    destpair( t ) -> body -> bindings;
    lvars pe = popexecute;
    if pe do sysPROCEDURE( "let", 0 ) endif;
    lvars i;
    for i in bindings do
        plant_sexp( i(2), ntc_cxt, env );
        schemePOP( addpseudovar( i(1), env ) -> env );
    endfor;
    plant_body( body, cxt, env );
    if pe do sysENDPROCEDURE().sysCALLQ endif; 
enddefine;

define plant_let_*( t, cxt, env ); lvars t, cxt, env;
    dlocal pop_new_lvar_list;
    if front( t ).isword do
        plant_error( 'Named LET* not allowed' );
    else
        plant_let_*_base( t, cxt, env )
    endif
enddefine;
plant_let_* -> plant_table( "let\*" );

;;; -- letrec
lconstant unspecified_letrec = consUnspecified( "letrec" );

define plant_letrec_base( t, cxt, env );
    lvars i, t, cxt, env;
    lvars body, bindings;
    destpair( t ) -> body -> bindings;
    plant_sexp(
        [let
            [% for i in bindings do [%i(1), unspecified_letrec%] endfor %]
            %
                for i in bindings do
                    [set\! % i(1), i(2) %]
                endfor
            %
            ^^body
        ],
        cxt,
        env
    );
enddefine;

define plant_letrec( t, cxt, env ); lvars t, cxt, env;
    dlocal pop_new_lvar_list;
    if front( t ).isword do
        plant_error( 'Named LETREC not allowed' );
    else
        plant_letrec_base( t, cxt, env );                     
    endif
enddefine;
plant_letrec -> plant_table( "letrec" );


;;; -- null?
;;; -- Deserves its own special form !  (Cancels out previous table entry)
define plant_null( t, cxt, env ); lvars t, cxt, env;
    plant_sexp( front( t ), nontailcall( cxt ), env );
    sysPUSHQ( nil );
    sysCALLQ( nonop == );
enddefine;
plant_null -> plant_table("null\?");


;;; -- or
plant_and_/_or(% schemeOR, false %) -> plant_table( "or" );

;;; -- quasiquote

define quasiquote_conslist( list ) -> list; lvars list;
    repeat
        lvars x = ();
        quitif( x == popstackmark );
        conspair(x, list) -> list;
    endrepeat
enddefine;

define quasiquote_consvector();
    lvars count = 1;
    repeat
        if subscr_stack(count) == popstackmark do
            lvars answer = consvector( count fi_- 1 );
            ->;         ;;; dump popstackmark
            return( answer )
        endif;
        count fi_+ 1 -> count;
    endrepeat;
enddefine;

define cons_for( item ); lvars item;
    if item.islist do
        quasiquote_conslist
    elseif item.isvector do
        quasiquote_consvector
    else
        internal_error();
    endif
enddefine;

define appitem( x, p ); lvars x, p;
    if x.ispair do
        while x.ispair do
            p( destpair(x) -> x )
        endwhile;
        p(x);
    else
        appdata( x, p )
    endif
enddefine;

constant procedure plant_quasiquote_*;

define quasiquote( x, ntc_cxt, env ); lvars x, ntc_cxt, env;
    if x.ispair do
        if hd(x) == "unquote" do
            plant_sexp( x(2), ntc_cxt, env )
        elseif hd(x) == "unquote\-splicing" do
            plant_sexp( x(2), ntc_cxt );
            sysCALLQ( explode );
        else
            plant_quasiquote_*( x, ntc_cxt, env )
        endif;
    else
        plant_quasiquote_*( x, ntc_cxt, env )
    endif
enddefine;

define plant_quasiquote_*( item, cxt, env ); lvars item, cxt, env;
    if item.ispair or item.isvector do
        sysPUSH( "popstackmark" );
        appitem( item, quasiquote(% cxt.nontailcall, env %) );
        sysCALLQ( cons_for( item ) );
    else
        sysPUSHQ( item )
    endif;
enddefine;

define plant_quasiquote( t, cxt, env ); lvars t, cxt, env;
    plant_quasiquote_*( front( t ), cxt, env )
enddefine;

plant_quasiquote -> plant_table( "quasiquote" );


;;; -- quote
define plant_quote( t, cxt, env ); lvars t, cxt, env;
    sysPUSHQ( front( t ) )
enddefine;
plant_quote -> plant_table( "quote" );

;;; -- set!
define plant_set( t, cxt, env ); lvars t, cxt, env;
    lvars w = destpair( t ).front -> t;
    plant_sexp( t, cxt.nontailcall, env );
    schemePOP( getvar( w, env ) );
    lconstant unspecified = consUnspecified( "set\!" );
    sysPUSHQ( unspecified );
enddefine;
plant_set -> plant_table( "set\!" );


;;; -- unquote
internal_error -> plant_table( "unquote" );

;;; -- unquote-splicing
internal_error -> plant_table( "unquote\-splicing" );

;;; -- zero?
;;; -- Deserves its own special form !  (Cancels out previous table entry)
define plant_zero( t, cxt, env ); lvars t, cxt, env;
    plant_sexp( t.front, cxt.nontailcall, env );
    sysPUSHQ( 0 );
    sysCALLQ( nonop == );
enddefine;
plant_zero -> plant_table("zero\?");
