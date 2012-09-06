;;; UNIX Utilities.  This is a collection of miscellaneous utilities
;;; that makes writing UNIX programs much easier.

compile_mode :pop11 +strict;

section;

define syntax $;
    lvars item = readitem() sys_>< nullstring;
    sysPUSHQ( item );
    sysCALL -> pop_expr_inst;
    "systranslate" -> pop_expr_item;
enddefine;

endsection;
