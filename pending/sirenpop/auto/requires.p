compile_mode :pop11 +strict;

section;

define global syntax requires;
    lvars modifier = readitem().check_word;

    define lconstant read_fname() -> name; lvars name;
        readitem() -> name;
        unless name.isstring or name.isword do
            mishap( 'LIBRARY OR FILE NAME NEEDED', [ ^name ] )
        endunless;
    enddefine;

    sysPUSHQ( read_fname() );
    if modifier == "library" then
        sysCALL( "useslib" );
    elseif modifier == "loading" then
        sysCALL( "loadcompiler" );
    else
        mishap( 'UNKNOWN FORM FOR REQUIRE', [ ^modifier ] )
    endif;
enddefine;

endsection
