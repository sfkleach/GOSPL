compile_mode :pop11 +strict;

section;

define global xt_new_args() -> ( name, parent, arglist, managed ); lvars name, parent, arglist, managed;
    unless dup().isboolean do
        true
    endunless -> managed;
    xt_new_arglist() -> arglist;
    xt_new_parent() -> ( name, parent );
enddefine;

endsection
