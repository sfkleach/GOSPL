compile_mode :pop11 +strict;

section;

exload_batch;

    ;;; load X Toolkit libraries

;;;     uses xpt_xtypes;
;;;     uses xt_widget;
;;;     uses xt_callback;
;;;     uses xt_event;
;;;     uses xt_composite;
;;;     uses xt_resource;

    ;;; we will be playing with the following Xlib procedures:
    XptLoadProcedures 'cookbook'
        XFlush
    ;

endexload_batch;

define global XptFlush();
    exacc [fast] (1) raw_XFlush( XptDefaultDisplay )
enddefine;

endsection;
