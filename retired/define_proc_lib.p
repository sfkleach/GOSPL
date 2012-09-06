compile_mode :pop11 +strict;

uses $-kers_syntax$-useful_syntax;
uses define_var;
uses call_syntax;

section $-kers_syntax =>
    define_proc
    define_proc_full_pdprops
;

;;; true -> arg names go into pdprops, false -> they don't
global vars define_proc_full_pdprops = true;

define lconstant parseOperand();
    if proglist.hd.issane then [% readArg() %] else [] endif
enddefine;

define lconstant operand_name( operand ); lvars operand;
    lvars it = operand.hd;
    if it.isword then it else 2.it endif
enddefine;

define lconstant makeProc( e ); lvars e;
    e
enddefine;

define lconstant makeUpdate( v, e ); lvars v, e;
    [% "upd", v, e %]
enddefine;

define lconstant parseExpr();
    lvars e = parseOperand();
    lvars tok = (proglist.dest -> proglist);
    if tok == "." then
        [% "app", parseOperand(), e %]
    elseif tok == "@" then
        parseOperand() -> lvar F;
        parseOperand() -> lvar R;
        [% "app", F, e <> R %]
    elseif tok == "(" then
        tok :: proglist -> proglist;
        [% "app", e, readargs() %]
    elseif tok == "$" then
        lvars args = e;
        consword( #|
            repeat
                `$`, destword( proglist.dest -> proglist ), erase();
                parseOperand() <> args -> args;
                quitunless( proglist.hd == "$" );
                proglist.tl -> proglist
            endrepeat
            |# ) -> lvar F;
        [% "app", F, args.rev %]
    else
        unless tok == "->" do
            mishap( 'illegal procedure header', [% e.hd, "as" %] );
        endunless;
        tok :: proglist -> proglist;
        e
    endif;
enddefine;

define lconstant parse_a_procdef();
    lvars X = parseExpr();
    if proglist.hd == "->" then
        proglist.tl -> proglist;
        makeUpdate( X, parseExpr() )
    else
        X.makeProc
    endif
enddefine;

define lconstant procdef_untangle( pd ); lvars pd;
    if pd.hd == "upd" then
        ;;; [upd Arg App]
        2.pd <> 3.(3.pd), 2.(3.pd), sysUPASSIGN
        ;;; dest_call( 3.pd, [% 2.pd %] ), sysUPASSIGN
    else
        3.pd, 2.pd, sysPASSIGN
    endif
enddefine;

define :define_form global proc;
    lvars d = parse_a_procdef();
    d.procdef_untangle -> lvar assign -> lvar proc_operand -> lvar args;
    lvars procname = proc_operand.operand_name;
    As.checkat;
    (if popexecute then sysVARS else sysLCONSTANT endif)( procname, "procedure" );
    sysPROCEDURE( procname, args.length );
    applist( args.rev, declare_arg );
    "enddefine".pop11_comp_stmnt_seq_to.erase;
    sysLABEL( "return" );
    assign( sysENDPROCEDURE(), procname )
enddefine;

endsection;
