
;;; -- BUILTINS -------------------------------------------------------------

define lconstant plantfoldop( t, cxt, env, op );
    lvars t, cxt, env, procedure op;
    lvars ntc_cxt = nontailcall( cxt );
    plant_sexp( dest(t) -> t, ntc_cxt, env );
    lvars i;
    for i in t do
        plant_sexp( i, ntc_cxt, env );
        sysCALLQ( op );
    endfor;
enddefine;

define lconstant folding1( n, op, id ); lvars n, procedure op, id;
    if n == 2 do op()
    elseif n > 2 do repeat n-1 times op() endrepeat
    elseif n == 1 do ;;; nothing
    elseif n == 0 do id
    else internal_error()
    endif
enddefine;

define plantfold1( t, cxt, env, op, id );
    lvars t, cxt, env, procedure op, id;
    if null( t ) do
        sysPUSHQ( id )
    else
        plantfoldop( t, cxt, env, op )
    endif;
enddefine;

define lconstant folding2( n, op, id ); lvars n, procedure op, id;
    if n == 2 do
        op()
    elseif n > 2 do
        repeat n-1 times op() endrepeat
    elseif n == 1 do
        lvars n = ();       ;;; reuse register
        op( id, n );
    elseif n == 0 do
        mishap( 'Operation not defined on 0 args', [^op] )
    else
        internal_error()      
    endif
enddefine;

define plantfold2( t, cxt, env, op, id ); 
    lvars t, cxt, env;
    lvars procedure op, id;
    if null( t ) do
        plant_error( 'Not defined for 0 args: '><op)
    elseif t.listlength == 1 do
        sysPUSHQ( id );
        plant_sexp( t(1), nontailcall( cxt ), env );
        sysCALLQ( op );
    else
        plantfoldop( t, cxt, env, op )
    endif;
enddefine;

;;; -- Defining builtins

define lconstant addbuiltin( name, free, inline ); lvars name, free, inline;
    unless pdprops( free ) do
        name -> pdprops( free )
    endunless;
    procedure;
        lvars v = addvar( name, nil ) ->;
        sysPUSHQ( free );
        schemePOP( v );
        sysEXECUTE();
        inline -> plantSchemeVar( v );
    endprocedure.sysCOMPILE;
enddefine;

define lconstant builtin( name, proc, warp, plant );
    lvars name, proc, warp, plant;
    addbuiltin( name, warp( proc ), plant(% proc %) )
enddefine;


;;; -- variadics

define lconstant warp_variadic( p ) -> result; lvars p, result;
    procedure(n, p); lvars n, p;
        if n == 2 do p()
        elseif n == 1 do ;;; nothing
        elseif n == 0 do
            mishap('Cannot apply variadic procedure to 0 args', [])
        else
            lvars l = conslist(n - 1);
            lvars total = ();
            lvars i;
            fast_for i in l do
                p( total, i ) -> total
            endfor;
            total
        endif;
    endprocedure(% p %) -> result;
    pdprops( p ) -> pdprops( result );
enddefine;

define lconstant plant_variadic( t, cxt, env, proc ); lvars t, cxt, env, proc;
    if t.null do plant_error( 'Cannot apply dyadic to 0 args' ) endif;
    plantfoldop( t, cxt, env, proc );
enddefine;

lconstant variadic = builtin(% warp_variadic, plant_variadic %);

;;; -- N-adic

define lconstant warp_n_adic( p, arity ) -> result; lvars p, result, arity;
    if is_checked_mode() do
        procedure(n, p, arity); lvars n, p, arity;
            if n == arity do p()
            else
                lvars args = conslist(n);
                mishap(
                    'Trying to apply monadic operator to wrong number of args',
                    args
                )
            endif
        endprocedure(% p, arity %) -> result;
        pdprops( p ) -> pdprops( result );
    else
        erase <> p -> result
    endif;
enddefine;

