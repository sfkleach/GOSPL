;;; What needs to be done here is
;;; 1. to extend the element type to include a deferred expression
;;; 2. use that extra type to do incremental reading
;;; 3. add a proper class_print procedure

compile_mode :pop11 +strict;

section;

;;; -- XML/HTML Datatype --------------------------------------

;;; This is used purely internally.  The name/value list is
;;; actually represented as a sorted list of Attributes.
;;;
defclass lconstant Attribute {
    attributeName,
    attributeValue
};


constant procedure (
    new_attribute   = consAttribute,
    is_attribute    = isAttribute,
    attribute_name  = attributeName,
    attribute_value = attributeValue
);


;;; We position the children at the end so that the idiom
;;;     e.destXmlElement.p
;;; works nicely.  In other words, after blowing all the bits
;;; onto the stack the vector-of-children is left nicely exposed
;;; on the top.
;;;
defclass lconstant XmlElement {
    xmlElementType,
    xmlElementAttributes,
    xmlElementChildren
};

;;; These abstraction breaking procedures are essential for the "baker"
;;; work.  However, they intimately link the code that uses it with the
;;; internal representation.
;;;
constant procedure (
    fast_element_attributes = class_fast_access( 2, XmlElement_key ),
    fast_element_children   = class_fast_access( 3, XmlElement_key )
);

define lconstant resort_attr_list( L );
    nc_listsort(
        L,
        procedure( x, y );
            alphabefore( attributeName( x ), attributeName( y ) )
        endprocedure
    )
enddefine;

define lconstant to_attr_list( L );
    [%
        until null( L ) do
            consAttribute( destpair( fast_destpair( L ) ) -> L )
        enduntil
    %].resort_attr_list
enddefine;

;;; This constructor has a variety of input formats - reflecting my
;;; own indecision about the best way to match it to a Pop11 idiom,
;;; to be honest.
;;;
;;; new_element( c1, ..., cN, N, t )
;;; new_element( c1, ..., cN, N, t, [ n1, v1, .., nM, vM ] )
;;; new_element( t, c1, ..., cN, N )
;;; new_element( t, [ n1, v1, .., nM, vM ], c1, ..., cN, N )
;;;
define new_element( t );
    lvars n, attrs;
    if t.isword then
        [] -> attrs;
        consvector() -> n;
    elseif t.islist then
        t -> attrs;
        () -> t;
        consvector() -> n;
    elseif t.isinteger then
        consvector( t ) -> n;
        () -> t;
        if t.isword then
            [] -> attrs
        elseif t.islist then
            t -> attrs;
            () -> t
        else
            mishap( 'Unexpected arguments for new_element', [ ^t ^n ] )
        endif
    else
        mishap( 'Invalid argument', [ ^t ] )
    endif;
    consXmlElement( t, attrs.to_attr_list, n )
enddefine;


;;; define new_element( n, type );
;;;     lvars attrs = [];
;;;     if type.islist then
;;;         ( n, type ) -> ( n, type, attrs )
;;;     endif;
;;;     consvector( n ) -> n;
;;;     consXmlElement(
;;;         type,
;;;         attrs.to_attr_list,
;;;         n
;;;     )
;;; enddefine;

define element_type =
    xmlElementType
enddefine;

define element_attributes( e );
    applist( xmlElementAttributes( e ), destAttribute )
enddefine;

define element_attributes_list( e );
    maplist( xmlElementAttributes( e ), destAttribute )
enddefine;

define element_value( name, e );
    lvars attrs = xmlElementAttributes( e );
    lvars i;
    for i in attrs do
        returnif( attributeName( i ) == name )( attributeValue( i ) )
    endfor;
    false
enddefine;

;;; This bizarre implementation is chosen because node COPYING is
;;; more common than updating attributes.  Therefore we copy on
;;; write, so to speak.  An improvement would be to add a dirty mark
;;; to nodes.  Not worth it at the moment.
;;;
define updaterof element_value( value, name, e );
    lvars attrs = xmlElementAttributes( e );
    [%
        if value then consAttribute( name, value ) endif;
        lvars i;
        for i in attrs do
            unless attributeName( i ) == name do
                i
            endunless
        endfor;
    %].resort_attr_list -> xmlElementAttributes( e )
enddefine;

