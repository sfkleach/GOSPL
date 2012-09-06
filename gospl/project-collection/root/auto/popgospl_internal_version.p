;;; Summary: vectorclass object describing GOSPL version.

compile_mode :pop11 +strict;

section;

;;; Compact encoding of MAJOR, MINOR, INCREMENTAL version numbers.
constant popgospl_internal_version = consstring( ( 1, 2, 2 ), 3 );

endsection;
