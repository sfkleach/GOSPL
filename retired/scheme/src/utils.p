
;;; -- Swop the top two elements of the stack -------------------------------

define constant procedure swop( x, y ); lvars x, y;
    y; x;
enddefine;

;;; -- Used for checking correct arity --------------------------------------

define constant procedure checkargs( m, n, mess ); lvars m, n, mess;
    unless m == n do
        mishap(
            conslist( m ),
            1,
            mess <> ': Wrong number of arguments'
        )
    endunless;
enddefine;

;;; -- Used for implementing rational approximations ------------------------

define contfraction( n0 ); lvars n0;
    define lconstant procedure genfractions( n, p1, p2, q1, q2 );
        lvars n, p1, p2, q1, q2;
        procedure;
            lvars f = fracof( n );
            if f == 0 do
                termin
            else
                1 / f -> n;
                lvars intn = intof( n );
                p2, p2 * intn + p1 -> p2 -> p1;
                q2, q2 * intn + q1 -> q2 -> q1;
                p2/q2
            endif;
        endprocedure.pdtolist
    enddefine;
    lvars n0 = number_coerce( n0, 0 );
    lvars q0 = 1;
    lvars p0 = intof( n0 );
    lvars n1 = 1 / fracof( n0 );
    lvars q1 = intof( n1 );
    lvars p1 = p0 * q1 + 1;
    conspair(
        p0/q0,
        conspair(
            p1/q1,
            genfractions( n1, p0, p1, q0, q1 )
        )
    )
enddefine;

;;; -- Used to implement exactness ------------------------------------------

define mapcomplex( x, p ); lvars x, procedure p;
    lvars y;
    p( destcomplex( x ) -> y ) +: p( y )
enddefine;

define exact_into_inexact( x ); lvars x;
    if x.isdecimal do x
    elseif x.iscomplex do mapcomplex( x, exact_into_inexact )
    else number_coerce( x, 0.0 )
    endif
enddefine;

define inexact_into_exact( x ); lvars x;
    if x.isdecimal do number_coerce( x, 0 )
    elseif x.iscomplex do mapcomplex( x, inexact_into_exact )
    else x
    endif
enddefine;

define isexact( x ); lvars x;
    x.isdecimal or
    (
        x.iscomplex and
        (
            isdecimal( realpart( x ) ) or
            isdecimal( imagpart( x ) )
        )
    )
enddefine;

;;; -- Implements string comparison operators -------------------------------

define constant downcase( x, y ); lvars x, y;
    uppertolower( x ); uppertolower( y );
enddefine;

define promoted_string_op(s1, s2, op, access);
    lvars i, s1, s2, op, access;
    unless s1.isstring do
        mishap('String needed', [^s1 ^op])
    endunless;
    unless s2.isstring do
        mishap('String needed', [^s2 ^op])
    endunless;
    lvars l1 = datalength( s1 );
    lvars l2 = datalength( s2 );
    fast_for i from 1 to min( l1, l2 ) do
        unless op( access( i, s1 ), access( i, s2 ) ) do
            return( false );
        endunless
    endfor;
    if l1 < l2 do
        fast_for i from l1+1 to l2 do
            unless op( 0, access( i, s2 ) ) do
                return( false )
            endunless
        endfor;
    elseif l2 < l1 do
        fast_for i from l2+1 to l1 do
            unless op( access( i, s1 ), 0 ) do
                return( false )
            endunless
        endfor;
    endif;
    true;
enddefine;

define string_promote_base( op, access ); lvars op, access;
    promoted_string_op(% op, access %);
enddefine;

vars string_promote = string_promote_base(% fast_subscrs %);
vars string_ci_promote = string_promote_base(% fast_subscrs <> uppertolower %);


;;; -- Implements association list lookup -----------------------------------

define lookup( x, list, op ); lvars x, list, op;
    while list.ispair do
        lvars el = fast_destpair( list ) -> list;
        if op( front( el ), x ) do return( el ) endif;
    endwhile;
    false;
enddefine;

;;; -- Implements call with current continuation ----------------------------

define call_/_cc( p ); lvars p;
    lvars cc = consprocto( 0, read_eval_print );
    if cc.isprocess do
        chain(
            procedure( n, cc ); lvars n, cc;
                unless n == 1 do
                    mishap(
                        conslist( n ),
                        1, 'Wrong number of args for continuation'
                    )
                endunless;
                resume( 1, copy( cc ) );
            endprocedure(% cc %),
            1, p
        )
    else
        ->;
        cc;     ;;; The result "wanted" by the continuation
    endif
enddefine;


;;; -- Used in FOREACH & MAP ------------------------------------------------

