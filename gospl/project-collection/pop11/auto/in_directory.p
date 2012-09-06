;;; Summary: for-extension for iterating over directories

/**************************************************************************\
Contributor                 Steve Knight, HP Labs.
Date                        14th Oct 1991
Description
    For-loop extension for iterating over the files of a directory.  I
    don't know what multiple variables would mean, so I've arbitrarily
    constrained them to 1.  This for-loop automatically declares its
    loop variable, too.
\**************************************************************************/

compile_mode :pop11 +strict;

section;

define :for_extension in_directory( varlist, isfast );
    lvars varlist, isfast;

    ;;; We want to temporarily allocate an lvars.
    dlocal pop_new_lvar_list;
    lvars dir = sysNEW_LVAR();

    ;;; Check there's only one loop variable and bind to -lv-
    unless varlist.length = 1 then
        mishap( 'Using in_directory with wrong number of loop variables', [^varlist] );
    endunless;
    lvars lv = varlist.hd;

    ;;; Automatically declares the loop variable.
    sysLVARS( lv, 0 );

    ;;; Allocate labels for the start and finish of the loop.
    lvars start = sysNEW_LABEL().dup.pop11_loop_start;
    lvars finish = sysNEW_LABEL().dup.pop11_loop_end;

    ;;; Generate a hidden list of all the files in the directory denoted
    ;;; by the immediately following expression.
    sysPUSH( "popstackmark" );
    pop11_comp_expr_to( "do" ).erase;
    sysCALL( "files_in_directory" );
    sysCALL( "sysconslist" );
    sysPOP( dir );

    sysLABEL( start );

    ;;; Check whether we've finished.  Note that this list is expanded.
    sysPUSH( dir );
    sysPUSHQ( [] );
    sysCALL( "==" );
    sysIFSO( finish );

    ;;; Get the next file from the list & put in LoopVariable lv.
    sysPUSH( dir );
    sysCALL( "sys_grbg_destpair" );
    sysPOP( dir );
    sysPOP( lv );

    ;;; Compile the loop body.
    pop11_comp_stmnt_seq_to( [ endfor endfast_for] ).erase;

    ;;; Go round again.
    sysGOTO( start );

    sysLABEL( finish );
enddefine;

endsection;
