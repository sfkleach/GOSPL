;;; Summary: Randomly chooses one of N items on the stack and erases the rest.
;;; Version: 1.0

compile_mode :pop11 +strict;

section;

define oneof_n( n ) -> r;
    subscr_stack( random( n ) ) -> r;
    erasenum( n );
enddefine;

endsection;
