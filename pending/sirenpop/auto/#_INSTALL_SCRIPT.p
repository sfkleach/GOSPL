
compile_mode :pop11 +strict;

section;

define global macro #_INSTALL_SCRIPT;
    lvars s = readitem();
    unless s.isstring do
        mishap( 'INVALID PRODUCTION NAME', [ ^s ] )
    endunless;
    hip_go_production( s );
    nextchar(% proglist.isdynamic %).destrepeater.consstring -> hip_system( "currentScene" )( "script" );
enddefine;

endsection;
