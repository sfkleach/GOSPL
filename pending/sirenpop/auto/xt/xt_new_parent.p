compile_mode :pop11 +strict;

section;

define global xt_new_parent() -> ( name, parent ); lvars name, parent;
    lvars x = ();
    if x.isstring then
        () -> parent;
        x -> name
    else
        x -> parent;
        'widget' -> name;
    endif
enddefine;

endsection
