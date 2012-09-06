;;; Summary: delete the current file from the disc and VED

/*
LIB VED_DELETEFILE

Here's a little program to delete the current file not only from
the VED buffer but also from the disc. (It doesn't delete backup
versions, however, in case you want them to recover from a mistake.)

Invoke this as

    ENTER deletefile
To delete the current file.

*/

section;

define vars procedure ved_deletefile();
    ;;; Ensure that backup versions are not unbacked up by
    ;;; sysdelete
    dlocal
        pop_file_versions = false,
        vedversions = false;

    ;;; Delete current file from the disc
    if sysdelete(vedpathname) then
        vedputmessage('DELETED');
    endif;

    ;;; Remove it from VED
    false -> vedwriteable;
    ved_q();
enddefine;

endsection;
