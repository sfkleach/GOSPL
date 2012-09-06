compile_mode :pop11 +strict;

section;

;;; Open a hip production without complaining, blast it!

define global hip_reopen( file ); lvars file;

    define dlocal warning( arg ); lvars arg;
        lvars msg, culprits;
        if arg.islist then
            () -> msg;
            destlist( arg );
        else
            arg -> msg;
        endif;
        if msg = 'OBJECT\'S NEW NAME ALREADY IN USE' then
            erasenum()
        else
            sysprmessage( msg )
        endif;
    enddefine;

    hip_open( file ).erase
enddefine;

endsection;
