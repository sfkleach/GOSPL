compile_mode :pop11 +strict;

section;

define counter( n );
    procedure() with_props counter_proc;
        n;
        n + 1 -> n
    endprocedure
enddefine;

endsection;
