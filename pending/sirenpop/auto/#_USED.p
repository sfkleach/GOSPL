;;; This macro can be used to declare a variable at top-level.  It's
;;; purpose is to act as a placeholder for declaring variables of the
;;; same name as a library file.

compile_mode :pop11 +strict;

section;

define macro #_USED;
    lvars w = readitem();
    [section; global vars ^w = true; endsection;].dl
enddefine;

endsection;
