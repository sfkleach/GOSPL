compile_mode :pop11 +strict;

section;

uses buffered_consumers;

define on_mishap_relocate( URL );
    new_buffered_consumer( cucharout ) -> cucharout;

    procedure( _ ) with_props relocating_prmishap;
        clear_buffered_consumer( cucharout );
        nprintf( 'Location: %p\r\n\r\n', [ ^URL ] );
        cucharout( termin )
    endprocedure -> prmishap;
enddefine;

endsection;
