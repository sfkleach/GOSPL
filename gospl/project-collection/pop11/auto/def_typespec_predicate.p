compile_mode :pop11 +strict;

section;

define global syntax def_typespec_predicate;
    lvars w = readitem();
    lvars name = w <> "':typespec'";
    if pop11_try_nextreaditem( "=" ) then
        pop11_comp_expr()
    else
        sysPUSH( w );
    endif;
    procedure( procedure p );
        lvars ts = identfn(% %);
        procedure( x ) -> x;
            unless p( x ) do
                mishap( x, 1, 'TYPESPEC FAILED (' sys_>< w sys_>< ')' )
            endunless
        endprocedure -> updater( ts );
        conspair( true, ts(% "full", true %) )
    endprocedure.sysCALLQ;
    sysCONSTANT( name, 0 );
    sysGLOBAL( name );
    sysPOP( name );
enddefine;

endsection;
