vars res_arg, res_arg_list;

define syntax !;
    lvars w = readitem();
    lvars s = w.isword and w.fast_word_string or w;
    sysPUSHQ( consword( uppertolower( s ) ) );
    "res_arg" -> pop_expr_item;
    sysCALL -> pop_expr_inst;
enddefine;
