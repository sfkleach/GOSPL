compile_mode :pop11 +strict;

uses xml_elements

section $-xml =>
    new_xml_repeater
;


;;; Given a stream of XML tokens it returns a stream of XML objects.
define new_xml_repeater( procedure tokeniser );

    define xmltokens();
        lvars tok = tokeniser();
        if tok.isStartTag then
            lvars type = tok.startTagTypeName;
            new_element(
                #|
                    repeat
                        lvars t = xmltokens();
                        if t == termin then
                            mishap( type, 1, 'Unexpected end of input while reading element' )
                        elseif t.isEndTag then
                            lvars etype = t.endTagTypeName;
                            unless etype == type then
                                mishap( type, t, 2, 'Unexpected end tag found while reading element' )
                            endunless;
                            quitloop
                        else
                            t
                        endif
                    endrepeat
                |#,
                type,
                tok.startTagAttributes
            )
        else
            tok
        endif
    enddefine;

    xmltokens
enddefine;

endsection;
