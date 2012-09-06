;;; Summary: like -uses- but uses -vedsrclist-

;;; -- Allows the use of VEDSRCLIST as an alternative library list

compile_mode:pop11 +strict;

section;

uses ved_src;   ;;; autoload vedsrclist

define lconstant do_usessrc( name ); lvars name;
    unless syslibcompile( name, vedsrclist ) then
        mishap( 'LIBRARY FILE NOT FOUND', [^name] )
    endunless;
enddefine;

define global syntax usessrc;
    dlocal popnewline = true;
    sysPUSHQ( rdstringto([; ^termin ^newline]) );
    sysCALLQ( do_usessrc );
    [; ^^proglist] -> proglist;
enddefine;

endsection;
