
;;; -- Scheme display function ----------------------------------------------

define display_scheme( s ); lvars s;
    if s.isstring do
        appdata( s, cucharout )
    else
        print( s );
    endif
enddefine;
