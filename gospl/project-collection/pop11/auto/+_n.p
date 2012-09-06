;;; Summary: adds top N items on stack
;;; Sums the first n stack values
section;
define global vars procedure +_n( n ); lvars n;
    if fi_check( n, 0, false ) == 0 then
        0
    else
        fast_repeat n fi_- 1 times
            () + ()
        endrepeat
    endif
enddefine;
sysprotect( "+_n" );
endsection;
