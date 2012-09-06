compile_mode :pop11 +strict;

section;

define global syntax xmn;
    lvars name = readitem();
    pop11_need_nextreaditem( "(" ).erase;
    pop11_comp_expr_to( ")" ).erase;
    sysPUSHQ( XtNLookup( name, "XmN" ) );
    XptPopValue -> pop_expr_item;
    sysCALLQ -> pop_expr_inst;
enddefine;

endsection
