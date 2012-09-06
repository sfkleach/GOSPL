;;; Summary: Simple optional argument facility
;;; Version: 1.0

compile_mode :pop11 +strict;

section $-gospl$-optarg =>
    optarg
    is_optarg
;

constant optarg_mark = stackmark.copy;

define is_optarg();
    dup() == optarg_mark
enddefine;

define next_optarg();
    if stacklength() fi_> 2 then
        false, false, false
    elseif dup() == optarg_mark then
        () -> _;        ;;; erase
        true
    else
        false, false, false
    endif
enddefine;

define global syntax optarg;

    define check_1( before );
        lvars diff = stacklength() - before;
        if diff /== 1 then
            lvars msg = 'Too %p results from optarg (wanted 1, got %p)';
            if diff < 1 then
                mishap( sprintf( msg, [ 'few' ^diff ] ), [] )
            else
                lvars args = conslist( diff );
                mishap( sprintf( msg, [ 'many' ^diff ] ), args )
            endif
        endif
    enddefine;

    lvars name = nextreaditem();
    if name.isword then
        sysPUSHQ( name );
    else
        mishap( 'Procedure variable needed', [ ^name ] );
    endif;
    if pop11_try_nextreaditem( "=" ) then
        dlocal pop_new_lvar_list;
        lvars v = sysNEW_LVAR();
        sysCALL( "stacklength" );
        sysPOP( v );
        pop11_comp_stmnt_seq_to( "endoptarg" ) -> _;
        sysCALL( "stacklength" );
        sysPUSH( v );
        sysCALLQ( check_1 );
    else
        pop11_comp_procedure( "endoptarg", false, false );
    endif;
    sysPUSHQ( optarg_mark );
enddefine;

endsection;
