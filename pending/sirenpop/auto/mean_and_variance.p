compile_mode :pop11 +strict;

section;

define global mean_and_variance( n ) -> ( m, vr ); lvars n, m, vr;
    dlocal popdprecision = true;
    lvars total = 0.0d0;
    lvars sqrtotal = 0.0d0;
    repeat n times
        dup() + total -> total;
        sqr() + sqrtotal -> sqrtotal;
    endrepeat;
    total / number_coerce( n, 0.0d0 ) -> m;
    max( 0, sqrtotal / n - sqr( m ) ) -> vr;
enddefine;

endsection;
