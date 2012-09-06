compile_mode :pop11 +strict;

section;

;;; This makes compiling this file idempotent i.e. further recompilations
;;; have no effect.
#_IF not( DEF sys_load_project )

lvars
    home    = sys_fname_path( popfilename ),
    src     = home dir_>< 'src';

compile( src dir_>< 'sys_uses_project_collection.p' );
compile( src dir_>< 'sys_load_project.p' );
compile( src dir_>< 'sys_uses_project.p' );
compile( src dir_>< 'uses_project.p' );

;;; Now make "root" appear to be a normally loaded project.
sys_load_project( home );

#_ENDIF

endsection
