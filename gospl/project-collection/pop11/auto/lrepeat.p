compile_mode :pop11 +strict;

uses int_parameters                 ;;; Needed for -pop_max_int-

section better_syntax => lrepeat endlrepeat;

define prepare( N );
    if isinteger( N ) then          ;;; Try to get thru with only 1 call.
        ( if N fi_<= 0 then 0 else N endif, 0 )
    elseif N <= 0 then
        0, 0
    elseif isintegral( N ) then
        pop_max_int,
        N - pop_max_int             ;;; OK, can go negative.
    else
        ;;; In-line implementation of "ceiling", a missing Pop-11
        ;;; primitive.
        chain( intof( N ) + if fracof( N ) > 0 then 1 else 0 endif, prepare )
    endif
enddefine;

define lconstant doLoop( closer );
    dlocal pop_new_lvar_list;
    lvars ( count, carry ) = ( sysNEW_LVAR(), sysNEW_LVAR() );
    pop11_comp_expr_to( "times" ).erase;
    sysPOP( carry );
    lvars alpha = sysNEW_LABEL();
    sysLABEL( alpha );
    sysPUSH( carry );
    sysCALLQ( prepare );
    sysPOP( carry );
    sysPOP( count );
    lvars beta = sysNEW_LABEL().dup.pop11_loop_start;
    lvars psi = sysNEW_LABEL();
    lvars omega = sysNEW_LABEL().dup.pop11_loop_end;
    sysLABEL( beta );
    sysPUSH( count ); sysPUSHQ( 0 ); sysCALL( "==" );
    sysIFSO( psi );
    sysPUSH( count ); sysPUSHQ( 1 ); sysCALL( "fi_-" ); sysPOP( count );
    sysLBLOCK( popexecute);
    closer.pop11_comp_stmnt_seq_to.erase;
    sysENDLBLOCK();
    sysGOTO( beta );
    sysLABEL( psi );
    sysPUSH( carry );
    sysPUSHQ( 0 );
    sysCALL( "==" );
    sysIFNOT( alpha );
    sysLABEL( omega );
enddefine;

define lconstant is_times( closer );
    dlocal proglist_state;
    dlocal pop_syntax_only = true;
    pop11_comp_expr();
    pop11_try_nextreaditem( "times" )
enddefine;

define lrepeatCompile( closer );
    if pop11_try_nextreaditem( "forever" ) or not( is_times( closer ) ) then
        lvars alpha = sysNEW_LABEL().dup.pop11_loop_start;
        lvars omega = sysNEW_LABEL().dup.pop11_loop_end;
        sysLABEL( alpha );
        closer.pop11_comp_stmnt_seq_to.erase;
        sysGOTO( alpha );
        sysLABEL( omega );
    else
        doLoop( closer )
    endif;
enddefine;

global vars syntax endlrepeat;

define global syntax lrepeat;
    lrepeatCompile( "endlrepeat" )
enddefine;

endsection;
