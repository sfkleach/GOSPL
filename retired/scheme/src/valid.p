;;; -- Validating Syntax ----------------------------------------------------

;;; -- Forward declarations
vars procedure valid_sexp;

;;; -- Declare the special used for all contextual communication
vars varg;

;;; -- Raising an error

define invalidity( mess ); lvars mess;
;;;     lvars count = 0, v;
;;;     [% until (caller_valof( "varg", 1 + count ->> count ) ->> v).isundef do
;;;         v
;;;     enduntil %] ==>
    mishap( mess, [^varg] )
enddefine;

define invalid_arity;
    invalidity( 'Wrong number of args' )
enddefine;

;;; -- valid table is a disguise for special table

define valid_table( x ); lvars x;
    validSpecial( special_table( x ) )
enddefine;

define updaterof valid_table( v, x ); lvars v, x;
    v -> validSpecial( special_table( x ) )
enddefine;


;;; -- Validating Code for a general sexpression

vars varg;
define valid_seq( varg, m, n ); dlocal varg; lvars m, n;
    lvars count = 0;
    while varg.ispair do
        1 + count -> count;
        valid_sexp( varg.destpair -> varg )
    endwhile;
    unless varg == nil do
        invalidity( 'Improper list of s-exprs ' )
    endunless;
    if m and count < m do
        invalidity( 'Too few s-exprs' )
    endif;
    if n and count > n do
        invalidity( 'Too many s-exprs' )
    endif;
enddefine;

vars valid_at_least = valid_seq(% false %);
vars valid_at_least_one = valid_at_least(% 1 %);
vars valid_exactly_one = valid_seq(% 1, 1 %);
vars valid_body = valid_seq(% false, false %);


;;; -- Valid sexp

define valid_sexp( varg ); dlocal varg;
    lvars h, t, p;
    if varg.ispair do
        destpair( varg ) -> t -> h;
        if (valid_table( h ) ->> p) do
            p( t )
        else
            valid_at_least_one( varg )
        endif;
    endif;
enddefine;

define dp( x ); lvars x;
    if x.ispair do fast_destpair( x )
    else invalid_arity()
    endif
enddefine;

;;; -- SPECIAL FORMS TABLE ENTRIES ------------------------------------------


;;; -- and

valid_body -> valid_table( "and" );

;;; -- begin

valid_at_least_one -> valid_table( "begin" );

;;; -- case

define valid_case( t ); lvars t;
    lvars clauses;
    valid_sexp( dp( t ) -> clauses );
    while clauses.ispair do
        lvars c = destpair( clauses ) -> clauses;
        unless c.ispair do invalidity( 'Invalid clause' ) endunless;
        lvars dlist = destpair( c ) -> c;
        if dlist == "else" do
            unless clauses == nil do
                invalidity( 'Misplaced ELSE part' )
            endunless;
        else
            while dlist.ispair do
                back( dlist ) -> dlist;
            endwhile;
            unless dlist == nil do
                invalidity( 'Invalid data list of clause' )
            endunless;
        endif;
        valid_at_least_one( c );
    endwhile;
    unless clauses == nil do
        invalidity( 'Improper list of clauses' )
    endunless;
enddefine;
valid_case -> valid_table( "case" );

;;; -- cond

define valid_cond( t ); lvars t;
    while t.ispair do
        lvars c = destpair( t ) -> t;
        unless c.ispair do invalidity( 'Invalid clause' ) endunless;
        lvars test = destpair( c ) -> c;
        if test == "else" do
            unless t == nil do
                invalidity( 'Misplaced ELSE' )
            endunless;
        else
            valid_sexp( test )
        endif;
        valid_at_least_one( c );
        if front( c ) == "=>" do
            unless listlength( c ) >= 2 do
                invalidity( 'Invalid => clause of COND' )
            endunless;
        endif;
    endwhile;
    unless t == nil do
        invalidity( 'Improper clauses sequence' )
    endunless;
enddefine;
valid_cond -> valid_table( "cond" );


;;; -- define

define valid_define( t ); lvars t;
    define lconstant oops();
        invalidity( 'Invalid 1st arg for DEFINE' )
    enddefine;
    lvars h = t.dp -> t;
    if h.isword do
        unless back( t ) == nil do
            invalid_arity()
        endunless;
        valid_sexp( front( t ) )
    elseif h.ispair do
        unless front( h ).isword do oops() endunless;
        valid_at_least_one( t );
    else
        oops()
    endif;
enddefine;
valid_define -> valid_table( "define" );


;;; -- delay

valid_exactly_one -> valid_table( "delay" );

;;; -- do

