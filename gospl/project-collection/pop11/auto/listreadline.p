;;; Summary: like readline, but gets nested lists

;;; lib listreadline
;;;
;;; jonathan laventhol, 13 December 1983
;;;
;;; works like readline, but will form nested lists. this was knocked up in
;;; too much of a hurry, and isn't very nice.  but i think it works, and makes
;;; use of readline so it sould work the same in ved.  if there is a nested
;;; list which doesn't have matching brackets it will return false.

section $-library => listreadline;

vars bad;   ;;; convert uses listreadline's local BAD as global

;;; convert from item repeater to a list.  sets flag if badly formed
;;;
define convert(p);
vars i;
    repeat forever
        p() -> i;
        if i == "["
        then  [% until (convert(p) ->> i) == "]"
                 do if i == termin then true -> bad; quitloop else i endif
                 enduntil %]
        elseif i == "]" or i == termin then return(i)
        else i
        endif
    endrepeat
enddefine;

;;; for making element repeaters from lists
;;;
define pdlist(ref);
    if  cont(ref) == nil
    then    termin
    else    dest(cont(ref)) -> cont(ref)
    endif
enddefine;

;;; like readline, but forms nested lists
;;;
define global listreadline();
vars bad x l;
    false -> bad;
    [% convert(pdlist(% consref(readline()) %) );
        unless (->> x) == termin then true -> bad endunless
    %] -> l;
    if bad then false else l endif
enddefine;

endsection; /* $-library */
