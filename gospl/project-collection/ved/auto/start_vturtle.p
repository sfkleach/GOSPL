;;; Summary: run vturtle from outside ved

;;; A Sloman May 1983
;;; a program to enable users to run vturtle from outside ved
section;

if identprops("popturtlefile") == undef then
	popval([uses vturtle;])
endif;

endsection;

section $-vturtle => start_vturtle;

define startup(start_proc);
    vars readline, cucharout vedprintingdone;
    vedcharinsert -> cucharout;
    vedreadline -> readline;
    true -> vedprintingdone;
    vedsetonscreen(vedopen('output'),false);
	vedendfile();
	true -> vedwriteable;
	vedrefresh();
    start_proc();
enddefine;


define global start_vturtle(start_proc, _num);
    vedsetup();
	procedure;
		vars vedstartwindow;
		_num -> vedstartwindow;
    	vedobey('output', startup(%start_proc%));
	endprocedure()
enddefine;

endsection;
