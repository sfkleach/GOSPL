;;; Summary: merge current & previous then delete current file

/*
LIB VED_MERGEFILE

A program for merging the current file in VED with the previous one you
were looking at, including deleting the former from the disc, if
necessary.

Invoke this as

    ENTER mergefile

The file you are in will be appended to the previous file, leaving the
VED cursor at the junction point. The original file is deleted from VED
and (if necessary) from the disc.
*/

section;

define vars procedure ved_mergefile();
    ;;; Mark and copy the current file into vveddump
    ved_mbe();
    ved_copy();

    ;;; Go to end of other file and yank in the copy
    vedswapfiles();
    if vedonstatus then vedswitchstatus() endif;    ;;; prevent it going
                                                    ;;; into status file
    vedendfile();
    ved_y();

    ;;; Go back to original and delete it
    vedswapfiles();
    ved_deletefile()
    ;;; You'll be left in the merged file.
enddefine;

endsection;
