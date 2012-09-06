;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Title       :   loading packages                                  ;;;
;;; Version     :   1                                                 ;;;
;;; Author      :   Steve Knight                                      ;;;
;;; Date        :   Tue May 16, 1989                                  ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section;

uses ved_src;

define lconstant add_dir( name, id ); lvars name, id;
    if readable( name ) then
        lvars d = current_directory dir_>< name;
        unless member( d, idval( id ) ) do
            d :: idval( id ) -> idval( id )
        endunless
    endif
enddefine;

lconstant setupfile = 'setup.p';

define vars procedure load_package( current_directory );
    dlocal current_directory;
    add_dir( 'auto',    ident popliblist );
    add_dir( 'auto',    ident popuseslist );
    add_dir( 'lib',     ident popuseslist );
    add_dir( 'src',     ident vedsrclist );
    add_dir( 'help',    ident vedhelplist );
    add_dir( 'doc',     ident veddoclist );
    add_dir( 'ref',     ident vedreflist );
    if readable( setupfile ) then
        compile( setupfile )
    endif;
enddefine;

endsection;
