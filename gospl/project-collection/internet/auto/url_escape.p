compile_mode :pop11 +strict;

define url_escape( s ); lvars s;
    if s.isinteger then
        if s.isalphacode or s.isnumbercode then
            s
        elseif 0 fi_<= s and s fi_< 256 then
            lconstant hex = '0123456789ABCDEF';
            `%`,
            fast_subscrs( s fi_>> 4 fi_+ 1, hex ),
            fast_subscrs( s fi_&& 2:1111 fi_+ 1, hex )
        else
            mishap( 'Character code needed', [ ^s ] )
        endif
    else
        consstring(#| appdata( s, url_escape ) |#)
    endif
enddefine;
