compile_mode :pop11 +strict;

section better_syntax =>
    lif endlif
    lunless endlunless
    elselif lelselunless
    ;

lconstant td_keywords = [ then do ];
lconstant ee_keywords = [ else elseif elselif elseunless elselunless endlif endlunless ];

define lifCompile( sys_if, closer );
    lvars exit_label = sysNEW_LABEL();

    ;;; At the moment of call, proglist is poised at the start of
    ;;; a conditional expression.
    define doLif( sys_if );
        lvars next_label = sysNEW_LABEL();
        pop11_comp_expr_to( td_keywords ).erase;
        sys_if( next_label );
        sysLBLOCK( popexecute );
        lvars tok = pop11_comp_stmnt_seq_to( ee_keywords );
        sysENDLBLOCK();
        unless tok == closer then
            sysGOTO( exit_label );
        endunless;
        sysLABEL( next_label );
        if tok == "else" or tok == "lelse" then
            sysLBLOCK( popexecute );
            pop11_comp_stmnt_seq_to( closer ).erase;
            sysENDLBLOCK();
        elseif tok == "elseif" or tok == "elselif" then
            doLif( sysIFNOT )
        elseif tok == "elseunless" or tok == "elselunless" then
            doLif( sysIFSO )
        endif
    enddefine;

    doLif( sys_if );
    sysLABEL( exit_label );
enddefine;

vars syntax ( endlif, endlunless, elselif, elselunless );

define global syntax lif;
    lifCompile( sysIFNOT, "endlif" )
enddefine;

define global syntax lunless;
    lifCompile( sysIFSO, "endlunless" )
enddefine;

endsection;
