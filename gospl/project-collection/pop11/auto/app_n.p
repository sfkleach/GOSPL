;;; Summary: iterate over a counted group

section;

define global procedure app_n( n, p ); lvars n, procedure p;
    lvars L = conslist( n );
    until L == [] do
        p( fast_destpair( L ) -> L )
    enduntil;
enddefine;

endsection;
