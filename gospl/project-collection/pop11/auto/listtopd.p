;;; Summary: converts a list to an item repeater

/**************************************************************************\
Contributor                 Steve Knight
Date                        17 Oct 91
Description
    Converts a list into an item repeater.
\**************************************************************************/

compile_mode :pop11 +strict;

section;

define listtopd( L ) -> R;

    lvars seen_termin = false;

    procedure();
        if null( L ) then
            if seen_termin then
                mishap( 'listtopd: repeater exhausted', [] )
            else
                true -> seen_termin;
                termin;
            endif
        else
            fast_destpair( L ) -> L
        endif
    endprocedure -> R;

    procedure() with_nargs 1;
        conspair( /* item */, L ) -> L
    endprocedure -> updater( R );

enddefine;

endsection;
