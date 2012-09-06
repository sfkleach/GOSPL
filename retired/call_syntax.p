compile_mode :pop11 +strict;

section;

uses @
uses <-

;;; ------------------------------------------------------------------
;;; |   Deprecated because of clash with SFK's $ syntax for          |
;;; |   accessing environment variables.                             |
;;; ------------------------------------------------------------------
;;; define syntax $;
;;;     procedure();
;;;         dlocal pop_expr_update = false;
;;;         lvars parts = [$];
;;;         repeat
;;;             readitem() :: parts -> parts;
;;;             quitunless( pop11_comp_prec_expr( 200, false ) == "$" );
;;;             proglist.tl -> proglist;
;;;             "$" :: parts -> parts;
;;;         endrepeat;
;;;         parts
;;;     endprocedure() -> lvar parts;
;;;     applist( '', parts.ncrev, nonop >< ).consword -> pop_expr_item;
;;;     sysCALL -> pop_expr_inst
;;; enddefine;

endsection;
