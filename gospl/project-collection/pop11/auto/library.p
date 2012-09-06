;;; Summary: a simple module control facility for code development

;;;
;;;     library - simple module control for system development
;;;
;;; library provides the facility whereby a module can be loaded from
;;; a library, preference begin given to a set of "development" libraries
;;; over a set of "system" libraries
;;;
;;;
;;; Commands:
;;;
;;;     library cancel all;                     Removes all libraries
;;;
;;;     library cancel 'dua0:[xxx.yy]';         The specified library
;;;                                             directory is removed.
;;;
;;;     library extension '.x';                 Sets the default extension
;;;                                             for library modules to '.x'
;;;                                             (if a module name is a word,
;;;                                             the default extension is
;;;                                             appended before it is looked
;;;                                             up)
;;;
;;;     library system 'mta0:[fred.jim]';       Adds this library directory
;;;                                             to the front of the system
;;;                                             library search list. If it
;;;                                             is already in this search
;;;                                             list it is removed.
;;;
;;;     library 'dba1:[jkl.jkl.dsss]';          Adds this library directory
;;;                                             to the front of the development
;;;                                             library search list. If it
;;;                                             is already in this search
;;;                                             list it is removed.
;;;
;;;     library load fred;                      Looks for module "fred.x".
;;;                                             (See below)
;;;
;;; The search strategy is as follows:
;;;
;;;     1. Look in each library in the development library search list
;;;
;;;     2. Look in each library in the system library search list
;;;
;;;     3. If not found, howl with anguish.
;;;
;;; The first readable file of the form:
;;;
;;;     <library-directory><module-name><default-extension>
;;;
;;; is loaded. If the <module-name> is a string rather than a word,
;;; the default extension is not appended.
;;;
;;;
;;; Mike Bell 21-Aug-84.
;;;



section $-library => library;


vars library_sysliblist,library_devliblist,library_defextension;

define global macro library;
    lvars w1,w2, x, fname;

    if isundef(library_sysliblist) then
        nil -> library_sysliblist;
        nil -> library_devliblist;
        '.p' -> library_defextension;
    endif;

    readitem() -> w1;

    unless isword(w1) then
        w1 -> w2;
        "development" -> w1;
    else
        readitem() -> w2;
    endunless;

    if (w1 == "load") and isword(w2) then
        w2 >< library_defextension -> w2;
    endif;

    unless isstring(w2) or isstring(valof(w2)) or member( w1, [cancel] ) then
        mishap( 'library', w1, w2, 3, 'Error in library statement' );
    endunless;

    if w1/="cancel" and not(isstring(w2))
    then
        valof(w2) -> w2;
    endif;


    if w1 == "system" then
        delete( w2, library_sysliblist ) -> library_sysliblist;
        w2 :: library_sysliblist -> library_sysliblist;
        pr( ';;; New system library: ' >< w2 >< newline );
    elseif w1 == "development" then
        delete( w2, library_devliblist ) -> library_devliblist;
        w2 :: library_devliblist -> library_devliblist;
        pr( ';;; New development library: ' >< w2 >< newline );
    elseif w1 == "extension" then
        w2 -> library_defextension;
        pr( ';;; New library extension ' >< w2 >< newline );
    elseif w1 == "cancel" then
        if w2 == "all" then
            nil -> library_sysliblist;
            nil -> library_devliblist;
            pr( ';;; All libraries cancelled\n' );
        else
            delete( w2, library_sysliblist ) -> library_sysliblist;
            delete( w2, library_devliblist ) -> library_devliblist;
            pr( ';;; library ' >< w2 >< ' cancelled\n' );
        endif;
    elseif w1 == "load" then
        for x in library_devliblist do
            x >< w2 -> fname;
            if readable( fname ) then
                dl( [
                        pr( ';;; Loading ' >< ^w2 >< ' from library ' ><
                            ^x >< newline );
                        compile( ^fname );
                        ] );
                return;
            endif;
        endfor;
        for x in library_sysliblist do
            x >< w2 -> fname;
            if readable( fname ) then
                dl( [
                        pr( ';;; Loading ' >< ^w2 >< ' from system library '
                            >< ^x >< newline );
                        compile( ^fname );
                        ] );
                return;
            endif;
        endfor;
        mishap( 'library', w1, w2, 3, 'Unable to find file' );
    else
        mishap( 'library', w1, w2, 3, 'Error in library statement' );
    endif;
enddefine;

endsection; ;;; $-library
