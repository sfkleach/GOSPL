;;; Summary: log all help requests to a file

;;; local lib helplog.  see *HELPLOG                    *** UNIX ONLY ***
;;; Jonathan Laventhol, 8 Oct 1984.

;;; this is a cheap and cheerful demonstration of how to use vedsysfilelog

;;; a library to record all help (teach, doc ...) file requests.
;;; the log file names are made from a prefix, the date, and
;;; the process number.  this makes sure they will be unique.
;;; the directory is got from environment variable $HELPLOGDIR
;;;     (default is $usepop/pop/local/spool/helplogs)
;;; the prefix is got from environement variable $HELPLOGGROUP
;;;     (default is 'H')

section ved => vedsysfilelog;

;;; where to put the log files.
;;;
constant HELPLOGDIR;
    if systranslate('$HELPLOGDIR') then
        systranslate('$HELPLOGDIR')
    else
        '$usepop/pop/local/spool/helplogs'
    endif -> HELPLOGDIR;

;;; check that it exists, as a directory
;;;
unless readable(HELPLOGDIR dir_>< '.') then
    mishap(HELPLOGDIR, 1, 'don\'t know where to put help logging')
endunless;

;;; prefix for log file
;;;
constant HELPLOGGROUP;
    if systranslate('$HELPLOGGROUP') then
        systranslate('$HELPLOGGROUP')
    else
        'H'
    endif -> HELPLOGGROUP;

;;; character consumer for log file
;;;
vars vedsysfilelogpdr;

HELPLOGDIR dir_>< HELPLOGGROUP >< sys_real_time() >< '.' >< poppid
         -> vedsysfilelogpdr;

discout(vedsysfilelogpdr) -> vedsysfilelogpdr;

;;; the logging procedure
;;; writes the time too
;;; the name is the last thing, so that it is readable
;;; caller_name filename timestamp request
;;;
define global procedure vedsysfilelog(cllr, request, found);
lvars request cllr found;
vars cucharout pop_pr_quotes pop_pr_radix pop_pr_exponent;
    false ->> pop_pr_quotes -> pop_pr_exponent; ;;; ARG! ensure normal printing
    10 -> pop_pr_radix;
    vedsysfilelogpdr -> cucharout;
    sys_syspr(cllr); cucharout(` `);
    sys_syspr(if found then found else 0 endif); cucharout(` `);
    sys_syspr(sys_real_time()); cucharout(` `);
    sys_syspr(request);
    cucharout(`\n`);
enddefine;

endsection;
