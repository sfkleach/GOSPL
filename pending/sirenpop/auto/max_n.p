compile_mode :pop11 +strict;

section;

define max_n( N ) -> mx; lvars N, mx;
    -infinity -> mx;
    fast_repeat intof( N ) times
        max( (), mx ) -> mx
    endrepeat
enddefine;

endsection;
