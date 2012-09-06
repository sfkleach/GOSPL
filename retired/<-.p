compile_mode :pop11 +strict;

section;

define lconstant is_normal_id( x ); lvars x;
    x.isword and x.identprops == 0
enddefine;

define lconstant compile_primitive();
    if proglist.hd.isword then (proglist.dest -> proglist).valof.apply
    else sysPUSHQ( proglist.dest -> proglist )
    endif
enddefine;

define syntax 1 <-;
    dlocal pop_new_lvar_list;
    lvars object_name =
        if pop_expr_inst == sysPUSH then
            pop_expr_item
        elseif pop_expr_inst == pop11_EMPTY then
            "self"
        else
            lvars x = sysNEW_LVAR();
            pop_expr_item.pop_expr_inst;
            sysPOP( x );
            x
        endif;
    lvars method_name =
        if proglist.hd.is_normal_id then
            proglist.dest -> proglist
        else
            lvars x = sysNEW_LVAR();
            compile_primitive();
            sysPOP( x );
            x
        endif;
    if proglist.hd == "(" then
        proglist.tl -> proglist;
        ")".pop11_comp_expr_seq_to.erase
    endif;
    sysPUSH( object_name );
    method_name -> pop_expr_item;
    sysCALL -> pop_expr_inst
enddefine;

endsection;
