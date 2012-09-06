compile_mode :pop11 +strict;

section;

defclass lconstant histogram {
    histogram_pop       : full,
    histogram_attr      : full,
    histogram_buckets   : full
};

define new_histogram( pop, attr ); lvars pop, attr;
    if pop.isvector then
        conshistogram(
            syssort_by(
                [%
                    lvars i;
                    for i in_vector pop do
                        if i.attr.isreal then
                            i
                        endif
                    endfor
                %],
                false,
                attr,
                nonop <=
            ).destlist.consvector,
            attr,
            []
        )
    else
        mishap( 'VECTOR NEEDED', [ ^pop ] )
    endif
enddefine;

define histogram_population =
    histogram_pop
enddefine;

define histogram_population_size =
    histogram_pop <> length
enddefine;

define histogram_attribute =
    histogram_attr
enddefine;

define histogram_length( H ); lvars H;
    H.histogram_buckets.length
enddefine;

define histogram_limits( H ) -> ( minimum, maximum ); lvars H, minimum, maximum;
    lvars procedure attr = histogram_attr( H );
    infinity -> minimum;
    -infinity -> maximum;
    lvars p = H.histogram_pop;
    lvars b;
    for b in_vector p do
        lvars n = attr( b );
        min( n, minimum ) -> minimum;
        max( n, maximum ) -> maximum;
    endfor;
enddefine;

;;; -------------------------------------------------------------------------

defclass lconstant bucket {
    b_min       : full,   ;;; TechFair, sfk.  Coercion problem workaround.
    b_max       : full,   ;;; ditto
    b_name      : full,
    b_members   : full
};

define bucket_name =
    b_name
enddefine;

define bucket_limits( B ); lvars B;
    b_min( B ), b_max( B )
enddefine;

define lconstant getv_buckets( H ); lvars H;
    lvars b = H.histogram_buckets;
    if b.isvector then
        b
    else
        syssort_by( b, false, b_min, nonop <= ).destlist.consvector
            ->> H.histogram_buckets
    endif
enddefine;

define lconstant getl_buckets( H ); lvars H;
    lvars b = H.histogram_buckets;
    if b.isvector then
        b.destvector.conslist -> H.histogram_buckets
    else
        b
    endif
enddefine;

define subscr_histogram( n, H ); lvars n, H;
    subscrv( n, H.getv_buckets )
enddefine;

subscr_histogram -> class_apply( histogram_key );

define bucket_members( B ); lvars B;
    lvars m = B.b_members;
    if m.isvector then
        m
    else
        m();
        B.b_members
    endif;
enddefine;

define lconstant fill_buckets( H ); lvars H;
    lvars buckets = getv_buckets( H );

    lvars b;
    for b in_vector buckets do
        [] -> b_members( b )
    endfor;

    lvars len = histogram_length( H );
    lvars procedure attr = histogram_attr( H );
    lvars index = 1;
    lvars i;
    for i in_vector H.histogram_pop do
        quitif( index > len );
        lvars a = attr( i );
        lvars k;
        for k from index to len do
            lvars b = subscrv( k, buckets );
            quitif( b.b_min > a );
            ;;; nprintf( 'Compare %p < %p -> %p', [% b.b_max, a, b.b_max < a %] );
            if b.b_max < a then
                k + 1 -> index
            else
                conspair( i, b.b_members ) -> b.b_members
            endif;
        endfor;
    endfor;

    lvars b;
    for b in_vector buckets do
        b.b_members.destlist.consvector -> b_members( b )
    endfor;
enddefine;

define make_bucket( name, mn, mx, H ) -> B; lvars name, mn, mx, H, B;
    consbucket(
        mn,
        mx,
        name,
        fill_buckets(% H %)
    ) -> B;
    B :: getl_buckets( H ) -> H.histogram_buckets;
enddefine;

define filter_histogram( H, pred ); lvars H, procedure pred;
    lvars buckets = getv_buckets( H );
    conshistogram(
        H.histogram_pop,
        H.histogram_attr,
        {%
            lvars b;
            for b in_vector buckets do
                consbucket(
                    b.bucket_limits,
                    b.b_name,
                    {%
                        lvars item;
                        for item in_vector b.bucket_members do
                            if pred( item ) then
                                item
                            endif;
                        endfor
                    %}
                )
            endfor
        %}
    )
enddefine;

define histogram_bucket_sizes( H ); lvars H;
    appdata(
        getv_buckets( H ),
        procedure( b ); lvars b;
            length( b.bucket_members )
        endprocedure
    )
enddefine;

define histogram_max_bucket_size( H ); lvars H;
    max_n(#| histogram_bucket_sizes( H ) |# )
enddefine;

define histogram_pick_bucket( x, H ); lvars H, x;
    lvars i;
    for i from 1 to histogram_length( H ) do
        lvars B = subscr_histogram( i, H );
        lvars ( mn, mx ) = bucket_limits( B );
        returnif( mn <= x and x <= mx )( B )
    endfor;
    return( false )
enddefine;

endsection;
