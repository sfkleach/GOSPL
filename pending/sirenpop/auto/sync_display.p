section;

compile_mode :pop11 +strict;

XptLoadProcedures 'sync_display' lvars XSync;

define sync_display();
    exacc (2) raw_XSync( XptDefaultDisplay, 0 );
enddefine;

endsection;
