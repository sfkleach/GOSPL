;;; Summary: show all keys bindings in a ved buffer

;;; ved_show_keys.p                             R.J.Popplestone Spring 91

/*
This file may be reproduced freely.  It creates a ved-buffer containing
all the current key-bindings occurring in VED.
*/


section $-ved_show_keys => ved_show_keys;

;;; ( This code looks dubious in the EXTREME - Steve Knight )
vars procedure name_key =
    [
        ['\^[?A'  'up_arrow   ']
        ['\^[?B'  'down_arrow ']
        ['\^[?C'  'right_arrow']
        ['\^[?D'  'left_arrow ']
        ['\^[?M'  'enter      ']
        ['\^[?Q'  'pf2        ']
        ['\^[?R'  'pf3        ']
        ['\^[[11'  'f1        ']
    ].assoc;

vars procedure (
  show_table,
  pr_str,
)
;

;;; Special variable.  (added by Steve Knight to accord with today's style.)
vars L_as_is;

define ved_show_keys();
    lvars W_file = systmpfile( false, 'keys', '.tmp' );
    dlocal cucharout = discout(W_file);
    nl(1);
    npr('VED key bindings - <false> means anonymous procedure.');
    npr('Keys which insert themselves are listed separately.');
    nl(2);
    npr('Key-Sequence  Binding');
    dlocal L_as_is = [];
    show_table('',vednormaltable);
    npr('\nInserted as is'); applist(L_as_is.rev,pr);
    nl(1);
    cucharout(termin);
    vedselect(W_file);
enddefine;


;;; Reformatted 22/11/92 by Steve Knight.
define show_table( str, T ); lvars str, T;
    if     T = vedinsertvedchar then str :: L_as_is -> L_as_is;
    elseif T = undef then   /* nothing */
    elseif isword(T) then show_table(str,T.valof)
    elseif isprocedure(T) then pr_str(str); sp(6); npr(T.pdprops);
    elseif isstring(T) then pr_str(str); sp(6); npr(T);
    elseif isnumber(T) then pr_str(str); sp(6); npr(consstring(T,1));
    else
        lvars i;
        for i from 1 to T.datalength do
            show_table(str<>consstring(i,1),T(i));
        endfor
    endif
enddefine;

define pr_str( str ); lvars str;
    lvars n = str.datalength;
    lvars str_name = name_key(str);
    if str_name then pr(str_name); else sp(4); endif;

    lvars i;
    for i from 1 to n do
        lvars c = subscrs(i,str);
        if c < ` ` then pr( '^' );
            cucharout( 64 + c );
        elseif c == `\` then
            cucharout(c);
            cucharout(c);
        else
            cucharout(c)
        endif
    endfor;
enddefine

/*
show_table('\^A',vednormaltable(1));
pr(datalist('\^A'));
show_table('\^[',vednormaltable(27));

*/
endsection;
