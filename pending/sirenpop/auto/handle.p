compile_mode :pop11 +strict;

section;

lvars raiser_list = [];
lvars detect_suspend;
lvars s_length;

define lconstant catcher( basep, raiser ); lvars basep, raiser;
    dlocal detect_suspend = false;
    dlocal 0 % (), if dlocal_context == 3 then true -> detect_suspend endif % ;
    dlocal raiser_list = conspair( raiser, raiser_list );
    dlocal s_length = stacklength();
    basep();
    unless detect_suspend do
        erase( sys_grbg_destpair( raiser_list ) -> raiser_list )
    endunless;
enddefine;

define lconstant throw( p, n, exn ); lvars p, n, exn;
    lvars remove_n = stacklength() - s_length - n;
    if remove_n < 0 then
        mishap( 'NOT ENOUGH ITEMS ON STACK FOR EXCEPTION', [ ^exn ] );
    elseif remove_n > 0 then
        lvars L = conslist( n );
        erasenum( remove_n );
        sys_grbg_destlist( L ).erase;
    endif;
    chainfrom( catcher, p )
enddefine;

define global sys_raise( n, exn  ); lvars n, exn;
    lvars r;
    for r in raiser_list do
        r( n, exn )
    endfor;
    mishap( 'UNHANDLED EXCEPTION', [ ^exn ] )
enddefine;

define global syntax raise;
    dlocal pop_new_lvar_list;
    lvars name = readitem().check_word;
    pop11_need_nextreaditem( "(" ).erase;
    lvars v = sysNEW_LVAR();
    { [ call stacklength ] [ pop ^v ] }.plant;
    pop11_comp_expr_seq_to( ")" ).erase;
    [ callq ^sys_raise
        [ call - [ call stacklength ] [ push ^v ] ]
        [ push ^name ]
    ].plant
enddefine;

define global new_exception() -> e; lvars e;
    sys_raise(% undef %) -> e;
    e -> frozval( 1, e );
enddefine;

global vars syntax endhandle;

define global syntax handle;
    lconstant wds = [ on endhandle ];
    lvars tok = undef;
    sysPROCEDURE( "handler", 0 );
    pop11_comp_stmnt_seq_to( wds ) -> tok;
    lvars basep = sysENDPROCEDURE();

    if tok == "endhandle" then
        sysCALLQ( basep )
    else
        sysPROCEDURE( "handler_case", 0 );
        lvars exn = sysNEW_LVAR();
        lvars exn_nargs = sysNEW_LVAR();
        { [ pop ^exn ] [ pop ^exn_nargs ] }.plant;
        lvars exitlab = sysNEW_LABEL();
        repeat
            lvars fail = sysNEW_LABEL();
            lvars f = readitem();
            [ call == [ push ^exn ] [ push ^f ] ].plant;
            [ ifnot ^fail ].plant;
            lvars nargs = 0;
            lvars vs = [];
            if pop11_try_nextreaditem( "(" ) then
                lvars ( vs, nargs ) = read_variables().dup.length;
                lvars i, k = nargs + 1;
                for i in vs do
                    k - 1 -> k;
                    [ call subscr_stack [ pushq ^k ] ].plant;
                    { [ lvar ^i ] [ pop ^i ] }.plant
                endfor;
            endif;
            if pop11_try_nextreaditem( "where" ) then
                pop11_comp_expr_to( "do" ).erase;
                sysIFNOT( fail );
            else
                pop11_need_nextreaditem( "do" ).erase;
            endif;
            sysPROCEDURE( false, 0 );
            lvars i;
            for i in vs.rev do
                { [ lvar ^i ] [ pop ^i ] }.plant
            endfor;
            pop11_comp_stmnt_seq_to( wds ) -> tok;
            sysENDPROCEDURE().sysPUSHQ;
            [ callq ^throw [ pushq ^nargs ] [ push ^exn ] ].plant;
            sysLABEL( fail );
            quitif( tok == "endhandle" );
        endrepeat;
        sysLABEL( exitlab );
        lvars handlep = sysENDPROCEDURE();

        [ callq ^catcher [ pushq ^basep ] [ pushq ^handlep ] ].plant
    endif;
enddefine;

endsection
