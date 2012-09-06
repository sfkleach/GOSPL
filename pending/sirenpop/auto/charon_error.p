compile_mode :pop11 +strict;

section;

define global charon_error( msg ); lvars msg;
    sprintf( msg ) -> msg;
    hip_error(
        sprintf(
            'PROGRAMMING ERROR\nPlease notify Steve Knight\nsfk@hplb.hpl.hp.com\nFault: %p',
            [ ^msg ]
        )
    );
    mishap( 'ABORTING AFTER PROGRAMMING ERROR', [] );
enddefine;

endsection;
