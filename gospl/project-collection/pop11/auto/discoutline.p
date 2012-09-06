;;; Summary: like discout but works on whole strings

compile_mode :pop11 +strict;

section;

define discoutline( file ); lvars file;
    lvars procedure d = discout( file );
    procedure( str ); lvars str;
        if str == termin then
            d( termin )
        else
            appdata( str, d );
            d( `\n` );
        endif
    endprocedure
enddefine;

endsection;
