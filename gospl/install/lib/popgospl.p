compile_mode :pop11 +strict;

section;

compile(
    procedure();
        dlocal current_directory = popfilename.sys_fname_path dir_>< '../..';
        current_directory
    endprocedure() dir_><
    'init.p'
);

vars popgospl = popgospl_version;       ;;; hack for uses, yuck!

endsection;
