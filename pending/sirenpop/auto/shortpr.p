compile_mode :pop11 +strict;

section;

define shortpr( x ); lvars x;
    cucharout( `<` );
    appdata( dataword( x ), cucharout );
    cucharout( `>` );
enddefine;

endsection;