define lconstant plant_n_adic( t, cxt, env, proc, arity );
    lvars t, cxt, env, proc, arity;
    unless t.length == arity do
        plant_error('Trying to apply operator to wrong number of args');
    endunless;
    lvars i, ntc_cxt = nontailcall( cxt );
    for i in t do
        plant_sexp( i, ntc_cxt, env )
    endfor;
    sysCALLQ( proc );
enddefine;

lconstant monadic    = builtin(% warp_n_adic(%1%), plant_n_adic(%1%) %);
lconstant dyadic     = builtin(% warp_n_adic(%2%), plant_n_adic(%2%) %);

;;; -- variables

define lconstant variable( name, value ); lvars name, value;
    procedure;
        lvars v = addvar( name, nil ) -> ;
        sysPUSHQ( value );
        schemePOP( v );
        sysEXECUTE();
    endprocedure.sysCOMPILE
enddefine;

;;; -- monotonic

define lconstant warp_monotonic( p ) -> result; lvars p, result;
    procedure( n, p ); lvars n, p;
        if n == 2 do
            p()
        elseif n < 2 do
            mishap( 'Insufficient arguments for comparision procedure', [^p])
        else
            lvars i;
            fast_for i from n by -1 to 1 do
                lvars x;
                -> x; dup();        ;;; Dirty stack stuff !!!
                unless p( x ) do
                    erasenum( i );
                    return( false );
                endunless;
            endfor;
            true;
        endif;
    endprocedure(% p %) -> result;
    pdprops( p ) -> pdprops( result );
enddefine;

define lconstant plant_monotonic( t, cxt, env, proc );
    lvars t, cxt, env, proc;                    
    dlocal pop_new_lvar_list;
    dlvars v = false;
    ;;; I am feeling mean!  Allocate 1 & only 1 & then only if necesary
    define lconstant the_v();
        if v do v else sysNEW_LVAR() ->> v endif
    enddefine;

    lvars len = listlength( t );
    lvars ntc_cxt = nontailcall( cxt );
    if len < 2 do
        plant_error( 'Comparisons need at least 2 args' );
    else
        plant_sexp( t.destpair -> t, ntc_cxt, env );
        lvars i, exit = sysNEW_LABEL();
        lvars count = len - 1;  ;;; because t is 1 shorter
        for i in t  do
            count - 1 -> count;
            lvars last_element = (count == 0);
            if last_element do
                plant_sexp( i, ntc_cxt, env );
                sysCALLQ( proc );
            elseif i.isword do
                plant_word( i, ntc_cxt, env );
                sysCALLQ( proc );
                sysAND( exit );
                plant_word( i, ntc_cxt, env );
            else
                plant_sexp( i, ntc_cxt, env );
                sysPUSHS( undef );
                sysPOP( the_v() );
                sysCALLQ( proc );
                sysAND( exit );
                sysPUSH( the_v() );
            endif;
        endfor;
        sysLABEL( exit );
    endif;
enddefine;

lconstant monotonic = builtin(% warp_monotonic, plant_monotonic %);


;;; -- define some syntax words

define lconstant definer_scheme( p ); lvars p;
    lvars w = readitem();
    sysPUSHQ( w );
    sysxcomp();
    sysCALLQ( p );
enddefine;

vars syntax define_monadic      = definer_scheme(% monadic %);
vars syntax define_dyadic       = definer_scheme(% dyadic %);
vars syntax define_variadic     = definer_scheme(% variadic %);
vars syntax define_variable     = definer_scheme(% variable %);
vars syntax define_monotonic    = definer_scheme(% monotonic %);

;;; -- defining procedures


;;; --?
define_monotonic <  nonop <;

define_monotonic <= nonop <=;

define_monotonic >  nonop >;

define_monotonic >= nonop >=;

define_monotonic =  nonop =;

addbuiltin( "+", folding1(% nonop +, 1 %), plantfold1(% nonop +, 1 %) );

addbuiltin( "*", folding1(% nonop *, 1 %), plantfold1(% nonop *, 1 %) );

addbuiltin( "-", folding2(% nonop -, 1 %), plantfold2(% nonop -, 1 %) );

