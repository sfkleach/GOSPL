;;; -- Pushable repeaters ---------------------------------------------------

;;; constant destPushable = explode;
;;;
;;; define lconstant canpush( cr, ref ); lvars cr, ref;
;;;     if fast_cont( ref ) do
;;;         fast_cont( ref );
;;;         false -> fast_cont( ref )
;;;     else
;;;         cr()
;;;     endif;
;;; enddefine;
;;;
;;; define updaterof canpush( v, cr, ref ); lvars v, ref, cr;
;;;     if fast_cont( ref ) do
;;;         mishap( 'Too many pushbacks', [^v] )
;;;     else
;;;         v -> fast_cont( ref );
;;;     endif
;;; enddefine;
;;;
;;; define newPushable(cr); lvars cr;
;;;     canpush(% cr, consref( false ) %)
;;; enddefine;
;;;
;;; define isPushable( x ); lvars x;
;;;     x.isclosure and pdpart( x ) == canpush
;;; enddefine;
;;;

define lconstant canpush(r, p); lvars r, p;
    if fast_front(p) == 0 do
        r()
    else
        lvars n = fast_front(p);
        n fi_- 1 -> fast_front(p);
        fast_subscrv( n, fast_back(p) );
    endif;
enddefine;

define updaterof canpush(v, r, p); lvars v, r, p;
    lvars l = datalength(fast_back(p));
    if fast_front(p) == l do
        move_subvector(1, fast_back(p), 1, initv(l + 2) ->> fast_back(p), l)
    endif;
    v -> fast_subscrv( fast_front(p) fi_+ 1 ->> fast_front(p), fast_back(p) )
enddefine;

define newPushable(r); lvars r;
    canpush(% r, conspair(0, initv(2)) %)
enddefine;

define emptyPushable( r ); lvars r;
    front( frozval( 1, r ) ) == 0
enddefine;

define isPushable(x); lvars x;
    x.isclosure and pdpart(x) == canpush
enddefine;
