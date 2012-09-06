compile_mode :pop11 +strict;

section better_syntax => lwhile endlwhile luntil endluntil;

define lwhileCompile( sys_if, closer );
    lvars start_label = sysNEW_LABEL().dup.pop11_loop_start;
    lvars exit_label = sysNEW_LABEL().dup.pop11_loop_end;
    sysLABEL( start_label );
    pop11_comp_expr_to( "do" ).erase;
    sys_if( exit_label );
    sysLBLOCK( popexecute );
    closer.pop11_comp_stmnt_seq_to.erase;
    sysENDLBLOCK();
    sysGOTO( start_label );
    sysLABEL( exit_label );
enddefine;

vars syntax ( endlwhile, endluntil );

define global syntax lwhile;
    lwhileCompile( sysIFNOT, "endlwhile" )
enddefine;

define global syntax luntil;
    lwhileCompile( sysIFSO, "endluntil" )
enddefine;

endsection;
