section;
compile_mode :pop11 +strict;

define global discdatafile(file); lvars file;
	lvars rep = discdatain(file);
	rep(); /* -> item */
	until rep() == termin do enduntil;
enddefine;

define updaterof discdatafile(item, file); lvars item, file;
	lvars consume = discdataout(file);
	consume(item);
	consume(termin);
enddefine;

endsection;
