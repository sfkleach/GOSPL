compile_mode :pop11 +strict;

section;

define syntax &_while;
    pop11_comp_expr_to( "do" ).erase;
    [ ; quitunless(); ^^proglist ] -> proglist;
enddefine;

#_IF DEF vedbackers

unless member( "&_until", vedbackers ) do
    [ &_until ^^vedbackers ] -> vedbackers
endunless

#_ENDIF
endsection;