addbuiltin( "/", folding2(% nonop /, 1 %), plantfold2(% nonop /, 1 %) );


;;; --A

define_monadic abs abs;

define_monadic acos arccos;

define_monadic angle phase;

define_variadic append  nonop <>;

;;; Well, this is very simple (note DESTLIST puts a number on top of
;;; stack) but the generalisation for n > 2 may take some swallowing.
;;; It is right, though.
define_variable apply
    procedure( n ); lvars n;
        if n == 2 do
            swop();
            lvars procedure p = ();
            p( destlist() )
        elseif n > 2 do
            lvars procedure p = subscr_stack( n );
            p( destlist() + n - 2 );    ;;; get the number JUST SO !
            swop(); erase();
        else
            mishap('Too few args for APPLY', [])
        endif;
    endprocedure;

define_monadic asin arcsin;

lvars assq = lookup(% nonop == %);
define_dyadic assq assq;
define_dyadic assv assq;
define_dyadic assoc lookup(% nonop = %);

;;; version 12 onwards
define_variable atan
    procedure( n ); lvars n;
        if n == 1 do arctan()
        elseif n == 2 do swop(); arctan2()
        else mishap('Wrong number of args for ATAN', [^n])
        endif
    endprocedure;

;;; --B
define_monadic boolean\? isboolean;

;;; --C

define_monadic call_with_current_continuation call_/_cc;

define_dyadic call\-with\-input\-file
    procedure( str, proc );
        lconstant unspecified =
            consUnspecified( "call\-with\-input\-file" );
        lvars str, proc;
        lvars port;
        proc( newInputPort( str ) ->> port );
        closeInputPort( port );
        unspecified;
    endprocedure;

define_dyadic call\-with\-output\-file
    procedure( str, proc );
        lconstant unspecified =
            consUnspecified( "call\-with\-output\-file" );
        lvars str, proc;
        lvars port;
        proc( newOutputPort( str ) ->> port );
        closeOutputPort( port );
        unspecified;
    endprocedure;

define_monadic call\/cc call_/_cc;

define_monadic ceiling
    procedure( x ); lvars x;
        if x.isintegral do
            x
        elseif x < 0 do
            intof( x )
        else
            intof( x ) + 1
        endif;
    endprocedure;

define_monadic char\?
    procedure( c ); lvars c;
        c.isinteger and 0 < c and c < 128
    endprocedure;

define_dyadic char\=\? nonop ==;
define_dyadic char\<\? nonop <;
define_dyadic char\<\=\? nonop <=;
define_dyadic char\>\? nonop >;
define_dyadic char\>\=\? nonop >=;
define_dyadic char\-ci\=\?  downcase <> nonop ==;
define_dyadic char\-ci\<\?  downcase <> nonop <;
define_dyadic char\-ci\<\=\? downcase <> nonop <=;
define_dyadic char\-ci\>\?  downcase <> nonop >;
define_dyadic char\-ci\>\=\? downcase <> nonop >=;

define_variable char\ready\?
    procedure( n ); lvars n;
        lvars port;
        if n == 1 do
            default_input_port -> port
        elseif n == 2 do
            -> port
        else
            checkargs( n, 2, 'CHAR-READY' );
        endif;
        port.readyInputPort;
    endprocedure;

define_monadic char\-upper\-case isuppercode;
define_monadic char\-lower\-case islowercode;
define_monadic char\-alphabetic\? isalphacode;
define_monadic char\-numeric\? isnumbercode;
define_monadic char\-whitespace\?
    procedure( c ); lvars c;
        item_chartype( c ) == 6
    endprocedure;

define_monadic char\-downcase uppertolower;
define_monadic char\-upcase   lowertoupper;

define_monadic char\-\>integer identfn;
define_monadic integer\-\>char identfn;

define_monadic close\-input\-port closeInputPort;

define_monadic close\-output\-port closeOutputPort;

define_monadic complex\? iscomplex;

define_dyadic cons conspair;

define_monadic cos  cos;

define_variable current\-input\-port
    procedure() with_nargs 1;
        checkargs( 0, 'CURRENT-INPUT-PORT' );
        default_input_port
    endprocedure;

