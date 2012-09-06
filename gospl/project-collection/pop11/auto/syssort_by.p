compile_mode :pop11 +strict;

section;

define global syssort_by( /*list[+ncflag],*/ p, c ) with_nargs 3; dlvars procedure p, procedure c;
    define lconstant procedure cmp( x, y ); lvars x, y;
        c( p( x ), p( y ) )
    enddefine;

    syssort( /* list[+ncflag], */ cmp )
enddefine;

endsection;
