;;; Install the PLUG archive search paths.

section;

;;; Self-locating.  Eliminates need for $popplug.
lvars plugdir = sys_fname_path( popfilename );

lvars helpdir   = plugdir dir_>< 'pop/help/';
lvars pop11dir  = plugdir dir_>< 'pop/pop11/';
lvars inetdir   = plugdir dir_>< 'pop/internet';

extend_searchlist( pop11dir dir_>< 'include', popincludelist ) -> popincludelist;
extend_searchlist( inetdir dir_>< 'include', popincludelist ) -> popincludelist;
extend_searchlist( pop11dir dir_>< 'auto/', popautolist ) -> popautolist;
extend_searchlist( inetdir dir_>< 'auto', popautolist ) -> popautolist;
extend_searchlist( pop11dir dir_>< 'auto/typespecs', popautolist ) -> popautolist;
extend_searchlist( pop11dir dir_>< 'lib/', popuseslist ) -> popuseslist;
extend_searchlist( inetdir dir_>< 'lib', popuseslist ) -> popuseslist;

;;; VED stuff.
#_IF DEF vededit
    lvars veddir = plugdir dir_>< 'pop/ved/';
    extend_searchlist( veddir dir_>< 'auto/', popautolist ) -> popautolist;
    extend_searchlist( veddir dir_>< 'lib/', popuseslist ) -> popuseslist;

    extend_searchlist( [[% helpdir % help ]], vedhelplist ) ->  vedhelplist;
    extend_searchlist( [[% veddir dir_>< 'help' % help ]], vedhelplist ) ->  vedhelplist;
    extend_searchlist( [[% pop11dir dir_>< 'help' % help ]], vedhelplist ) ->  vedhelplist;
    extend_searchlist( [[% inetdir dir_>< 'help' % help ]], vedhelplist ) -> vedhelplist;
    extend_searchlist( [[% pop11dir dir_>< 'ref' % ref ]], vedhelplist, true ) ->  vedhelplist;
    extend_searchlist( [[% inetdir dir_>< 'ref' % ref ]], vedhelplist, true ) -> vedhelplist;

    extend_searchlist( [[% pop11dir dir_>< 'ref' % ref ]], vedreflist ) ->  vedreflist;
    extend_searchlist( [[% inetdir dir_>< 'ref' % ref ]], vedreflist ) -> vedreflist;
    extend_searchlist( [[% helpdir % help ]], vedreflist, true ) ->  vedreflist;
    extend_searchlist( [[% veddir dir_>< 'help' % help ]], vedreflist, true ) ->  vedreflist;
    extend_searchlist( [[% pop11dir dir_>< 'help' % help ]], vedreflist, true ) ->  vedreflist;
    extend_searchlist( [[% inetdir dir_>< 'help' % help ]], vedreflist, true ) -> vedreflist;
#_ENDIF;


;;; Extend prolog search paths.  This isn't the right way -- the prolog system
;;; does something clever with extend_help, but what?

#_IF is_subsystem_loaded( "prolog" )

lvars lib = plugdir dir_>< 'pop/plog/lib';
unless member( lib, prologliblist ) do
    lib :: prologliblist -> prologliblist;
endunless;

lvars help = [% plugdir dir_>< 'pop/plog/help' % help ];
unless member( help, vedhelplist ) do
    help :: vedhelplist -> vedhelplist;
endunless;

#_ENDIF

vars plug_archive = true;

endsection;
