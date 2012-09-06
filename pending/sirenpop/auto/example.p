compile_mode :pop11 +strict;

section;

define macro example;
    lvars item = readitem();
    unless item.isword do
        mishap( 'UNEXPECTED CLASS NAME', [ ^item ] )
    endunless;
    [ ( oneof( recorded_instances( % item <> "_key" % ) ) ) ].dl
enddefine;

endsection;
