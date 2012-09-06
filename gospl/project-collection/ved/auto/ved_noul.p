;;; Summary: no underlines - strip nroff underlines out of text

compile_mode :pop11 +strict;

section;


;;; ved_noul
;;; for cleaning up underlining
;;; jonathan laventhol, 23 september 1983.

define ved_noul();
vars vedargument;
    '/_\^H//' -> vedargument;
    ved_sgs();
enddefine;

endsection;
