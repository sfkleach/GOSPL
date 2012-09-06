compile_mode :pop11 +strict;

section;

lvars string_to_term_err_mess = nil;

define global active string_to_term_error;
    lconstant tag = 'READING: ';
    lvars s = string_to_term_err_mess.ncrev.destlist.consstring;
    lvars n = issubstring( tag, 1, s );
    if n then
        lvars k = n + length( tag );
        substring( k, s.length - k, s )
    else
        s
    endif
enddefine;

define global string_to_term( str ); lvars str;
    dlocal proglist = str.stringin.incharitem.pdtolist;
    lvars error = false;
    lvars errtext = [];
    lvars term;
    [%
        procedure();

            define dlocal interrupt();
                true -> error;
                exitto( string_to_term );
            enddefine;

            define dlocal cucharerr( ch ); lvars ch;
                ch :: errtext -> errtext;
            enddefine;

            prolog_readterm_to( termin ) -> term;
        endprocedure();
    %].erase;
    errtext -> string_to_term_err_mess;
    return( not( error ) and term )
enddefine;

endsection
