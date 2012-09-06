;;; Summary: print numbers as binary, hex, octal, and decimal

;;; For printing numbers in binary, octal and hex nicely.
;;; jonathan laventhol.

compile_mode:pop11 +strict;

section;

define pr_num_bin( num ); lvars num;
    lvars i, n;
    dlocal pop_pr_radix = 2;
    dlocal pop_pr_quotes = false;
    num >< nullstring -> n;
    consstring(#|
        repeat 32 - datalength( n ) times `0` endrepeat
    |#) >< n -> n;
    for i from 1 to 31 do
        cucharout( n( i ) );
        if i == 16 then
            syspr( '  ' )
        elseif i rem 4 == 0 then
            cucharout( `-` )
        endif
    endfor;
    cucharout( n( 32 ) );
    syspr( '  ' );
    16 -> pop_pr_radix;
    syspr( num ); syspr( ' h  ' );
    8 -> pop_pr_radix;
    syspr( num ); syspr( ' o  ' );
    10 -> pop_pr_radix;
    syspr( num ); syspr( ' d\n' )
enddefine;

sysprotect( "bin" );

endsection;

;;; -------------------------------------------------------------------------
;;; modified by sfk -- Mon Oct 14 15:37:29 BST 1991
;;;     Mainly modernisation & correction of minor errors.
;;;     *   use strict compile_mode
;;;     *   updated -vars- to -dlocal- for pop_pr_radix
;;;     *   made locals (i, n) into lvars
;;;     *   declared input-local (num) as lvars
;;;     *   dlocalised pop_pr_quotes because of the use of -><-
;;;     *   changed -vednullstring- to -nullstring-
;;;     *   inserted "optional" commas, to meet future modernisation, in
;;;         variable declarations
;;;     *   introduced count-brackets rather than the obsolete -cons_with-
;;;     *   made -bin- a protected vars procedure in top-section to meet
;;;         nasty autoloading requirements
;;;     *   revised layout to meet religious requirements
;;; -------------------------------------------------------------------------
