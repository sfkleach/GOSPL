compile_mode :pop11 +strict;

section;

define load_style( procedure props );
    lconstant style = "style";
    repeat
        lvars styles = props( style );
        quitif( styles.null );
        [] -> props( style );

        lvars fname;
        for fname in styles do
            fast_appproperty(
                read_resource( ( $pophypstyle or $DOCUMENT_ROOT ) dir_>< fname, uppertolower ).erase,
                procedure( k, v );
                    props( k ) <> v -> props( k )
                endprocedure
            )
        endfor
    endrepeat
enddefine;

endsection;
