compile_mode :pop11 +strict;
section;

;;; Make "uses" work.
vars extend_section = true;

uses pop11_comp_section;

sysunprotect( "section" );

define syntax section;
    pop11_comp_section( "endsection" )
enddefine;

sysprotect( "section" );

endsection;
