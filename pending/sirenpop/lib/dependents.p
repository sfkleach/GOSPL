compile_mode :pop11 +strict;

section;

;;; Table which maps between items and their dependents.  Dependents are
;;; stored as lists of items.
;;;
lconstant procedure dtable =
    newanyproperty(
        [], 8,  1, false,           ;;; automatically resizes
        false, false, "tmparg",     ;;; temporary property
        [], false                   ;;; default nil
    );

define global add_dependent( d, item ); lvars d, item;
    lvars ds = dtable( item );
    unless lmember( d, ds ) do
        d :: ds -> dtable( item )
    endunless
enddefine;

define global del_dependent( d, item ); lvars d, item;
    delete( d, dtable( item ), nonop == ) -> dtable( item )
enddefine;

define global is_dependent( d, item ); lvars d, item;
    lmember( d, dtable( item ) ) and true
enddefine;

define updaterof is_dependent( flag, d, item ); lvars flag, d, item;
    if flag then
        add_dependent
    else
        del_dependent
    endif( d, item )
enddefine;

define global app_dependents( item, p ); lvars item, p;
    applist( dtable( item ), p )
enddefine;

define global notify_dependents( item ); lvars item;
    app_dependents( item, apply )
enddefine;

;;; Declare this variable in order that "uses" will work.
global vars dependents;

endsection;
