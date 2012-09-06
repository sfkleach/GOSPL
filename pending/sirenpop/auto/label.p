compile_mode :pop11 +strict;

section;

define global syntax label;
    lvars item = readitem();
    unless item.isword then
        mishap( 'INVALID LABEL SYNTAX', [^item] )
    endunless;
    sysLABEL( item );
    pop11_need_nextreaditem( ":" ).erase;
    ";" :: proglist -> proglist;
enddefine;

endsection;
