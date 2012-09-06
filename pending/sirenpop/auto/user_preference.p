;;; User preferences code.

compile_mode :pop11 +strict;

section;

uses popdbm;
uses dbm_core;

defclass lconstant preference {
    property : full
};

property <> apply -> class_apply( preference_key );

define global user_preference( file ); lvars file;
    lvars dbm = dbm_open( file, true );
    unless dbm do
        sysgarbage();                   ;;; Try to reclaim some file pointers.
        dbm_open( file, true ) -> dbm;  ;;; Attempt to open it again.
    endunless;
    unless dbm do
        mishap( 'CANNOT OPEN DBM FILE ' sys_>< sysiomessage(), [ ^file ] )
    endunless;
    conspreference( dbm_property( dbm, false, false ) )
enddefine;

endsection;
