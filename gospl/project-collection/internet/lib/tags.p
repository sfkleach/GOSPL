compile_mode :pop11 +strict;

uses def_typespec_predicate
uses isvector:typespec
uses isword:typespec

section;

define lconstant isvector_or_false( x );
    not( x ) or isvector( x )
enddefine;

def_typespec_predicate isvector_or_false;

defclass constant Tag {
    tagName         : isword,
    tagAttributes   : isvector,
    tagPayload      : isvector_or_false
};

define isElement( E );
    E.tagPayload and true
enddefine;

define updaterof isElement( flag, E );
    if flag then
        unless E.tagPayload do
            nullvector -> E.tagPayload
        endunless
    else
        false -> E.tagPayload
    endif
enddefine;

define tagCopy( E ) -> E;
    E.copy -> E;
    if E.tagPayload then
        mapdata( E.tagPayload, tagCopy ) -> E.tagPayload
    endif
enddefine;

define lconstant find( name, V );
    lvars n;
    for n from 1 by 2 to datalength( V ) do
        if subscrv( n, V ) == name then
            return( n + 1 )
        endif
    endfor;
    return( false )
enddefine;

define lconstant get( name, E );
    lvars V = E.tagAttributes;
    lvars n = find( name, V );
    n and subscrv( n, V )
enddefine;

define updaterof get( x, name, E );
    lvars V = E.tagAttributes;
    lvars n = find( name, V );
    if n then
        x -> subscrv( n, V )
    else
        { ^name ^x ^^V } -> E.tagAttributes
    endif
enddefine;

get -> class_apply( Tag_key );

define tagCont( E );
    E.tagPayload or nullvector
enddefine;

define updaterof tagCont( v, E );
    v -> E.tagPayload
enddefine;

define toTag( T );
    if T.islist then
        lvars ( name, rest ) = T.dest;
        {%
            while not( null( rest ) ) and hd( rest ).isvector do
                lvars nv = rest.dest -> rest;
                nv( 1 ), nv( 2 )
            endwhile
        %} -> lvar attrs;
        not( null( rest ) ) and {% applist( rest, toTag ) %} -> lvar payload;
        consTag( name, attrs, payload )
    else
        T
    endif
enddefine;

define appTagAttributes( t, procedure p );
    lvars attrs = t.tagAttributes;
    lvars n;
    for n from 2 by 2 to datalength( attrs ) do
        p( subscrv( n fi_- 1, attrs ), fast_subscrv( n, attrs ) )
    endfor
enddefine;

endsection;
