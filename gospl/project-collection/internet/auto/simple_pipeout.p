compile_mode :pop11 +strict;

section;


define global simple_pipeout(src, command, args, wait);
    lvars src, command, args, wait, child;
    dlocal popexit = identfn;

    define lconstant do_pipeout(command, args, src);
        lvars command, args, child, dout, din, src, outchars;

        syspipe(true) -> din -> dout;

        if sysfork() ->> child then
            /* this is still parent */
            sysclose(din);
            /* send the data to the exec'ed process */
            ;;; cont(src) is a procedure which takes an output device
            ;;; and writes the data to it
            cont(src)(dout);
            sysclose(dout);

            /* wait for the child */
            until syswait() == child do enduntil;
        else
            /* child - the exec process */
            sysclose(dout);
            din -> popdevin;
            ;;; Should never return from this:
            sysexecute(command, args, false);
            ;;; but just in case we do ...
            fast_sysexit();
        endif;
    enddefine;

    /* is user willing to wait? */
    if wait then
        /* transfer the stuff to the exec'ed child from top level process */
        do_pipeout(command, args, src);
    else
        if sysvfork() ->> child then
            /* top level parent - a quick wait then we're off */
            until syswait() == child do enduntil;
        else
            /* vforked 1st child (to prevent zombie) */
            if sysfork() then
                /* needed a real fork because processes will be running along
                 * side one another.  This is still the 1st child.
                 */
                fast_sysexit();
            endif;
            /* we're in the fully detached process */
            do_pipeout(command, args, src);
            /* exit from the detached parent process */
            fast_sysexit();
        endif;
    endif;
enddefine;



endsection;
