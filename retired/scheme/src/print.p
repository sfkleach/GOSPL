
;;; -- Scheme print function ------------------------------------------------

constant print_table =
    newproperty(
        [],
        10,
        pr,
        true
    );

define print( x ); lvars x;
    if x == nil do "nil".pr
    elseif x == true do '#t'.pr
    elseif x == false do '#f'.pr
    else
        apply(x, x.datakey.print_table)
    endif
enddefine;

define print_scheme( s ); lvars s;
    dlocal pop_pr_quotes = false;
    print( s );
enddefine;

;;; -- PRINT TABLE ----------------------------------------------------------

define print_ratio( x ); lvars x;
    pr( numerator( x ) );
    cucharout( `/` );
    pr( denominator( x ) );
enddefine;
print_ratio -> print_table( datakey( 1_/2 ) );

define print_complex( x ); lvars x;
    lvars r, i;
    destcomplex( x ) -> i -> r;
    print( r );
    if i < 0 do `-` else `+` endif.cucharout;
    print( abs( i ) );
    `i`.cucharout;        
enddefine;
print_complex -> print_table( datakey( 1 +: 1 ) );

define print_pair( p ); lvars p;
    "(".pr;
    print( destpair( p ) -> p );
    while p.ispair do
        cucharout(` `);
        print( destpair( p ) -> p );
    endwhile;
    unless p == nil do
        '. '.pr;
        print( p );
    endunless;
    ")".pr
enddefine;
print_pair -> print_table( conspair(undef, undef).datakey );

define print_vector( x ); lvars x;
    if datalength( x ) == 0 do
        appdata( '#()', cucharout )
    else
        '#('.pr;
        print( x(1) );
        lvars i;
        for i from 2 to length(x) do
            cucharout( ` ` );
            x(i).print;
        endfor;
        ")".pr;
    endif
enddefine;
print_vector -> print_table( {}.datakey );

define print_procedure( x ); lvars x;
    if pdprops(x) do
        pdprops(x).print
    else
        'lambda'.pr
    endif;
enddefine;
print_procedure -> print_table( identfn.datakey );
