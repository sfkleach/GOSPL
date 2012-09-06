compile_mode :pop11 +strict;

define lconstant app_html_escape_char( ch, p );
    if ch fi_< 32 or ch fi_> 126 then
        lconstant hex = '0123456789ABCDEF';
        `&`.p,
        `#`.p,
        appdata( ch sys_>< '', p );
        `;`.p
    elseif ch == `<` then
        appdata( '&lt;', p )
    elseif ch == `>` then
        appdata( '&gt;', p )
    elseif ch == `&` then
        appdata( '&amp;', p )
    else
        p( ch )
    endif
enddefine;

define app_html_escape( s, p );
    if s.isinteger then
        app_html_escape_char( s, p )
    else
        lvars ch;
        for ch in_string s do
            app_html_escape_char( ch, p )
        endfor
    endif
enddefine;