define_variable current\-output\-port
    procedure() with_nargs 1;
        checkargs( 0, 'CURRENT-OUTPUT-PORT' );
        default_output_port
    endprocedure;

;;; -- cXXXr
procedure;
    define lconstant 3 x &_then y; lvars x, y;
        if x == identfn do y
        elseif y == identfn do x
        else x <> y
        endif;
    enddefine;

    define lvars cNr( n, chars, proc ); lvars n, chars, proc;
        if n == 0 do
            monadic( cons_with consword { `c` ^^chars `r` }, proc )
        else
            cNr( n-1, `a` :: chars, proc &_then front );
            cNr( n-1, `d` :: chars, proc &_then back );
        endif;
    enddefine;

    lvars i;
    for i from 1 to 4 do
        cNr( i, nil, identfn )
    endfor;
endprocedure();

;;; --D
;;; version 12 onwards
define_monadic denominator denominator;

define_variable display
    procedure( n ); lvars n;
        lconstant unspecified = consUnspecified( "display" );
        if n == 1 do
            display_scheme()
        elseif n == 2 do
            lvars port = ();
            withinOutputPort( display_scheme, port )
        else
            checkargs( n, 1, 'WRITE' )
        endif;
        unspecified;
    endprocedure;

;;; --E
define_monadic eof\-object nonop ==(% termin %);

define_monadic even\? iseven;

define_monotonic eq\? nonop ==;

define_monotonic equal\? nonop =;

define_monotonic eqv\? nonop ==;

define_monadic exact\? isexact;

define_monadic exact\-\>inexact exact_into_inexact;

define_monadic exp exp;

define_monadic expt nonop **;

;;; --F

define_variable f false;

define_monadic floor
    procedure( x ); lvars x;
        if x.isintegral do
            x
        elseif x < 0 do
            intof( x ) - 1
        else
            intof( x )
        endif;
    endprocedure;


lconstant unspecified_foreach = consUnspecified( "foreach" );

define_variable foreach
    procedure( x ); lvars x, y;
        if x == 2 do
            lvars v = single_app_for_scheme( erase );
            unless v == nil do
                mishap('FOREACH applied to a single improper list', [^v])
            endunless;
            unspecified_foreach;
        elseif x > 2 do
            lvars y = ();
            consvector( x - 1 ) -> x;
            unless multi_app_for_scheme( x, y, erase ) == nil do
                mishap('MULTI-FOREACH found an improper list as an argument', [^x])
            endunless;
            unspecified_foreach;
        else
            mishap('Too few args for FOREACH', [^x])
        endif
    endprocedure;

define_monadic force contPromise <> apply;

;;; --G
;;; version 12 onwards
define_variable gcd gcd_n;

;;; --H
;;; --I

define_monadic imag\-part imagpart;

define_monadic inexact\? isexact<>not;

define_monadic inexact\-\>exact inexact_into_exact;

define_monadic input\-port\? isInputPort;

define_monadic integer\? isintegral;

;;; --J
;;; --K
;;; --L
define_monadic last\-pair
    procedure( l );
        lvars l, prev = l;
        while ispair( l )  do
            fast_back( l ->> prev ) -> l;
        endwhile;
    endprocedure;

;;; version 12 onwards
define_variable lcm lcm_n;

define_monadic length listlength;

define_variable list conslist;

define_dyadic list\-ref
    procedure(l, n); lvars l, n;
        unless n.isinteger do
            mishap('Index too big to subscript a list', [^n])
        endunless;
        until n fi_<= 0 do
            back(l) -> l;
            n fi_- 1 -> n;
        enduntil;
        front(l);
    endprocedure;

define_dyadic list\-tail  swop <> allbutfirst;

define_monadic list\-\>string destlist<>consstring;

define_monadic list\-\>vector destlist<>consvector;

define_monadic load
    procedure( f ); lvars f;
        lconstant unspecified_load = consUnspecified( "load" );
        f.discin.compile_scheme;
        unspecified_load;
    endprocedure;