;;; This loop provides the syntax
;;;     for name, value in_attributes element do ... endfor
;;; The fast variant is not used.
;;;
define :for_extension in_attributes( varlist, isfast );
    dlocal pop_new_lvar_list;

    ;;; This is a shortcoming that will be addressed at a later date.
    unless varlist.length == 2 do
        mishap( varlist, 1, 'Exactly 2 variables required for in_attributes' )
    endunless;

    lvars ( namev, valuev ) = varlist.dl;
    lvars attrlistv = sysNEW_LVAR();

    pop11_comp_expr_to( "do" ) -> _;
    sysCALLQ( xmlElementAttributes );
    sysPOP( attrlistv );

    lvars start_label = sysNEW_LABEL().dup.pop11_loop_start;
    lvars done_label = sysNEW_LABEL().dup.pop11_loop_end;

    sysLABEL( start_label );

    sysPUSH( attrlistv );
    sysPUSHQ( [] );
    sysCALL( "==" );
    sysIFSO( done_label );
    sysPUSH( attrlistv );
    sysCALL( "fast_destpair" );
    sysPOP( attrlistv );
    sysCALLQ( destAttribute );
    sysPOP( valuev );
    sysPOP( namev );

    pop11_comp_stmnt_seq_to( "endfor" ) -> _;

    sysGOTO( start_label );
    sysLABEL( done_label );
enddefine;


;;; This loop provides the syntax
;;;     for child in_children element do ... endfor
;;; The fast variant is not used.
;;;
define :for_extension in_children( varlist, isfast );
    dlocal pop_new_lvar_list;

    ;;; This is a shortcoming that will be addressed at a later date.
    unless varlist.length == 1 do
        mishap( varlist, 1, 'Only one variable allowed in in_children' )
    endunless;
    lvars lv = varlist( 1 );

    lvars v = sysNEW_LVAR();
    lvars i = sysNEW_LVAR();
    lvars n = sysNEW_LVAR();
    pop11_comp_expr_to( "do" ) -> _;
    lvars start_label = sysNEW_LABEL().dup.pop11_loop_start;
    lvars done_label = sysNEW_LABEL().dup.pop11_loop_end;

    sysCALLQ( xmlElementChildren );
    sysPOP( v );
    sysPUSH( v );
    sysCALL( "datalength" );
    sysPOP( n );
    sysPUSHQ( 0 );
    sysPOP( i );

    sysLABEL( start_label );

    sysPUSH( i );
    sysPUSHQ( 1 );
    sysCALL( "fi_+" );
    sysPUSHS( i );
    sysPOP( i );
    sysPUSH( n );
    sysCALL( "fi_<=" );
    sysIFNOT( done_label );

    sysPUSH( i );
    sysPUSH( v );
    ;;; sysCALL( "fast_subscrv" );
    sysFIELD( false, conspair( "full", _ ), false, false );
    sysPOP( lv );

    pop11_comp_stmnt_seq_to( "endfor" ) -> _;

    sysGOTO( start_label );
    sysLABEL( done_label );
enddefine;

define app_element_children( x, p );
    appdata( x.xmlElementChildren, p )
enddefine;

define map_element_children( x, p );
    consXmlElement(
        x.destXmlElement -> x,
        {% appdata( x, p ) %}
    )
enddefine;

define element_length( x );
    x.xmlElementChildren.datalength
enddefine;

define element_last( x );
    x.xmlElementChildren.last
enddefine;

define element_first( x );
    subscrv( 1, x.xmlElementChildren )
enddefine;

define subscr_element( n, x );
    subscrv( n, xmlElementChildren( x ) )
enddefine;

define updaterof subscr_element( v, n, x );
    v -> subscrv( n, xmlElementChildren( x ) )
enddefine;

define element_explode( x );
    x.xmlElementChildren.explode
enddefine;

define updaterof element_explode( x );
    -> x.xmlElementChildren.explode
enddefine;

define element_children( x );
    x.xmlElementChildren.explode
enddefine;

define element_children_list( x );
    x.xmlElementChildren.destvector.conslist
enddefine;

define element_children_dest( x );
    x.xmlElementChildren.destvector
enddefine;

define is_element =
    isXmlElement
enddefine;

;;; Note that you have to copy the vector of children.  This is
;;; highly undesirable.  What we what is a modified updater of
;;; subscr_element that marks elements as dirty.  If the element
;;; is clean then copying is simply copy(e).
;;;
define copy_element( e );
    consXmlElement( e.destXmlElement.copy )
enddefine;

define r_copy_element( e );
    if e.isXmlElement then
        lvars ( t, a, c ) = e.destXmlElement;
        consXmlElement( t, a, {% appdata( c, r_copy_element ) %} )
    else
        e
    endif
enddefine;

define nc_r_app_element_names( e, fc_type, fc_attr );
    lvars ( t, a, c ) = e.destXmlElement;
    fc_type( t ) -> e.xmlElementType;

    ;;; A minor "optimisation" which is probably worth it.
    unless fc_attr == identfn do
        lvars i;
        fast_for i in a do
            fc_attr( attributeName( i ) ) -> attributeName( i )
        endfor;
    endunless;

    lvars j;
    for j in_vector c do
        if j.isXmlElement do
            nc_r_app_element_names( j, fc_type, fc_attr )
        endif
    endfor;
enddefine;


;;; Usual disgusting hack to protect against defect in "uses".
vars xml_elements = true;


endsection;
