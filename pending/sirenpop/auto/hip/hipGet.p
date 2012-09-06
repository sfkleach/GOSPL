compile_mode :pop11 +strict;

section;

define global macro hipGet();
    lvars item = readitem();
    cons_with erase { ( hip_get( " ^item ", hip_system( " currentScene " ) ) ) }
enddefine;

endsection;