define_monadic log log;

;;; --M
define_monadic magnitude abs;

define_dyadic make\-polar
    procedure( x, y ); lvars x, y;
        x * exp( unary_+:( y ) )
    endprocedure;

define_dyadic make\-rectangular nonop +: ;

define_variable make\-string
    procedure( n ); lvars n;
        if n == 1 do inits()
        elseif n == 2 do
            lvars ch = ();
            lvars s = inits();
            set_bytes( ch, 1, s, datalength( s ) );
        else
            mishap(
                conslist( n ),
                1,
                'Wrong number of args for MAKE-STRING'
            )
        endif;
    endprocedure;

define_variable make\-vector
    procedure( n );
        lvars i, n;
        if n == 1 do initv()
        elseif n == 2 do
            lvars x = ();
            lvars v = initv();
            lvars i;
            fast_for i from 1 to datalength( v ) do
                x -> fast_subscrv( i, v )
            endfor;
            v;
        else
            mishap(
                conslist( n ),
                1,
                'Wrong number of args for MAKE-VECTOR'
            )
        endif;
    endprocedure;

define_variable map             ;;; Inefficient & messy
    procedure( x ); lvars x, y;
        if x == 2 do
            -> y -> x;
            [% single_app_for_scheme( x, y, identfn ) -> y %] -> x;
            unless y == nil do
                mishap('MAP applied to a single improper list', [^y])
            endunless;
            x;
        elseif x > 2 do
            lvars y = ();
            consvector( x - 1 ) -> x;
            [% multi_app_for_scheme( x, y, identfn ) -> y %] -> x;
            unless y == nil do
                mishap('MULTI-MAP found an improper list as an argument', [^x])
            endunless;
            x;
        else
            mishap('Too few args for MAP', [^x])
        endif
    endprocedure;

define_variadic max max;

define_dyadic memq lmember;

define_dyadic memv lmember; ;;; VERY DUBIOUS

define_dyadic member member;

define_variadic min min;

define_dyadic modulo nonop mod;

;;; --N
define_monadic negative\? negate;

define_variable newline
    procedure( n ); lvars n;
        lconstant unspecified = consUnspecified( "newline" );
        if n == 0 do
            cucharout( `\n` )
        elseif n == 1 do
            charOutputPort( )( `\n` )
        else
            checkargs( n, 1, 'NEWLINE' )
        endif;
        unspecified;
    endprocedure;

define_variable nil nil;

define_monadic not
    procedure(x); lvars x;
        if x == nil do
            unless nil_as_bool_scheme do true
            elseif nil_as_bool_scheme == true do false
            elseif nil_as_bool_scheme == "warn" do
                warning( 'NIL used inside NOT', [] );
                false
            else
                internal_error()
            endunless
        elseif x do false
        else true
        endif
    endprocedure;

define_monadic null\? nonop ==(% nil %);

define_monadic number\? isnumber;

define_dyadic number\-\>string number_into_string;

;;; version 12 onwards
define_monadic numerator   numerator;

;;; --O
define_monadic odd\? isodd;

define_monadic open\-input\-file newInputPort;

define_monadic open\-output\-file newOutputPort;

define_monadic output\-port\? isOutputPort;

;;; --P
define_monadic pair\? ispair;

define_monadic positive\? nonop >(%0%);

define_variable pragma\-call\-mode
    procedure;
        checkargs( 0, 'PRAGMA-CALL-MODE' );
        call_mode_scheme
    endprocedure;

define_monadic pragma\-call\-mode\!
    procedure( x ); lvars x;
        if x == "proc" or x == "data" or x == "unchecked" do
            x -> call_mode_scheme
        else
            mishap( 'Not one of \'proc, \'warn or \'unchecked', [^x] )
        endif;
        lconstant unspecified = consUnspecified( "pragma\-call\-mode\!" );
        unspecified;
    endprocedure;

define_variable pragma\-cs
    procedure;
        checkargs( 0, 'PRAGMA-CS' );
        case_sensitivity_scheme
    endprocedure;

