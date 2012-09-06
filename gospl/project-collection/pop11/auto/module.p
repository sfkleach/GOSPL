;;; Summary: enhanced syntax for section/endsection

compile_mode :pop11 +strict;
section;

uses pop11_comp_section;

sysunprotect( "endmodule" );
sysunprotect( "module" );

global vars syntax endmodule;
define global syntax module;
    pop11_comp_section( "endmodule" )
enddefine;

sysprotect( "endmodule" );
sysprotect( "module" );

#_IF identprops( "ved" ) /= "undef"
unless lmember( "module", vedopeners ) do
    [module ^^vedopeners] -> vedopeners;
    [endmodule ^^vedclosers] -> vedclosers;
endunless;
#_ENDIF

endsection;
