compile_mode :pop11 +strict;

section;

define notImplemented( what );
    mishap( 'Oops, not implemented', [ ^what ] )
enddefine;

endsection;
