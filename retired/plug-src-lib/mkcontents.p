;;; Creates the contents file.  Use as
;;;     pop11 mkcontents.p

define mkcontents( dir ); lvars dir, d;
    if readable( dir dir_>< 'README' ) ->> d then
        print_file( d );                ;;; print the file to stdout
        nl( 2 );                        ;;; 2 newlines
    endif;
    for f in_directory dir do       ;;; in_directory, in this archive
        if f.sysisdirectory then
            mkcontents( f )
        endif
    endfor;
enddefine;

procedure();
    dlocal cucharout = 'contents'.discout;
    mkcontents( '.' );
    cucharout( termin );
endprocedure();
