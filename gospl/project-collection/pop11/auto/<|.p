;;; Summary: shorthand for anonymous functions (lambdas)

compile_mode :pop11 +strict;

section;

global vars syntax |> ;

define syntax <| ;
    lvars state = { ^proglist_state };
    lvars variables = read_variables();
    sysPROCEDURE( false, 0 );
    if pop11_try_nextreaditem( ":" ) then
        lvars i;
        for i in variables do
            sysLVARS( i, 0 )
        endfor;
        for i in rev( variables ) do
            sysPOP( i );
        endfor;
        pop11_comp_stmnt_seq_to( "|>" ) -> _;
    else
        state.explode -> proglist_state;
        pop11_comp_stmnt_seq_to( "|>" ) -> _;
    endif;
    sysPUSHQ( sysENDPROCEDURE() );
enddefine;

endsection;
