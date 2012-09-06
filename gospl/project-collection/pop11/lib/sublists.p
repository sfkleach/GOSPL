;;; Summary: returns the list of all sublists of a list

;;; Aaron Sloman                                Feb 1984
;;; A program which, when given a list, returns a list of all sub-lists,
;;; including the original and the empty list.

;;; The empty list has only one sublist, itself.
;;; So sublists([]) = [[]]

;;; A list of one element [a] has two sublists [[a] []]

;;; A list of two elements [a b] has four sublists
;;;     [[a b] [a] [b] []]

;;; We can make all the sublists for a given list L as follows.
;;; Call Lt the tail of L. Assume we can get all the sublists for Lt, in a
;;; list call Lts. E.g. if L is [a b], then Lt is [b] and Lts is [[b] []]
;;;
;;; So Lts contains sublists of L involving all but the first element of L,
;;; which we can call L1. So we need to get new subsets of L, by adding
;;; L1 to all the elements of Lts. But we also need to keep all the elements
;;; of Lts, since they are also subsets of L.
;;; So, given
;;;         L   = [a b c]
;;;         Lt  = [b c]
;;;         Lts = [[b c] [b] [c] []]
;;;         L1  = "a"
;;;         Lts elements combined with "a"
;;;             = [[a b c] [a b] [a c] [a]]
;;;         Add the original elements of Lts, and we get
;;;               [[a b c] [a b] [a c] [a] [b c] [b] [c] []]
;;;
;;; Notice that as a new element is added to a list, the size of the
;;; list of sublists doubles, i.e. the new list includes all the originals
;;; plus new copies with one more element added. So for a list of N elements
;;; the list of sublists will have 2 to the power N elements.
;;;

section $-library => sublists;

define global procedure sublists(list);
    vars lts sublist x;
    if list = [] then
        [[]]
    else
        sublists(tl(list)) -> lts;
        hd(list) -> x;
        [
            %for sublist in lts do  ;;; copy elements of lts with x in front
                [^x ^^sublist]
            endfor%
            ^^lts                   ;;; insert elements of lts
        ]
    endif
enddefine;
endsection;