define_monadic pragma\-cs\!
    procedure( x ); lvars x;
        if x == "upper\-case" or x == "lower\-case" or x == false do
            x
        else
            mishap( 'Not one of \'lower-case \'upper-case or #f', [^x] )
        endif -> case_sensitivity_scheme;
        lconstant unspecified = consUnspecified( "pragma\-cs\!" );
        unspecified;
    endprocedure;

define_variable pragma\-declare
    procedure;
        checkargs( 0, 'PRAGMA-DECLARE' );
        prdeclare_scheme;
    endprocedure;

define_monadic pragma\-declare\!
    procedure( x ); lvars x;
        x -> prdeclare_scheme;                    
        lconstant unspecified = consUnspecified( "pragma\-declare\!" );
        unspecified;
    endprocedure;

define_variable pragma\-nil\-as\-bool
    procedure;
        checkargs( 0, 'PRAGMA-NIL-AS-BOOL' );
        nil_as_bool_scheme
    endprocedure;

define_monadic pragma\-nil\-as\-bool\!
    procedure( x ); lvars x;
        if x.isboolean or x == "warn" do
            x -> nil_as_bool_scheme
        else
            mishap( 'Not a boolean or (quote warn)', [^x] )
        endif;
        lconstant unspecified = consUnspecified( "pragma\-nil\-as\-bool\!" );
        unspecified;
    endprocedure;

define_variable pragma\-opt\-tail\-call
    procedure;
        checkargs( 0, 'PRAGMA-SOURCE' );
        opt_tail_call_scheme
    endprocedure;

define_monadic pragma\-opt\-tail\-call\!
    procedure( x ); lvars x;
        if x.isboolean do
            x -> opt_tail_call_scheme
        else
            mishap( 'Boolean needed', [^x] )
        endif;
        lconstant unspecified = consUnspecified( "pragma\-opt\-tail\-call\!" );
        unspecified;
    endprocedure;

define_monadic pragma\-protected
    procedure( w ); lvars w;
        if initial_env( w ).plantSchemeVar do true else false endif
    endprocedure;

define_dyadic pragma\-protected\!
    procedure( w, x ); lvars w, x;
        if x.isboolean do
            true -> plantSchemeVar( initial_env( w ) );
        else
            mishap( 'Boolean needed', [^x] )
        endif;
        lconstant unspecified = consUnspecified( "pragma\-protected\!" );
        unspecified;
    endprocedure;

define_variable pragma\-source
    procedure;
        checkargs( 0, 'PRAGMA-SOURCE' );
        src_scheme;
    endprocedure;

define_monadic pragma\-source\!
    procedure( x ); lvars x;
        if x.isboolean do
            x -> src_scheme
        else
            mishap( 'Boolean needed', [^x] )
        endif;
        lconstant unspecified = consUnspecified( "pragma\-source\!" );
        unspecified;
    endprocedure;

define_variable pragma\-time\-loop
    procedure;
        checkargs( 0, 'TIME-LOOP' );
        time_stats_scheme
    endprocedure;

define_monadic pragma\-time\-loop\!
    procedure( x ); lvars x;
        if x.isboolean do
            x -> time_stats_scheme
        else
            mishap( 'Boolean needed', [^x] )
        endif;
        lconstant unspecified = consUnspecified( "pragma\-time\-loop\!" );
        unspecified;
    endprocedure;

define_monadic procedure\? isprocedure;

;;; --Q
define_dyadic quotient nonop div;


;;; --R
define_monadic rational\? isrational;

define_variable rationalize
    procedure( n ); lvars n;
        if n == 1 do
            number_coerce( 0 )
        elseif n == 2 do
            lvars y = abs(), x = number_coerce( 0 );
            lvars i;
            for i in contfraction( x ) do
                if abs(x - i) <= y do
                    return( i )
                endif
            endfor;
            x;
        else
            checkargs( n, 1, 'RATIONALISE' )
        endif
    endprocedure;

