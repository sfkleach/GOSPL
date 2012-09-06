;;; Summary: copy current window to preserve.tmp & then edit it

;;;                                                        A. Sloman June 1983

section;

;;; Copy current window to non-writeable file called 'preserve.tmp' and
;;; show it in other window. To keep part of current file visible while you
;;; move around it.

define ved_preserve();
    procedure();
        vars vvedmarklo vvedmarkhi ;
        vedlineoffset + 1 -> vvedmarklo;
        vedlineoffset + vedwindowlength - 1 -> vvedmarkhi;
        veddo('ved preserve.tmp');
        false -> vedwriteable;
        ved_clear();
        veddo('ti');
        vedlinedelete();
    endprocedure();
    vedswapfiles();
enddefine;

endsection;
