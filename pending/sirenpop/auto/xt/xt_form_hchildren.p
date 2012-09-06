compile_mode :pop11 +strict;

section;

define global xt_form_hchildren( N ); lvars N;
    returnif( N <= 0 );

    lvars V = consvector( N );
    xt_set_values(
        V( 1 ),
        { topAttachment ^XmATTACH_FORM },
        { bottomAttachment ^XmATTACH_FORM },
        { leftAttachment ^XmATTACH_FORM }
    );
    lvars i;
    for i from 2 to N do
        xt_set_values(
            V( i ),
            { topAttachment ^XmATTACH_FORM },
            { bottomAttachment ^XmATTACH_FORM },
            { leftAttachment ^XmATTACH_WIDGET },
            { leftWidget % V( i - 1 ) %}
        );
    endfor;
    xt_set_values(
        V( N ),
        { rightAttachment ^XmATTACH_FORM }
    );
enddefine;

endsection
