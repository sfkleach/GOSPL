compile_mode :pop11 +strict;

section;

define global sysGVAR( w ); lvars w;
    sysSYNTAX( w, "procedure", false );
    sysGLOBAL( w );
enddefine;

endsection
