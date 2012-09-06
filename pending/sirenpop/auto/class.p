compile_mode :pop11 +strict;

section;

define macro class;
    lvars item = readitem();
    unless item.isword do
        mishap( 'UNEXPECTED CLASS NAME', [ ^item ] )
    endunless;
    item <> "_key"
enddefine;

endsection;
