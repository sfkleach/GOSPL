compile_mode :pop11 +strict;

section;

define 2 x mod1 y -> ans; lvars ans, x, y;
    ( x mod y ) -> ans;
    if ans <= 0 then
        ans + y -> ans
    endif;
enddefine;

endsection;
