;;; Summary: human readable string describing GOSPL version.

compile_mode :pop11 +strict;

section;

constant popgospl_version =
    sprintf(
        'GOSPL Version %p.%p.%p',
        [% popgospl_internal_version.explode %]
    );

endsection;
