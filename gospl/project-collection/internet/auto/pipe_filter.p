
define pipe_filter( src, command, args ); lvars command, args, src;
    lvars ( dout, din ) = syspipe( true );
    lvars ( fout, fin ) = syspipe( true );
    lvars child = sys_fork( false );
    if child then
        ;;; This is the parent process.
        sysclose( din );
        sysclose( fout );
        ;;; send the data to the exec'ed process.
        ;;; src is a procedure which takes an output device
        ;;; and writes the data to it

        if src.isref then
            cont( src )( dout )
        else
            ;;; Note that the device is always closed explicitly.
            apprepeater( src, dout.discout );
        endif;
        sysclose( dout );

        fin;
    else
        ;;; This is the child process.
        sysclose( dout );
        din -> popdevin;
        sysclose( fin );
        fout -> popdevout;
        ;;; Should never return from this:
        sysexecute( command, args, false );
        ;;; but just in case we do ...
        fast_sysexit();
    endif;
enddefine;
