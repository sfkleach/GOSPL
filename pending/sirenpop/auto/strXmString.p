compile_mode :pop11 +strict;

section;

;;; Converts motif strings to Pop11 strings.
define global strXmString( xms ); lvars xms;
    defclass lconstant exptrvec :exptr;
    lconstant sptr = initexptrvec( 1 );
    if XmStringGetLtoR( xms, XmSTRING_DEFAULT_CHARSET, sptr ) then
        exacc_ntstring( fast_subscrexptrvec( 1, sptr ) )
    else
        mishap( 'TO BE DEFINED', [] )
    endif;
enddefine;

endsection;