define_variable read
    procedure( n ); lvars n;
        if n == 0 do
            read_scheme( cucharin )
        elseif n == 1 do
            read_scheme( charInputPort() )
        else
            checkargs( n, 1, 'READ' )
        endif;
    endprocedure;

define_variable read\-char
    procedure( n ); lvars n;
        if n == 0 do
            cucharin()
        elseif n == 1 do
            charInputPort()()
        else
            checkargs( n, 1, 'READ-CHAR' )
        endif
    endprocedure;

;;; version 12 onwards
define_monadic real\? isdecimal;

define_monadic real\-part realpart;

define_dyadic remainder nonop rem;

define_monadic reverse rev;

;;; version 12 onwards
define_monadic round
    procedure( x ); lvars x;
        if x.isintegral do
            x
        else
            lvars f = fracof( x );
            lvars i = intof( x );
            if f < 1_/2 do      i
            elseif f > 1_/2 do  i + sign( x )
            else
                if i.iseven do  i
                else            i + sign( x )
                endif
            endif;
        endif;
    endprocedure;

;;; --S
define_dyadic set\-car\! updater(front);
define_dyadic set\-cdr\! updater(back);

define_monadic sin sin;

define_monadic sqrt sqrt;

define_monadic string\-\>list deststring<>conslist;

define_variable string\-\>number
    procedure();
        checkargs( 3, 'STRING-NUMBER' );
        string_into_number();
    endprocedure;

define_monadic string\-\>symbol consword;

define_monotonic string\-ci\=\?   string_ci_promote( nonop == );
define_monotonic string\-ci\<\?   string_ci_promote( nonop < );   ;;; fi_<
define_monotonic string\-ci\<\=\? string_ci_promote( nonop <= );  ;;; fi_<=
define_monotonic string\-ci\>\?   string_ci_promote( nonop > );   ;;; fi_>
define_monotonic string\-ci\>\=\? string_ci_promote( nonop >= );  ;;; fi_>=

define_variable string\-append
    procedure( n ); lvars n;
        lvars n = consvector( n );
        cons_with consstring {% appdata( n, explode ) %}
    endprocedure;

define_dyadic string\-fill\!
    procedure( s, c ); lvars s, c;
        lconstant unspecified = consUnspecified( "string\-fill\!" );
        set_bytes( c, 1, s, datalength( s ) );
        unspecified;
    endprocedure;

define_monadic string\-copy copy;

define_monadic string\-length datalength;

define_monadic string\-null\? datalength<>nonop ==(%0%);

define_dyadic  string\-ref swop<>subscrs;

define_variable string\-set\!
    procedure(s, k, c); lvars s, k, c;
        lconstant unspecified = consUnspecified( "string\-set\!" );
        lconstant usubscrs = updater( subscrs );
        usubscrs( c, k, s );
        unspecified;
    endprocedure;

define_monotonic string\=\? string_promote( nonop == );
define_monotonic string\<\?   string_promote( nonop < );   ;;; fi_<
define_monotonic string\<\=\? string_promote( nonop <= );  ;;; fi_<=
define_monotonic string\>\?   string_promote( nonop > );   ;;; fi_>
define_monotonic string\>\=\? string_promote( nonop >= );  ;;; fi_>=

define_monadic string\? isstring;

define_variable substring
    procedure( n ); lvars n;
        unless n == 3 do
            mishap(
                conslist( n ),
                1,
                'Wrong number of args for SUBSTRING'
            )
        endunless;
        lvars endposn = ();
        lvars startposn = ();
        ;;; & now pick string off stack
        substring( startposn, startposn - endposn + 1 )
    endprocedure;

define_variable substring\-fill\!
    procedure( n ); lvars i, str, ch, n;
        lconstant unspecified = consUnspecified( "substring\-fill\!" );
        unless n == 4 do
            mishap(
                conslist( n ),
                1,
                'Wrong number of args for SUBSTRING-FILL!'
            )
        endunless;
        lvars ch = ();
        lvars endposn = ();
        lvars startposn = ();
        lvars str = ();
        unless str.isstring do
            mishap( str, 1, 'String needed for SUBSTRING-FILL!' )
        endunless;
        lvars i;
        fast_for i from startposn to endposn do
            ch -> fast_subscrs( i, str );
        endfor;
        unspecified;
    endprocedure;

