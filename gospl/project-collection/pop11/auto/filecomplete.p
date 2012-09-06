;;; Summary: completes filenames (used by lib vedfnc)

compile_mode :pop11 +strict;

section;

define filecomplete( name ); lvars name;
    lvars f = sysfileok( name ), len = length( f );
    lvars r = sys_file_match( f sys_>< '*', '', false, false );
    procedure();
        if r then
            lvars filename = r();
            if filename == termin then
                termin;
                false -> r
            else
                lvars l = datalength( filename );
                if l == len then
                    ''
                else
                    substring( len + 1, l - len, filename )
                endif
            endif
        else
            termin
        endif
    endprocedure.pdtolist
enddefine;

endsection;
