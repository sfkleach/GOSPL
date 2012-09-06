;;; Summary: explicitly load a GOSPL-style project directory


compile_mode :pop11 +strict;

section;

;;; DANGER - this is dependent on VED being present.
;;; declares vedsrclist!
#_IF DEF vedprocess
    uses ved_src;
#_ENDIF

define lconstant add_dir( name, id ); lvars name, id;
    if readable( name ) then
        extend_searchlist(
            current_directory dir_>< name,
            idval( id )
        ) -> idval( id )
    endif
enddefine;

lconstant setupfile = 'init.p';

define sys_load_project( d );
    if sysisdirectory( d ) then
        dlocal current_directory = d;
        add_dir( 'auto',    ident popautolist );
        add_dir( 'include', ident popincludelist );
        add_dir( 'lib',     ident popuseslist );
	#_IF DEF vedprocess
	if testdef ved then
            add_dir( 'src',     ident vedsrclist );
            add_dir( 'help',    ident vedhelplist );
            add_dir( 'doc',     ident veddoclist );
            add_dir( 'ref',     ident vedreflist );
        endif;
        #_ENDIF
        if readable( setupfile ) then
            compile( setupfile )
        endif;
    elseif sys_file_exists( d ) then
        ;;; Ordinary file so use self-homing.  Would be nice if
        ;;; we could resolve symlinks here - but there seems no
        ;;; guaranteed way round it.
        sys_load_project( sys_fname_path( d ) )
    else
        mishap( 'Project directory does not exist', [ ^d ] )
    endif
enddefine;

endsection;
