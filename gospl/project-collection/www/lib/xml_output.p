;;; -- Rendering XML/HTML items -------------------------------

compile_mode :pop11 +strict;

section;

uses html_predicates;

constant procedure ( render_xml_item, render_html_item );

;;; WRONG! Must protect quotes!!
define lconstant print =
    pr
enddefine;

define lconstant renderAnyTag( t, e, start );
    appdata( start, cucharout );
    appdata( t, cucharout );
    if e then
        lvars name, value;
        for name, value in_attributes e do
            cucharout( ` ` );
            appdata( name, cucharout );
            cucharout( `=` );
            cucharout( `"` );
            print( value );
            cucharout( `"` );
        endfor
    endif;
    cucharout( `>` );
enddefine;

define lconstant renderTag( t, e );
    renderAnyTag( t, e, '<' )
enddefine;

define lconstant renderEndTag( t );
    renderAnyTag( t, false, '</' )
enddefine;

define lconstant renderXmlElement( e );
    lvars t = e.element_type;
    if t.is_empty_typename then
        renderTag( t, e )
    else
        renderTag( t, e );
        app_element_children( e, render_xml_item );
        renderEndTag( t );
    endif
enddefine;

define lconstant renderHtmlElement( e );
    lvars t = e.element_type;
    renderTag( t, e );
    app_element_children( e, render_html_item );
    renderEndTag( t );
enddefine;

define render_xml_item( x );
    if x.is_element then
        renderXmlElement( x )
    else
        print( x )
    endif
enddefine;

define render_html_item( x );
    if x.is_element then
        renderHtmlElement( x )
    else
        print( x )
    endif
enddefine;

endsection;
