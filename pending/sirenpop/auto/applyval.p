compile_mode :pop11 +strict;

section;

define global applyval( x ); lvars x;
    while x.isident do x.idval -> x endwhile;
    x()
enddefine;

endsection;
