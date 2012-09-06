compile_mode :pop11 +strict;

section;

define global syntax scene_var;

    define lconstant make_getter( default ); lvars default;
        lvars procedure table =
            newanyproperty(
                [], 4, 1, false,
                false, false, "tmparg",
                default, false
            );

        define lconstant get();
            table( hip_system( "currentScene" ) )
        enddefine;

        define updaterof get( x ); lvars x;
            x -> table( hip_system( "currentScene" ) )
        enddefine;

        return( get )
    enddefine;

    lvars v = readitem();
    unless v.isword then
        mishap( 'VARIABLE NAME NEEDED', [ ^v ] )
    endunless;

    sysVARS( v, conspair( 0, 1 ) );
    if pop11_try_nextreaditem( "=" ) then
        pop11_comp_expr();
    else
        sysPUSHQ( undef )
    endif;
    sysCALLQ( make_getter );
    sysPOP( conspair( v, "nonactive" ) );
enddefine;

endsection;
