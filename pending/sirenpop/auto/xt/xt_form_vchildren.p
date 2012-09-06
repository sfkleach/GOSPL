compile_mode :pop11 +strict;

section;

define global xt_form_vchildren( N ); lvars N;
    returnif( N <= 0 );

    lvars V = consvector( N );
    xt_set_values(
        V( 1 ),
        { leftAttachment ^XmATTACH_FORM },
        { rightAttachment ^XmATTACH_FORM },
        { topAttachment ^XmATTACH_FORM }
    );
    lvars i;
    for i from 2 to N do
        xt_set_values(
            V( i ),
            { leftAttachment ^XmATTACH_FORM },
            { rightAttachment ^XmATTACH_FORM },
            { topAttachment ^XmATTACH_WIDGET },
            { topWidget % V( i - 1 ) %}
        );
    endfor;
    xt_set_values(
        V( N ),
        { bottomAttachment ^XmATTACH_FORM }
    );
enddefine;

endsection
