;;; -- functorclass ---------------------------------------------------------
;;; Useful for declaring prolog-functors to give a recordclass like interface
;;; from Pop11.

define syntax functorclass;
    lvars popname, plogname;

    readitem() ->> popname -> plogname;
    unless popname.isword do
        mishap( 'INVALID CLASS NAME', [ ^popname ] )
    endunless;

    if pop11_try_nextreaditem( "as" ) then
        readitem() -> popname;
        if popname.isstring then
            popname.consword -> popname
        endif;
        unless popname.isword do
            mishap( 'INVALID FUNCTOR NAME', [ ^popname ] )
        endunless;
    endif;

    lvars fields =
        {%
            until pop11_try_nextreaditem( ";" ) do
                lvars id, field = readitem();
                if
                    field.isword and
                    (field.identprops ->> id) == undef or
                    id == 0
                then
                    field
                else
                    mishap( 'INVALID FIELD NAME', [^field] )
                endif;
            enduntil;
        %};
    [ ; ^^proglist ] -> proglist;
    lvars arity = fields.length;

    define lconstant procedure check( x ); lvars x;
        lvars ( f, n ) = prolog_termspec( x );
        unless f == plogname and n == arity do
            mishap( x, 'WRONG FUNCTOR/ARITY' )
        endunless
    enddefine;

    sysGVAR( "cons" <> popname );
    sysPROCEDURE( "cons" <> popname, length( fields ) );
    sysPUSHQ( plogname );
    sysPUSHQ( arity );
    sysCALL( "prolog_maketerm" );
    sysPASSIGN( sysENDPROCEDURE(), "cons" <> popname );

    sysGVAR( "dest" <> popname );
    sysPROCEDURE( "dest" <> popname, 1 );
    sysPUSHS( undef );
    sysCALLQ( check );
    sysCALL( "prolog_args" );
    sysPASSIGN( sysENDPROCEDURE(), "dest" <> popname );

    sysGVAR( "is" <> popname );
    sysPROCEDURE( "is" <> popname, 1 );
    sysCALLQ( prolog_termspec );
    sysPUSHQ( arity );
    sysCALL( "==" );
    sysIFSO( "ok" );
    sysERASE( undef );
    sysPUSHQ( false );
    sysGOTO( "return" );
    sysLABEL( "ok" );
    sysPUSHQ( plogname );
    sysCALL( "==" );
    sysLABEL( "return" );
    sysPASSIGN( sysENDPROCEDURE(), "is" <> popname );

    lvars i;
    for i from 1 to length( fields ) do
        lvars f = fields( i );
        sysGVAR( f );
        sysPROCEDURE( f, 1 );
        sysPUSHS( undef );
        sysCALLQ( check );
        sysPUSHQ( i );
        sysSWAP( 1, 2 );
        sysCALL( "prolog_arg" );
        sysPASSIGN( sysENDPROCEDURE(), f );
    endfor;
enddefine;
;;; -------------------------------------------------------------------------
