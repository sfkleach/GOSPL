;;; Summary: compile-time brackets <# #>, <## ##>, <#| |#>

/**************************************************************************\
Contributor                 Steve Knight, HP Labs.
Date                        22nd Jan 1992
Description
    Three kinds of compile-time evaluation brackets.  Posted to pop-forum
    on the same day.
\**************************************************************************/

compile_mode :pop11 +strict;

section;

define lconstant get_literals( closer ); lvars closer;
    {%
        sysEXEC_COMPILE(
            procedure();
                pop11_comp_stmnt_seq_to( closer ).erase;
            endprocedure,
            false
        )
    %}
enddefine;

;;; get=one-item brackets
global vars syntax #> ;
define global syntax <# ;
    lvars literals = get_literals( "#>" );
    returnif( pop_syntax_only );
    lvars len = literals.datalength;
    if len == 0 then
        mishap( 'No values returned from compile-time expression', [] )
    elseif len > 1 then
        mishap( 'More than one value returned from compile-time expression', [] )
    endif;
    sysPUSHQ( literals( 1 ) );
enddefine;

;;; get-many-items-brackets
global vars syntax ##> ;
define global syntax <## ;
    appdata( get_literals( "##>" ), sysPUSHQ );
enddefine;

;;; get-counted-items brackets
global vars syntax |#> ;
define global syntax <#| ;
    lvars literals = get_literals( "|#>" );
    appdata( literals, sysPUSHQ );
    sysPUSHQ( literals.datalength );
enddefine;

endsection;
