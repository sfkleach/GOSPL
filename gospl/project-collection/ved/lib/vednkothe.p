;;; Summary:  backspace key makes next key work in other file

;;; jonathan, june 1983.
;;; backspace key makes next key work in other file
;;; based on VEDPROCESSCHAR, but with a local VEDERROR to get you back in the
;;; file you started from, and complains if you press it twice in a row.
;;; -----

section $-ved_in_other_file => vedprocesschar_in_other_file;

define vedprocesschar_in_other_file();
vars ved_last_char item vederror;

/* errors land in right file */
    define vederror(message);
        chainfrom(vedprocesschar_in_other_file,
                  procedure;
                      vedswapfiles();
                      vedputmessage(message); vedscreenbell();
                  endprocedure(%message%))
    enddefine;

/* go to other file, right place on screen */
    vedswapfiles();
    vedcheck();
    vedsetcursor();

/* get a key, check it's not this proc */
    vedinascii() -> ved_last_char;
    while (vedgetproctable(ved_last_char) ->> item) == caller(0)
    do    vedputmessage('Already in other file');
          vedwiggle(vedline, vedcolumn);
          vedinascii() -> ved_last_char
    endwhile;

/* do the key, get back home */
    if isprocedure(item) then apply(item)
     elseif isstring(item) then conspair(item, ved_char_in_stream) -> ved_char_in_stream
    elseif item == undef then vedscreenbell()
    else vederror('UNRECOGNIZED KEY')
    endif;
    vedwiggle(vedline, vedcolumn);
    vedswapfiles();
enddefine;

/* put it in control-H (backspace) */
vedsetkey('\^H', vedprocesschar_in_other_file);     ;;; problem for LYMEs

section_cancel(current_section, true);
endsection;
