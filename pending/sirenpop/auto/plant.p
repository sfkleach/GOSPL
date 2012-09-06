compile_mode :pop11 +strict;

section;

lconstant procedure do_plant =
    newproperty(
        maplist(
            [
                pop erase
                push pushs pushq
                call calls callq
                ifso ifnot goto label
            ],
            procedure( w ); lvars w;
                [% w, identof( "sys" <> lowertoupper( w ) ) %]
            endprocedure
        ),
        32, false, "perm"
    );

procedure( arg ); lvars arg;
    sysLVARS( arg, 0 )
endprocedure -> do_plant( "lvar" );

define global plant( L ); lvars L;
    if L.isvector then
        appdata( L, plant )
    else
        lvars t = L.dest -> L;
        lvars arg = L.null and undef or ( L.dest -> L );
        applist( L, plant );
        lvars p = do_plant( t );
        if p then
            applyval( arg, p )
        else
            mishap( 'CANNOT PLANT CODE FOR KEYWORD', [ ^t ] )
        endif
    endif
enddefine;

endsection
