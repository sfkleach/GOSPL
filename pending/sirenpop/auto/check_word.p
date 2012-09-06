compile_mode :pop11 +strict;

section;

define global check_word( w ) -> w; lvars w;
    unless w.isword do
        mishap( 'WORD NEEDED', [ ^w ] )
    endunless
enddefine;

endsection
