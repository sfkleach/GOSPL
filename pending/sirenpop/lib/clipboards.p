;;; --
;;; Clipboards are an imperative implementation of bags.
;;; --

compile_mode :pop11 +strict;

section;

defclass lconstant CB {
    CBtable     : full,     ;;; property.
    CBequality  : full      ;;; typically =, ==#, or ==
};

define lconstant get_table( cb ) -> t; lvars cb, t;
    CBtable( cb ) -> t;
    unless t do
        lvars eq = CBequality( cb );
        newanyproperty(
            [], 8, 1, false,            ;;; automatically resizes
            if eq == nonop == or not( eq ) then
                false, false, "perm"    ;;; permanent & ==
            else
                syshash, eq, "perm"     ;;; permanent & user =
            endif,
            0, false                    ;;; default 0
        ) ->> t -> CBtable( cb );
    endunless;
enddefine;

define lconstant multi_add_clipboard( n, x, c ); lvars n, x, c;
    lvars t = c.get_table;
    if n.isintegral then
        lvars k = n + t( x );
        if k >= 0 then
            k -> t( x );
        endif;
    else
        mishap( 'INTEGRAL VALUE NEEDED', [^n] )
    endif;
enddefine;

define global new_clipboard( assoc_list, eq ) -> cb; lvars assoc_list, eq, cb;
    consCB( 0, false, eq ) -> cb;
    lvars i;
    for i in assoc_list do
        multi_add_clipboard( i(2), i(1), cb )
    endfor;
enddefine;

;;; This is a new-ish kind of define statement (see HELP *DEFINE_FORM).
;;; It changes the -pdprops- of -isCB- to "is_clipboard" which is what
;;; I want.
;;;
define global is_clipboard =
    isCB
enddefine;

define global del_clipboard( x, c ); lvars x, c;
    multi_add_clipboard( -1, x, c )
enddefine;

define global add_clipboard( x, c ); lvars x, c;
    multi_add_clipboard( 1, x, c )
enddefine;

define global on_clipboard( x, c ); lvars x, c;
    lvars t = c.CBtable;
    t and t( x ) or 0
enddefine;

define updaterof on_clipboard( n, x, c ); lvars n, x, c;
    multi_add_clipboard( n - get_table( c )( x ), x, c )
enddefine;

define app_clipboard( c, p ); lvars c, p;
    lvars t = c.CBtable;
    if t then
        appproperty( t, p )
    endif;
enddefine;

define global length_clipboard( cb ); lvars cb;
    lvars t = cb.CBtable;
    if t then
        lvars total = 0;
        fast_appproperty(
            t,
            procedure( item, count ); lvars item, count;
                count + total -> total
            endprocedure
        );
        total
    else
        0
    endif;
enddefine;

endsection;