define valid_iteration_spec( varg ); lvars varg;
    lvars count = 0;
    unless isword( dp( varg ) -> varg ) do
        invalidity( 'Non-variable as first element of iteration spec' )
    endunless;
    while varg.ispair do
        if (count + 1 ->> count) > 3 do
            invalidity( 'Iteration spec is too long' )
        endif;
        valid_sexp( destpair( varg ) -> varg );
    endwhile;
    if count < 2 do invalidity( 'Iteration spec is too short' ) endif;
enddefine;

define valid_do( t ); lvars t;
    lvars varlist = t.dp -> t;
    while varlist.ispair do
        valid_iteration_spec( destpair( varlist ) -> varlist );
    endwhile;
    unless varlist == nil do
        invalidity( 'Improper list of iteration specs' )
    endunless;
    lvars testlist = t.dp -> t;
    valid_at_least_one( testlist );
    valid_at_least_one( t );
enddefine;
valid_do -> valid_table( "do" );

;;; -- if
valid_seq(% 2, 3 %) -> valid_table("if" );


;;; -- lambda

define valid_formals( varg ); lvars varg;                    
    lvars oops = invalidity(% 'Invalid formal parameter s-expr' %);
    lvars x = varg;
    if x.isword do ;;; nothing
    elseif x.islist do
        while x.ispair do
            unless (destpair( x ) -> x).isword do oops() endunless
        endwhile;
        unless x == nil or isword( x ) do oops() endunless;
    else oops()
    endif;
enddefine;

define valid_lambda( t ); lvars t;
    valid_formals( dp( t ) -> t );
    valid_at_least_one( t );
enddefine;
valid_lambda -> valid_table( "lambda");


;;; -- let

define valid_binding( varg ); lvars varg;                    
    unless varg.ispair do
        invalidity( 'Atom as binding in let-form' )
    endunless;
    lvars t;
    unless isword( varg.destpair -> t ) do
        invalidity( 'First element of binding is not a word' )
    endunless;
    unless back( t ) == nil do
        invalidity( 'Improper list as binding' )
    endunless;
    valid_sexp( front( t ) );
enddefine;

define valid_let( t ); lvars t;
    if t.ispair and front( t ).isword do
        back( t ) -> t;     ;;; named let
    endif;
    lvars bindings = t.dp -> t;
    while bindings.ispair do
        valid_binding( destpair( bindings ) -> bindings )
    endwhile;
    unless bindings == nil do
        invalidity( 'Improper list of bindings' )
    endunless;
    valid_at_least_one( t );
enddefine;
valid_let -> valid_table( "let" );

;;; -- let*
valid_let -> valid_table( "let\*" );

;;; -- letrec
valid_let -> valid_table( "letrec" );

;;; -- null?
valid_exactly_one -> valid_table("null\?");

;;; -- or
valid_body -> valid_table( "or" );

;;; -- quasiquote

define valid_qq( x ); lvars x;
    if x.ispair do
        lvars f = front( x );
        if f == "unquote" or f == "unquote\-splicing" do
            back( x ) -> x;
            unless x.ispair and back( x ) == nil do
                invalid_arity()
            endunless;
            valid_sexp( front( x ) );                  
        else
            while x.ispair do
                valid_qq( x.destpair -> x )
            endwhile;
            valid_qq( x )
        endif;
    elseif x.isvector do
        appdata( x, valid_qq )
    endif
enddefine;

define valid_quasiquote( t ); lvars t;
    lvars h = t.dp -> t;
    unless t == nil do invalid_arity() endunless;
    valid_qq( h );
enddefine;
valid_quasiquote -> valid_table( "quasiquote" );


;;; -- Quote
define valid_quote( t ); lvars t;
    unless t.ispair and t.back == nil do
        invalid_arity()
    endunless
enddefine;
valid_quote -> valid_table( "quote" );

;;; -- set!
define valid_set( t ); lvars t;
    unless t.ispair do invalid_arity() endunless;
    unless (t.destpair -> t).isword do
        invalidity( 'Non-word as first arg' )
    endunless;
    unless back( t ) == nil do
        invalidity( 'Invalid second arg' )
    endunless;
    valid_sexp( front( t ) );
enddefine;
valid_set -> valid_table( "set\!" );

;;; -- unquote
procedure( t ) with_props UNQUOTE; lvars t;
    invalidity('UNQUOTE outside of QUASIQUOTE')
endprocedure -> valid_table( "unquote" );

;;; -- unquote-splicing
procedure( t ) with_props QUOTE\-UNSPLICING; lvars t;
    invalidity('UNQUOTE-SPLICING outside of QUASIQUOTE')
endprocedure -> valid_table( "unquote\-splicing" );

;;; -- zero?
valid_exactly_one -> valid_table("zero\?");