define constant multi_app_for_scheme( v, p, proc );
    lvars v, p, procedure proc;
    lvars len = datalength( v );
    repeat
        lvars i;
        fast_for i from 1 to len do
            lvars a = fast_subscrv( i, v );
            if a.ispair do
                destpair( a ) -> fast_subscrv( i, v )
            else
                return( a );
            endif
        endfor;
        proc( p( len ) );
    endrepeat
enddefine;

;;; Used in FOREACH & MAP
define constant procedure single_app_for_scheme( p, list, proc );
    lvars procedure p, list, procedure proc;
    while list.ispair do
        proc( p( fast_destpair(list) -> list, 1 ) );
    endwhile;
    list;
enddefine;

;;; -- STRING->NUMBER & NUMBER->STRING --------------------------------------

;;; Note that stringin does not do pushbacks but ought to!
define string_into_number( string, exactness, radix ) -> num;
    lvars string, exactness, radix, num;
    if radix == "B" do      '#b'
    elseif radix == "O" do  '#o'
    elseif radix == "X" do  '#x'
    elseif radix == "D" do  ''
    else
        mishap( 'Illegal radix', [^radix] )
    endif <> string -> string;
    dlocal cucharin = newPushable( stringin( string ) );
    lvars num = read_scheme();
    unless num.isnumber do
        mishap( 'Not a number', [^num] );
    endunless;
    lvars t = read_scheme();
    unless t == termin do
        mishap( 'Found s-exp after the number', [^t] )
    endunless;
    if exactness == "E" do
        inexact_into_exact( num )
    elseif exactness == "I" do
        exact_into_inexact( num )
    else
        mishap( 'Exactness not \'E or \'I', [^exactness] )
    endif -> num;
enddefine;


;;; -- Number into string

define exactness_of_format( f ) -> e; lvars f, e = false;
    lvars i;
    for i in f do
        if i.ispair and front( i ) == "exactness" and back(i).ispair do
            lvars b = front( back( i ) );
            if b == "e" do      true
            elseif b == "s" do  false
            else
                mishap( 'Not \'e or \'s', [^b] )
            endif -> e;
            return;
        endif;
    endfor;
enddefine;

define radix_of_format( f ) -> r -> s;
    lvars f, r = "D", s = false;
    lvars i;
    for i in f do
        if i.ispair and front( i ) == "radix" do
            if (i.back ->> i).ispair do
                lvars r = front( i );
                if (i.back ->> i).ispair do
                    lvars f = front( i );
                    if f == "e" do      true
                    elseif f == "s" do  false
                    else
                        mishap( 'Not \'r or \'s', [^f] )
                    endif -> s
                endif;
            endif;
            return
        endif;
    endfor
enddefine;

constant format_table =
    newproperty( [], 10, mishap(% 4, 'Unknown format' %), true );

procedure( n, f ); lvars n, f;
    ;;; Simple, I think             
    mishap( 'TBD', [] )
endprocedure -> format_table( "int" );

procedure( n, f ); lvars n, f;
    ;;; Simple
    mishap( 'TBD', [] )
endprocedure -> format_table( "rat" );

procedure( n, f ); lvars n, f;
    mishap( 'TBD', [] )
endprocedure -> format_table( "fix" );

procedure( n, f ); lvars n, f;
    mishap( 'TBD', [] )
endprocedure -> format_table( "flo" );

procedure( n, f ); lvars n, f;
    mishap( 'TBD', [] )
endprocedure -> format_table( "sci" );

procedure( n, f ); lvars n, f;
    lvars i, r;
    destcomplex( n ) -> i -> r;
    ;;; Simple
    mishap( 'TBD', [] )
endprocedure -> format_table( "rect" );

procedure( n, f ); lvars n, f;
    lvars i, r;
    destcomplex( n ) -> i -> r;
    lvars m = sqrt( r**2 + i**2 );
    lvars a = arctan2( r, i );
    ;;; Simple
    mishap( 'TBD', [] )
endprocedure -> format_table( "polar" );

procedure( n, f ); lvars n, f;
    print( n )
endprocedure -> format_table( "heur" );

define number_into_string( n, f ); lvars n, f;
    lconstant lookup = [[D 10] [B 2] [O 8] [X 16]].assoc;
    lvars e = exactness_of_format( f );
    lvars r, s;
    radix_of_format( f ) -> r -> s;
    dlocal cucharout = identfn;
    cons_with consstring {%
        if e do
            cucharout( `#` );
            if isexact( n ) do  `E`
            else                `I`
            endif.cucharout
        endif;
        if s do
            cucharout( `#` );
            pr( r );
        endif;
        lvars b = lookup( r );
        unless b do
            mishap( 'Invalid radix', [^r] )
        endunless;
        dlocal pop_pr_radix = b;
        format_table( f.destpair -> f )( n, f )
    %}
enddefine;


;;; -------------------------------------------------------------------------
