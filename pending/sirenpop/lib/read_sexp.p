compile_mode :pop11 +strict;

section $-ReadSexp =>
    read_sexp
    discin_sexps
    string_to_sexps
;

;;; Compensate for a bug in -strnumber- in version 14.2 of POPLOG.
define safe_strnumber( s ); lvars s;
    define dlocal prmishap( x ); lvars x;
        if x.islist then
            erase()
        elseif x.isstring then
            erasenum()
        endif;
        exitfrom( false, safe_strnumber )
    enddefine;

    strnumber( s )
enddefine;

define lconstant incharlispitem( cr ); lvars cr;

    lconstant
        alphabetic = 1,
        numeric    = 2,
        separator  = 5,
        whitespace = 6,
        charquote  = 7;

    lvars ir = incharitem( cr );
    lvars ch;
    for ch from 0 to 255 do
        lvars ct = item_chartype( ch, ir );
        unless ct == whitespace do
            alphabetic -> item_chartype( ch, ir )
        endunless;
    endfor;
    lvars ch;
    for ch in_string '()' do
        separator -> item_chartype( ch, ir )
    endfor;
    charquote -> item_chartype( `"`, ir );

    procedure( ir ); lvars procedure ir;
        lvars item = ir();
        item /== termin and safe_strnumber( item ) or item
    endprocedure(% ir %)
enddefine;

define global read_sexp( ir ); lvars ir;
    lvars sexp = ir();
    if sexp == "(" then
        [%
            repeat
                lvars item = read_sexp( ir );
            quitif( item == ")" );
                item
            endrepeat
        %]
    else
        sexp
    endif
enddefine;

define global discin_sexps( fname ); lvars fname;
    read_sexp(% fname.discin.incharlispitem %).pdtolist
enddefine;

define global string_to_sexps( s ); lvars s;
    read_sexp(% s.stringin.incharlispitem %).pdtolist
enddefine;

endsection;
