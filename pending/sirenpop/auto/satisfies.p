compile_mode :pop11 +strict;

section;

define satisfies( x, preds ); lvars x, preds;
    until null( preds ) do
        returnunless( apply( x, dest( preds ) -> preds ) )( false )
    enduntil;
    return( true );
enddefine;

endsection;
