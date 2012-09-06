;;; Summary: like -lib- but uses -vedsrclist-

;;; -- Allows the use of VEDSRCLIST as an alternative library list

compile_mode:pop11 +strict;

section;

uses ved_src;

define lconstant do_libsrc( name ); lvars name;
    nprintf( ';;; LOADING SRC %p', [^name] );
    unless syslibcompile( name, vedsrclist ) then
        mishap( 'LIBRARY FILE NOT FOUND', [^name] )
    endunless;
enddefine;

define global syntax libsrc;
    dlocal popnewline = true;
    sysPUSHQ( rdstringto([; ^termin ^newline]) );
    sysCALLQ( do_libsrc );
    [; ^^proglist] -> proglist;
enddefine;

endsection;
