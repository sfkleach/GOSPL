;;; Summary:  multiplies top N items on stack

section;
define global vars procedure *_n( n ); lvars n;
    if fi_check( n, 0, false ) == 0 then
        1
    else
        fast_repeat n fi_- 1 times
            () * ()
        endrepeat
    endif
enddefine;
sysprotect( "*_n" );
endsection;
