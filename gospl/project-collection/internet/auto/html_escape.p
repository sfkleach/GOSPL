compile_mode :pop11 +strict;

define html_escape( s ); lvars s;
    dlocal cucharout = identfn;
    dlocal pop_pr_radix = 10;
    if s.isinteger then
        if s.isalphacode or s.isnumbercode then
            s
        elseif s == `<` then
            '&lt;'.explode
        elseif s == `>` then
            '&gt;'.explode
        elseif s == `&` then
            '&amp;'.explode
        elseif 0 fi_<= s and s fi_< 256 then
            lconstant hex = '0123456789ABCDEF';
            `&`,
            `#`,
            pr( s );
            `;`
        else
            mishap( 'Character code needed', [ ^s ] )
        endif
    else
        consstring(#| appdata( s, html_escape ) |#)
    endif
enddefine;
