compile_mode :pop11 +strict;

section;

define syntax &_until;
    pop11_comp_expr_to( "do" ).erase;
    [ ; quitif(); ^^proglist ] -> proglist;
enddefine;

#_IF DEF vedbackers

unless member( "&_until", vedbackers ) do
    [ &_until ^^vedbackers ] -> vedbackers
endunless

#_ENDIF

endsection;
