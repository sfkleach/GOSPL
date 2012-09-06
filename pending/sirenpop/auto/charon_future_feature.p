compile_mode :pop11 +strict;

section;

define global charon_future_feature( msg ); lvars msg;
    sprintf( msg ) -> msg;
    hip_information( 'This feature is not available yet\nRe: ' sys_>< msg );
enddefine;

endsection;
