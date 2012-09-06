compile_mode :pop11 +strict;

section;

define global oops_beep();
    hip_beep( 100, 200, 100 );
    hip_beep( 100, 400, 100 );
    hip_beep( 100, 100, 200 );
enddefine;

endsection
