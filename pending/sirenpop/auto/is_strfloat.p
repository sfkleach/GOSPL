compile_mode :pop11 +strict;

section;

define global is_strfloat =
    strnumber <> isdecimal
enddefine;

endsection
