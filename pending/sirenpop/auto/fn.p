compile_mode :pop11 +strict;

section;

global vars syntax endfn;

define global syntax fn;
    lvars args =
        [%
            until pop11_try_nextreaditem( "|" ) do
                lvars it = readitem();
                if it.isword then
                    unless it == "," do
                        it
                    endunless
                else
                    mishap( 'UNEXPECTED INPUT LOCAL', [ ^it ] )
                endif
            enduntil
        %];
    sysPROCEDURE( "fn", args.length );
    applist( args, sysLVARS(% 0 %) );
    applist( rev( args ), sysPOP );
    pop11_comp_stmnt_seq_to( "endfn" ).erase;
    sysLABEL( "return" );
    sysPUSHQ -> pop_expr_inst;
    sysENDPROCEDURE() -> pop_expr_item;
enddefine;

endsection;
