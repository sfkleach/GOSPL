compile_mode :pop11 +strict;

section;

lconstant procedure index =
    procedure( n ); lvars n;

        define lconstant get( v, n ); lvars v, n;
            subscrv( n, v )
        enddefine;

        define updaterof get( x, v, n ); lvars x, v, n;
             x -> subscrv( n, v )
        enddefine;

        get(% n %)
    endprocedure.memofn;

lconstant procedure conser =
    procedure( n ); lvars n;
        consvector(% n %)
    endprocedure.memofn;

define global syntax pseudoclass;

    lvars name = readitem().check_word;

    lvars fields =
        {%
            until pop11_try_nextreaditem( ";" ) do
                lvars id, field = readitem();
                if
                    field.isword and
                    (field.identprops ->> id) == undef or
                    id == 0
                then
                    field
                else
                    mishap( 'INVALID FIELD NAME', [^field] )
                endif;
            enduntil;
        %};
    [ ; ^^proglist ] -> proglist;

    lvars arity = fields.length;

    ;;; consNAME + destNAME
    sysGVAR( "cons" <> name );
    sysPASSIGN( conser( arity ), "cons" <> name );
    sysGVAR( "dest" <> name );
    sysPASSIGN( explode, "dest" <> name );

    ;;; fields.
    lvars f, n;
    for f with_index n in_vector fields do
        sysGVAR( f );
        sysPASSIGN( index( n ), f )
    endfor;
enddefine;

endsection