define_monadic symbol\-\>string destword <> consstring;

define_monadic symbol\? isword;

;;; --T

define_variable t true;

define_monadic tan tan;

define_monadic transcript\-on
    procedure( file ); lvars file = discout( file );
        checkargs( 0, 'TRANSCRIPT-ON' );
        lvars c;
        consInputPort(
            default_input_port,
            default_input_port.charInputPort <> dup <> file ->> cucharin
        ) -> default_input_port;
        consOutputPort(
            default_output_port,
            dup <> default_output_port.charOutputPort <> file ->> cucharout,
        ) -> default_output_port;
        lconstant unspecified = consUnspecified( "transcript\-on" );
        unspecified;
    endprocedure;

define_variable transcript\-off
    procedure();
        checkargs( 0, 'TRANSCRIPT-OFF' );
        lvars port = default_input_port.deviceInputPort;
        if port.isdevice do
            port -> default_input_port;
        else
            mishap( 'Transcript not in progress', [] )
        endif;
        charInputPort( port ) -> cucharin;
        lvars port = default_output_port.deviceOutputPort;
        if port.isdevice do
            port -> default_output_port;
        else
            mishap( 'Transcript not in progress', [] )
        endif;
        charOutputPort( port ) -> cucharout;
        lconstant unspecified = consUnspecified( "transcript\-off" );
        unspecified;
    endprocedure;

define_monadic truncate intof <> abs;

;;; --U
;;; --V
define_variable vector consvector;

define_monadic vector\? isvector;

define_monadic vector\-\>list destvector<>conslist;

define_monadic vector\-length datalength;

define_monadic vector\-ref swop <> subscrv;

define_variable vector\-set\!
    procedure( n ); lvars v, k, x, n;
        lconstant unspecified = consUnspecified( "vector\-set\!" );
        unless n == 3 do
            mishap(
                conslist( n ),
                1,
                'Wrong number of args for VECTOR-SET!'
            )
        endunless;
        lvars x = (), k = (), v = ();
        x -> subscrv( k, v );
        unspecified;          
    endprocedure;

;;; --W

define_dyadic with\-input\-from\-file
    procedure( str, thunk ); lvars str, thunk;
        lconstant unspecified = consUnspecified( "with\-input\-from\-file" );
        lvars port = newInputPort( str );
        withinInputPort( 0, thunk, port );
        closeInputPort( port );
        unspecified;
    endprocedure;

define_dyadic with\-output\-from\-file
    procedure( str, thunk ); lvars str, thunk;
        lconstant unspecified = consUnspecified( "with\-output\-from\-file" );                    
        lvars port = newOutputPort( str );
        withinOutputPort( 0, thunk, port );
        closeOutputPort( port );
        unspecified;          
    endprocedure;

define_variable write
    procedure( n ); lvars n;
        lconstant unspecified = consUnspecified( "write" );
        if n == 1 do
            print_scheme()
        elseif n == 2 do
            lvars port = ();
            withinOutputPort( print_scheme, port )
        else
            checkargs( n, 1, 'WRITE' )
        endif;
        unspecified;
    endprocedure;


define_variable write\-char
    procedure( n ); lvars n;
        lconstant unspecified = consUnspecified( "write\-char" );
        if n == 1 do
            cucharout()
        elseif n == 2 do
            charOutputPort()()
        else
            checkargs( 2, n, 'WRITE-CHAR' )
        endif;
        unspecified;
    endprocedure;

;;; --X
;;; --Y
;;; --Z
define_monadic zero\? nonop ==(% 0 %);

;;; -------------------------------------------------------------------------
;;; syscancel("define_monadic");
;;; syscancel("define_dyadic");
;;; syscancel("define_variadic");
;;; syscancel("define_variable");
;;; syscancel("define_monotonic");
;;; -------------------------------------------------------------------------
