compile_mode :pop11 +strict;

section kers_syntax;

constant As = [ as = ; ];

define issyntax( props );
    props.isword and isstartstring( "syntax", props )
enddefine;

define issane( x );
    ;;; Ensure that x is a sensible name for a variable - ie: a word that
    ;;; is not declared -syntax-
    x.isword and x.identprops.issyntax.not
enddefine;

define checksane( x );
    ;;; Ensure that x is a sensible name for a variable - ie: a word that
    ;;; is not declared -syntax-
    if x.issane then x else mishap( 'unsuitable for identifier', [^x] ) endif
enddefine;

define checkat( anyof );
    lvars it = readitem();
    unless lmember( it, anyof ) do
        mishap( 'punctuator expected', [got ^it wanted one of ^anyof] )
    endunless
enddefine;

define lconstant isQualifier( x ); lvars x;
    lmember( x, #_< [lconstant lvar dlocal constant] >_# )
enddefine;

define declare_arg( x ); lvars x;
    if x.islist then
        x.dest.dest.hd -> lvar type -> lvar name -> lvar kind;
        if kind == "dlocal" then
            sysLOCAL( name );
            sysPOP( name )
        elseif kind == "procedure" then
            sysLVARS( name, "procedure" );
            sysPOP( name )
        elseif kind == "lvars" then
            sysLVARS( name, 0 );
            sysPOP( name );
        else
            mishap( 'inappropriate qualifier on argument', x )
        endif
    else
        sysLVARS( x, 0 );
        sysPOP( x )
    endif
enddefine;

define readArg();
    lvars qual =
        if proglist.hd.isQualifier then proglist.dest -> proglist
        else false
        endif;
    lvars name =
        readitem().checksane;
    lvars type =
        if proglist.hd == ":" then
            proglist.tl -> proglist;
            if proglist.hd.isQualifier then
                proglist.dest -> proglist -> lvar q;
                if qual and qual /== q then
                    mishap
                        (
                        'inconsistent qualifiers',
                        [% qual, "vs", q, "for", name %]
                        )
                else
                    q -> qual
                endif
            endif;
            if proglist.hd.issane then
                proglist.dest -> proglist
            else
                false
            endif
        else
            false
        endif;
    if qual or type then
        [% qual or "lvars", name, type or "any" %]
    else
        name
    endif
enddefine;

define read_arg_sequence( stopat ); lvars stopat;
    [%
    until proglist.hd == stopat or proglist.hd.issane.not do
        readArg();
        if proglist.hd == "," then proglist.tl -> proglist endif
    enduntil
    %];
    unless proglist.hd == stopat do
        mishap( 'illegal item in argument list', [% proglist.hd %] )
    endunless;
    proglist.tl -> proglist
enddefine;

define readargs();
    ;;; Reads an argument list, checking that sensible words are used
    if proglist.hd == "(" then
        proglist.tl -> proglist;
        read_arg_sequence( ")" );
    else
        []
    endif
enddefine;

endsection;
