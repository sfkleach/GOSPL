compile_mode :pop11 +strict;

section $-better_syntax;

uses lfor

constant obsolete_for;

unless isundef( obsolete_for ) do
    mishap( 'This library must not be loaded twice', [ for_lvars ] )
endunless;

nonsyntax for -> obsolete_for;

define new_for();
    if pop11_try_nextreaditem( "lvars" ) then
        compileLfor( "endfor" )
    else
        obsolete_for()
    endif
enddefine;

endsection;

section;

sysunprotect( "for" );
syscancel( "for" );

ident_declare( "for", "syntax", 2:1 );    ;;; 2:1 = ordinary constant
better_syntax$-new_for -> idval( ident for );
sysGLOBAL( "for", true );

sysprotect( "for" );

endsection;
