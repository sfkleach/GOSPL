compile_mode :pop11 +strict;

uses $-kers_syntax$-useful_syntax;

section kers_syntax;

define doDefine_name( how );
    ;;; define :[const|var] Name as Exprs enddefine;
    lvars name = readitem().checksane;
    As.checkat;
    pop11_comp_stmnt_seq_to( "enddefine" ).erase;
    how( name, 0 );
    sysPOP( name );
enddefine;

endsection;
