compile_mode :pop11 +strict;

section;

define new_simple_property( alist, gcflag, default );
    newanyproperty(
        alist, 8, 1, false,
        false, false, gcflag,
        default, false
    )
enddefine;

endsection;
